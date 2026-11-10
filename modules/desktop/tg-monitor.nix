#===============================================================================
# Telegram inbox monitor (desktop only)
#
# Long-polls the configured Telegram bot (same credentials/chat as the `tg`
# helper: ~/.telegram-bot-api-key) and, for every incoming message:
#   1. replies instantly with "msg received, working", and
#   2. appends it to the inbox log for the agent to pick up and act on.
#
# The monitor consumes `tg read -f -r -q` (modules/scripts/tg.sh): each
# stdout line is one Telegram getUpdates payload echoed verbatim, parsed
# with the same jq precedence the human display used (message //
# channel_post // edited_message, same chat filter, text // caption //
# media tag). Queued blocks contain the bare message text. Lines that fail
# to parse yet never could start a JSON object (banners, stray noise) are
# logged and dropped.
#
# Runs as a user service (like opencode2) so it has the user's HOME
# (credentials) and survives as long as the user session exists. Enable
# lingering (loginctl enable-linger) to keep it running without login.
# Only wired into the desktop host (see modules/desktop/default.nix).
#===============================================================================

{ pkgs, ... }:

let
  monitorScript = pkgs.writeText "tg-monitor.py" ''
    import hashlib
    import json
    import os
    import select
    import subprocess
    import sys
    import time

    HOME = os.path.expanduser("~")
    INBOX = os.environ.get("TG_INBOX", os.path.join(HOME, ".local", "share", "tg-monitor", "inbox.log"))
    SEEN = os.environ.get("TG_SEEN", os.path.join(HOME, ".local", "share", "tg-monitor", "seen.txt"))
    KEY_FILE = os.path.join(HOME, ".telegram-bot-api-key")
    ACK = "msg received, working"
    IDLE_FLUSH_S = 5.0
    MAX_BUF = 1 << 22


    def log(msg):
        print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)


    def resolve_chat_id():
        # Mirrors the credential parsing in modules/scripts/tg.sh so the monitor
        # filters updates against the same chat the `tg` helper targets.
        env = os.environ.get("TELEGRAM_CHAT_ID", "").strip()
        if env:
            return env
        try:
            with open(KEY_FILE) as f:
                lines = [l.strip() for l in f if l.strip()]
        except OSError:
            return None
        for line in lines:
            if line.startswith("CHAT_ID=") or line.startswith("TELEGRAM_CHAT_ID="):
                return line.split("=", 1)[1].strip("\"'")
        if len(lines) >= 2 and lines[1].lstrip("-").isdigit():
            return lines[1]
        return None


    CHAT_ID = resolve_chat_id()


    def load_seen():
        try:
            with open(SEEN) as f:
                return set(l.strip() for l in f if l.strip())
        except FileNotFoundError:
            return set()


    def save_seen(h):
        with open(SEEN, "a") as f:
            f.write(h + "\n")


    def send_ack():
        try:
            r = subprocess.run(["tg", ACK], capture_output=True, timeout=60, text=True)
            if r.returncode != 0:
                log("ack failed rc=%d: %s" % (r.returncode, (r.stderr or "")[-200:]))
        except Exception as e:
            log("ack exception: %s" % e)


    def handle_block(text, seen):
        text = text.strip("\n")
        if not text.strip():
            return seen
        h = hashlib.sha256(text.encode()).hexdigest()
        if h in seen:
            return seen
        seen.add(h)
        save_seen(h)
        ts = time.strftime("%Y-%m-%d %H:%M:%S")
        with open(INBOX, "a") as f:
            f.write("[%s]\n%s\n---\n" % (ts, text))
        log("new message queued (%d chars)" % len(text))
        send_ack()
        return seen


    def extract_text(msg):
        # Same precedence the `tg` display uses (jq's text // caption // media tag).
        for key in ("text", "caption"):
            if msg.get(key) is not None:
                return msg[key]
        if msg.get("photo") is not None:
            return "[Photo]"
        doc = msg.get("document")
        if doc is not None:
            return "[Document: %s]" % (doc.get("file_name") or "file")
        return "[Media]"


    def handle_update(update, seen):
        msg = None
        for key in ("message", "channel_post", "edited_message"):
            if update.get(key) is not None:
                msg = update[key]
                break
        if not isinstance(msg, dict):
            return seen  # non-message update kinds (callback_query, ...)
        if CHAT_ID is not None:
            chat = msg.get("chat") or {}
            if str(chat.get("id")) != CHAT_ID:
                return seen  # update from another chat
        return handle_block(extract_text(msg), seen)


    def handle_payload(payload, seen):
        # Each payload mirrors a Telegram getUpdates response as echoed verbatim
        # by `tg read -r` (see modules/scripts/tg.sh).
        if not isinstance(payload, dict):
            log("dropping non-object JSON payload")
            return seen
        if payload.get("ok") is not True:
            log("dropping payload without ok:true")
            return seen
        updates = payload.get("result") or []
        if not isinstance(updates, list):
            log("dropping payload with malformed result")
            return seen
        for up in updates:
            if isinstance(up, dict):
                seen = handle_update(up, seen)
        return seen


    def flush_buf(buf, seen):
        text = buf.strip()
        if not text:
            return seen
        try:
            payload = json.loads(text)
        except ValueError:
            log("dropping unparsed output (%d chars): %.100s" %
                (len(text), text.replace("\n", " ")[:100]))
            return seen
        return handle_payload(payload, seen)


    def main():
        os.makedirs(os.path.dirname(INBOX), exist_ok=True)
        seen = load_seen()
        log("tg-monitor started, parsing `tg read -f -r` JSON (chat filter: %s)" %
            (CHAT_ID or "all chats"))
        idle_cycles = 0
        while True:
            try:
                p = subprocess.Popen(["tg", "read", "-f", "-r", "-q"],
                                     stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                     text=True, bufsize=1)
            except Exception as e:
                log("failed to start tg read: %s" % e)
                time.sleep(10)
                continue
            buf = ""
            try:
                while True:
                    rlist, _, _ = select.select([p.stdout], [], [], IDLE_FLUSH_S)
                    if p.poll() is not None:
                        rest = p.stdout.read()
                        if rest:
                            buf += rest
                        if buf.strip():
                            seen = flush_buf(buf, seen)
                        break
                    if not rlist:
                        if buf:
                            seen = flush_buf(buf, seen)
                            buf = ""
                        idle_cycles += 1
                        if idle_cycles >= 12:
                            log("heartbeat: stream alive, no new messages")
                            idle_cycles = 0
                        continue
                    line = p.stdout.readline()
                    if not line:
                        if buf:
                            seen = flush_buf(buf, seen)
                        break
                    idle_cycles = 0
                    if not line.strip():
                        # Blank output line: a getUpdates payload never contains
                        # one, so whatever buffered so far ends here.
                        if buf:
                            seen = flush_buf(buf, seen)
                            buf = ""
                        continue
                    buf += line
                    try:
                        payload = json.loads(buf)
                    except ValueError:
                        if not buf.lstrip().startswith("{"):
                            log("dropping non-JSON output (%d chars): %.100s" %
                                (len(buf), buf.strip().replace("\n", " ")[:100]))
                            buf = ""
                        elif len(buf) > MAX_BUF:
                            log("dropping oversized partial JSON (%d chars)" % len(buf))
                            buf = ""
                        continue
                    buf = ""
                    seen = handle_payload(payload, seen)
            except Exception as e:
                log("stream error: %s" % e)
            try:
                p.wait(timeout=5)
            except Exception:
                try:
                    p.kill()
                except Exception:
                    pass
            log("tg read ended (rc=%s), reconnecting in 5s" % p.returncode)
            time.sleep(5)


    if __name__ == "__main__":
        main()
  '';

  runner = pkgs.writeShellScriptBin "tg-monitor-run" ''
    # `tg` is installed system-wide (see modules/common.nix); resolve it
    # via the current system profile so this unit needs no extra inputs.
    export PATH="/run/current-system/sw/bin:${pkgs.python3}/bin:$PATH"
    exec ${pkgs.python3}/bin/python3 -u ${monitorScript}
  '';
in
{
  systemd.user.services.tg-monitor = {
    description = "Telegram inbox monitor (acks + queues messages for the agent)";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${runner}/bin/tg-monitor-run";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
