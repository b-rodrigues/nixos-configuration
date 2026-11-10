#===============================================================================
# Telegram inbox monitor (desktop only)
#
# Long-polls the configured Telegram bot (same credentials/chat as the `tg`
# helper: ~/.telegram-bot-api-key) and, for every incoming message:
#   1. replies instantly with "msg received, working", and
#   2. appends it to the inbox log for the agent to pick up and act on.
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
    import os
    import select
    import subprocess
    import sys
    import time

    HOME = os.path.expanduser("~")
    INBOX = os.environ.get("TG_INBOX", os.path.join(HOME, ".local", "share", "tg-monitor", "inbox.log"))
    SEEN = os.environ.get("TG_SEEN", os.path.join(HOME, ".local", "share", "tg-monitor", "seen.txt"))
    ACK = "msg received, working"
    IDLE_FLUSH_S = 5.0
    STATUS_PATTERNS = (
        "Watching for incoming messages",
        "Press Ctrl+C to stop",
        "No recent messages",
    )


    def log(msg):
        print("[%s] %s" % (time.strftime("%H:%M:%S"), msg), flush=True)


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
        for pat in STATUS_PATTERNS:
            if pat in text and len(text) < 200:
                log("ignoring tg status line (%d chars)" % len(text))
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


    def main():
        os.makedirs(os.path.dirname(INBOX), exist_ok=True)
        seen = load_seen()
        log("tg-monitor started, watching for messages")
        idle_cycles = 0
        while True:
            try:
                p = subprocess.Popen(["tg", "read", "-f"], stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, text=True, bufsize=1)
            except Exception as e:
                log("failed to start tg read: %s" % e)
                time.sleep(10)
                continue
            block = []
            try:
                while True:
                    rlist, _, _ = select.select([p.stdout], [], [], IDLE_FLUSH_S)
                    if p.poll() is not None:
                        rest = p.stdout.read()
                        if rest:
                            block.append(rest)
                        if block:
                            seen = handle_block("\n".join(block), seen)
                        break
                    if not rlist:
                        if block:
                            seen = handle_block("\n".join(block), seen)
                            block = []
                        idle_cycles += 1
                        if idle_cycles >= 12:
                            log("heartbeat: stream alive, no new messages")
                            idle_cycles = 0
                        continue
                    line = p.stdout.readline()
                    if not line:
                        if block:
                            seen = handle_block("\n".join(block), seen)
                        break
                    idle_cycles = 0
                    if line.strip():
                        block.append(line.rstrip("\n"))
                    else:
                        if block:
                            seen = handle_block("\n".join(block), seen)
                            block = []
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
