        #!/usr/bin/env bash
        set -euo pipefail

        show_help() {
          cat <<'EOF'
NAME:
  tg - Send and read Telegram messages, photos, and files

SYNOPSIS:
  tg [OPTIONS] [MESSAGE...]
  tg read [OPTIONS]
  echo "MESSAGE" | tg [OPTIONS]
  command && tg "Success!" || tg -s "Failed!"

DESCRIPTION:
  tg is a unified CLI client for Telegram Bot API communication. It allows
  sending notifications, formatted text, photos, and files to your personal
  Telegram chat or group, as well as reading and live-streaming incoming
  messages.

  By default, all actions target the credentials and chat ID specified in
  ~/.telegram-bot-api-key (or environment variables).

COMMANDS:
  (default)             Send mode: sends text, photos, or documents to Telegram.
  read, recv            Read mode: inspects or follows incoming messages.

SEND OPTIONS:
  -f, --file PATH       Send a file/document as an attachment (e.g. PDF, log, archive).
                        Any accompanying [MESSAGE] is attached as the file's caption.
  -p, --photo PATH      Send an image with inline preview (e.g. PNG, JPG, WEBP).
                        Any accompanying [MESSAGE] is attached as the photo's caption.
  -c, --chat-id ID      Override the target Telegram Chat ID for this invocation.
  -m, --markdown        Parse text with Telegram Markdown (supports *bold*, _italic_,
                        `inline code`, ```blocks```, and [links](url)).
  --markdown-v2         Parse text with strict Telegram MarkdownV2 formatting.
  -H, --html            Parse text with HTML tags (supports <b>, <i>, <code>,
                        <pre>, and <a href="...">).
  --parse-mode MODE     Set custom parse mode explicitly ('Markdown', 'MarkdownV2', 'HTML').
  -s, --silent          Send silently (disables recipient notification chime/push sound).
  -q, --quiet           Quiet mode: suppress success confirmation messages on stdout.

READ OPTIONS (used with 'tg read'):
  -n, --limit NUM       Number of recent messages to display (default: 5).
  -f, --follow, -w      Live stream mode: continuously long-poll Telegram for new
                        incoming messages in real time (similar to tail -f).
                        Press Ctrl+C to terminate.
  -c, --chat-id ID      Override the chat ID filter (defaults to configured chat ID).
  -a, --all             Disable chat ID filter; display incoming messages from all
                        senders and chats communicating with the bot.
  -q, --quiet           Scripting mode: output raw message text only, omitting dates
                        and sender names. Ideal for shell variable capture.
  -r, --raw             Dump the unmodified JSON payload returned by Telegram getUpdates.
  --ack, --mark-read    Acknowledge and clear retrieved updates from Telegram's servers
                        so subsequent calls will only receive newer messages.
  --catch-up, --from-start
                        Follow mode only: process already-queued updates on start
                        instead of skipping to the latest (the default skips
                        history so interactive use watches only new arrivals).

GENERAL OPTIONS:
  -h, --help            Display this comprehensive manual.

PAYLOAD MANAGEMENT:
  Telegram restricts standard text messages to 4,096 UTF-8 characters. tg
  automatically manages large inputs so pipelines never fail:
    • Up to 4,096 chars:   Sent as a standard instant message.
    • 4,097 - 16,384 chars: Automatically chunked into 4,000-char parts and
                           sent sequentially with rate-limit pacing.
    • Over 16,384 chars:   Automatically written to a temporary text document and
                           uploaded as an attachment (e.g. large build/dry-run logs).

CONFIGURATION:
  Credentials are read from ~/.telegram-bot-api-key (permissions 0600) so secrets
  are never exposed or tracked in git repositories.

  Key-Value Format:
    BOT_TOKEN="123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ"
    CHAT_ID="27584996"

  Two-Line Format:
    Line 1: 123456789:ABCdefGhIJKlmNoPQRsTUVwxyZ
    Line 2: 27584996

  Environment Variables (take priority over file):
    TELEGRAM_BOT_TOKEN  Bot authentication token.
    TELEGRAM_CHAT_ID    Default recipient chat ID.

HOW TO SET UP A TELEGRAM BOT:
  1. Open Telegram and message @BotFather:
     • Send: /newbot
     • Provide a display name and username ending in 'bot' (e.g. my_notifier_bot)
     • Copy the HTTP API token provided.
  2. Start your bot:
     • Open a chat with your new bot and click "Start" (or send /start).
  3. Find your Chat ID:
     • Start a chat with @userinfobot (or forward a message to it) to view your ID.
  4. Save credentials to ~/.telegram-bot-api-key:
     echo 'BOT_TOKEN="<token>"' > ~/.telegram-bot-api-key
     echo 'CHAT_ID="<id>"' >> ~/.telegram-bot-api-key
     chmod 600 ~/.telegram-bot-api-key

EXAMPLES:
  # Basic messaging
  tg "Backup completed at $(date)"
  tg Hello from terminal                    # Multi-word unquoted string
  echo "Job finished" | tg                 # Standard input piping

  # Formatted alerts
  tg -m "*Alert*: Service \`nginx\` has restarted!"
  tg -H "<b>Deploy</b>: <code>v2.1.0</code> succeeded."

  # Silent alerts (ideal for cron or late-night jobs)
  tg -s "Nightly database snapshot created."

  # Piping large command outputs
  rebuild-dry 2>&1 | tg

  # Sending media and files
  tg -p ~/Pictures/desktop.png "Current Hyprland desktop"
  tg -f /var/log/syslog "System log excerpt"

  # Sending to a different chat or channel
  tg -c -1001234567890 "Broadcast announcement"

  # Reading incoming messages
  tg read                                   # Show last 5 messages from your chat
  tg read -n 10                             # Show last 10 messages
  tg read -n 1 -q                           # Extract single latest text message
  tg read -f                                # Live follow incoming messages
  tg read -a                                # Show messages from all chats
  tg read --ack                             # Read and mark updates as cleared

EXIT STATUS:
  0   Success (message sent, file delivered, or updates retrieved).
  1   Error (missing credentials, network failure, or API rejection).
EOF
          exit 0
        }

        # Check for help flag
        for arg in "$@"; do
          case "$arg" in
            -h|--help)
              show_help
              ;;
          esac
        done

        KEY_FILE="$HOME/.telegram-bot-api-key"

        TOKEN=""
        CHAT_ID=""

        if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
          TOKEN="$TELEGRAM_BOT_TOKEN"
        elif [ -f "$KEY_FILE" ]; then
          if grep -q "BOT_TOKEN=" "$KEY_FILE" 2>/dev/null; then
            TOKEN=$(grep -E "^(TELEGRAM_)?BOT_TOKEN=" "$KEY_FILE" | head -n1 | cut -d= -f2- | tr -d "[:space:]\"\047")
          fi
          if [ -z "$TOKEN" ]; then
            TOKEN=$(head -n1 "$KEY_FILE" | tr -d "[:space:]\"\047")
          fi
        fi

        if [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
          CHAT_ID="$TELEGRAM_CHAT_ID"
        elif [ -f "$KEY_FILE" ]; then
          if grep -q "CHAT_ID=" "$KEY_FILE" 2>/dev/null; then
            CHAT_ID=$(grep -E "^(TELEGRAM_)?CHAT_ID=" "$KEY_FILE" | head -n1 | cut -d= -f2- | tr -d "[:space:]\"\047")
          fi
          if [ -z "$CHAT_ID" ]; then
            LINE2=$(sed -n "2p" "$KEY_FILE" | tr -d "[:space:]\"\047")
            if [[ "$LINE2" =~ ^-?[0-9]+$ ]]; then
              CHAT_ID="$LINE2"
            fi
          fi
        fi

        if [ -z "$CHAT_ID" ]; then
          CHAT_ID="27584996"
        fi

        if [ -z "$TOKEN" ]; then
          echo "Error: Telegram Bot Token not found." >&2
          echo "Please create $KEY_FILE or export TELEGRAM_BOT_TOKEN." >&2
          echo "Run 'tg --help' for setup instructions." >&2
          exit 1
        fi

        # Env-sourced values may carry stray whitespace (editors, exports);
        # file-parsed values are already stripped via tr -d above.
        TOKEN=$(printf '%s' "$TOKEN" | tr -d '[:space:]')
        CHAT_ID=$(printf '%s' "$CHAT_ID" | tr -d '[:space:]')

        api_call() {
          local endpoint="$1"
          shift
          local resp
          resp=$(curl -s -w "\n%{http_code}" "$@" "https://api.telegram.org/bot${TOKEN}/${endpoint}")
          local status
          status=$(echo "$resp" | tail -n1)
          local body
          body=$(echo "$resp" | sed '$d')
          if [ "$status" != "200" ]; then
            echo "Error: Telegram API request failed (HTTP $status):" >&2
            echo "$body" | jq -r '.description // .' >&2 2>/dev/null || echo "$body" >&2
            return 1
          fi
          return 0
        }

        #===========================================================================
        # READ SUBCOMMAND
        #===========================================================================
        if [ "${1:-}" = "read" ] || [ "${1:-}" = "recv" ]; then
          shift
          LIMIT=5
          FOLLOW=false
          FILTER_CHAT=true
          QUIET=false
          RAW=false
          ACK=false
          CATCH_UP=false

          while [ $# -gt 0 ]; do
            case "$1" in
              -n|--limit)
                LIMIT="$2"
                shift 2
                ;;
              -f|--follow|-w|--watch)
                FOLLOW=true
                shift
                ;;
              -c|--chat-id)
                CHAT_ID="$2"
                FILTER_CHAT=true
                shift 2
                ;;
              -a|--all)
                FILTER_CHAT=false
                shift
                ;;
              -q|--quiet)
                QUIET=true
                shift
                ;;
              -r|--raw)
                RAW=true
                shift
                ;;
              --ack|--mark-read)
                ACK=true
                shift
                ;;
              --catch-up|--from-start)
                CATCH_UP=true
                shift
                ;;
              *)
                echo "Unknown option: $1" >&2
                echo "Run 'tg --help' for usage." >&2
                exit 1
                ;;
            esac
          done

          format_updates() {
            local json="$1"
            local limit="$2"
            local filter="$3"
            local target_chat="$4"
            local quiet="$5"

            if [ "$RAW" = "true" ]; then
              echo "$json"
              return
            fi

            if [ "$quiet" = "true" ]; then
              echo "$json" | jq -r \
                --arg filter "$filter" \
                --arg chat_id "$target_chat" \
                --argjson limit "$limit" '
                  [
                    .result[]? |
                    (.message // .channel_post // .edited_message // .edited_channel_post) as $msg |
                    select($msg != null) |
                    select($filter != "true" or ($msg.chat.id | tostring) == $chat_id) |
                    ($msg.text // $msg.caption // (if $msg.photo then "[Photo]" elif $msg.document then "[Document: " + ($msg.document.file_name // "file") + "]" else "[Media]" end))
                  ] | (if length > $limit then .[-$limit:] else . end) | .[]
                '
            else
              echo "$json" | jq -r \
                --arg filter "$filter" \
                --arg chat_id "$target_chat" \
                --argjson limit "$limit" '
                  [
                    .result[]? |
                    (.message // .channel_post // .edited_message // .edited_channel_post) as $msg |
                    select($msg != null) |
                    select($filter != "true" or ($msg.chat.id | tostring) == $chat_id) |
                    "[\($msg.date | strftime("%Y-%m-%d %H:%M:%S"))] \($msg.from.first_name // $msg.from.username // $msg.chat.title // "User"): \($msg.text // $msg.caption // (if $msg.photo then "[Photo]" elif $msg.document then "[Document: " + ($msg.document.file_name // "file") + "]" else "[Media]" end))"
                  ] | (if length > $limit then .[-$limit:] else . end) | .[]
                '
            fi
          }

          if [ "$FOLLOW" = "true" ]; then
            if [ "$QUIET" != "true" ]; then
              if [ "$FILTER_CHAT" = "true" ]; then
                echo "Watching for incoming messages from chat $CHAT_ID... (Press Ctrl+C to stop)"
              else
                echo "Watching for incoming messages from all chats... (Press Ctrl+C to stop)"
              fi
            fi

            # By default follow mode skips already-queued history so interactive
            # use watches only new arrivals. --catch-up disables that skip so a
            # consumer (e.g. tg-monitor) drains the backlog instead of losing
            # all but the latest update on every (re)start.
            OFFSET=""
            if [ "$CATCH_UP" != "true" ]; then
              RESP=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=-1")
              LAST_ID=$(echo "$RESP" | jq -r '.result[-1].update_id // empty' 2>/dev/null || true)
              if [ -n "$LAST_ID" ]; then
                OFFSET=$((LAST_ID + 1))
              fi
            fi

            while true; do
              URL="https://api.telegram.org/bot${TOKEN}/getUpdates?timeout=30"
              if [ -n "$OFFSET" ]; then
                URL="${URL}&offset=${OFFSET}"
              fi
              if ! UPDATES=$(curl -s "$URL"); then
                echo "tg: getUpdates request failed, retrying in 5s" >&2
                sleep 5
                continue
              fi
              # Empty curl output (network cut mid-read): back off, don't spin.
              if [ -z "$UPDATES" ]; then
                echo "tg: empty getUpdates response, retrying in 5s" >&2
                sleep 5
                continue
              fi
              OK=$(echo "$UPDATES" | jq -r '.ok // false' 2>/dev/null || echo "false")
              if [ "$OK" != "true" ]; then
                # Covers 409 conflicts (another getUpdates consumer) and API
                # errors. Log to stderr (the monitor relays this) and back off
                # instead of hot-looping.
                echo "tg: getUpdates returned ok != true, retrying in 5s" >&2
                sleep 5
                continue
              fi
              COUNT=$(echo "$UPDATES" | jq -r '.result | length // 0' 2>/dev/null || echo "0")
              if [ "${COUNT:-0}" -gt 0 ] 2>/dev/null; then
                format_updates "$UPDATES" "$COUNT" "$FILTER_CHAT" "$CHAT_ID" "$QUIET"
                NEW_LAST_ID=$(echo "$UPDATES" | jq -r '.result[-1].update_id // empty' 2>/dev/null || true)
                if [ -n "$NEW_LAST_ID" ]; then
                  OFFSET=$((NEW_LAST_ID + 1))
                fi
              fi
            done
          else
            RESP=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates")
            OK=$(echo "$RESP" | jq -r '.ok // false' 2>/dev/null || echo "false")
            if [ "$OK" != "true" ]; then
              echo "Error: Telegram API error:" >&2
              echo "$RESP" | jq -r '.description // .' >&2 2>/dev/null || echo "$RESP" >&2
              exit 1
            fi

            OUTPUT=$(format_updates "$RESP" "$LIMIT" "$FILTER_CHAT" "$CHAT_ID" "$QUIET")
            if [ -n "$OUTPUT" ]; then
              echo "$OUTPUT"
            elif [ "$QUIET" != "true" ]; then
              if [ "$FILTER_CHAT" = "true" ]; then
                echo "No recent messages found from chat ID $CHAT_ID."
              else
                echo "No recent messages found."
              fi
            fi

            if [ "$ACK" = "true" ]; then
              LAST_ID=$(echo "$RESP" | jq -r '.result[-1].update_id // empty')
              if [ -n "$LAST_ID" ]; then
                NEW_OFFSET=$((LAST_ID + 1))
                curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=${NEW_OFFSET}" > /dev/null
                if [ "$QUIET" != "true" ]; then
                  echo "Messages acknowledged up to update_id $LAST_ID."
                fi
              fi
            fi
          fi
          exit 0
        fi

        #===========================================================================
        # SEND MODE (Default)
        #===========================================================================
        FILE=""
        PHOTO=""
        MESSAGE=""
        PARSE_MODE=""
        SILENT="false"
        QUIET="false"

        while [ $# -gt 0 ]; do
          case "$1" in
            -f|--file)
              FILE="$2"
              shift 2
              ;;
            -p|--photo)
              PHOTO="$2"
              shift 2
              ;;
            -c|--chat-id)
              CHAT_ID="$2"
              shift 2
              ;;
            -m|--markdown)
              PARSE_MODE="Markdown"
              shift
              ;;
            --markdown-v2)
              PARSE_MODE="MarkdownV2"
              shift
              ;;
            -H|--html)
              PARSE_MODE="HTML"
              shift
              ;;
            --parse-mode)
              PARSE_MODE="$2"
              shift 2
              ;;
            -s|--silent)
              SILENT="true"
              shift
              ;;
            -q|--quiet)
              QUIET="true"
              shift
              ;;
            *)
              if [ -z "$MESSAGE" ]; then
                MESSAGE="$1"
              else
                MESSAGE="$MESSAGE $1"
              fi
              shift
              ;;
          esac
        done

        # Read piped standard input if message was not supplied or if stdin is piped
        if [ -z "$FILE" ] && [ -z "$PHOTO" ] && [ -z "$MESSAGE" ]; then
          if [ ! -t 0 ]; then
            MESSAGE=$(cat)
          else
            echo "Usage: tg [OPTIONS] [MESSAGE]" >&2
            echo "       tg read [OPTIONS]" >&2
            echo "       echo \"MESSAGE\" | tg" >&2
            echo "Run 'tg --help' for detailed manual." >&2
            exit 1
          fi
        elif [ -z "$MESSAGE" ] && [ ! -t 0 ]; then
          MESSAGE=$(cat)
        fi

        send_text_message() {
          local text="$1"
          local len="${#text}"
          if [ "$len" -le 4096 ]; then
            local args=(-F "chat_id=$CHAT_ID" -F "text=$text")
            if [ -n "$PARSE_MODE" ]; then args+=(-F "parse_mode=$PARSE_MODE"); fi
            if [ "$SILENT" = "true" ]; then args+=(-F "disable_notification=true"); fi
            api_call "sendMessage" "${args[@]}"
          elif [ "$len" -le 16384 ]; then
            local offset=0
            local chunk_size=4000
            while [ "$offset" -lt "$len" ]; do
              local chunk="${text:$offset:$chunk_size}"
              local args=(-F "chat_id=$CHAT_ID" -F "text=$chunk")
              if [ -n "$PARSE_MODE" ]; then args+=(-F "parse_mode=$PARSE_MODE"); fi
              if [ "$SILENT" = "true" ]; then args+=(-F "disable_notification=true"); fi
              api_call "sendMessage" "${args[@]}"
              offset=$((offset + chunk_size))
              if [ "$offset" -lt "$len" ]; then
                sleep 0.2
              fi
            done
          else
            local tmp_file
            tmp_file=$(mktemp /tmp/tg-output-XXXXXX.txt)
            printf "%s\n" "$text" > "$tmp_file"
            local caption="Piped output ($len characters)"
            local args=(-F "chat_id=$CHAT_ID" -F "document=@$tmp_file" -F "caption=$caption")
            if [ "$SILENT" = "true" ]; then args+=(-F "disable_notification=true"); fi
            api_call "sendDocument" "${args[@]}"
            rm -f "$tmp_file"
          fi
        }

        if [ -n "$PHOTO" ]; then
          if [ ! -f "$PHOTO" ]; then
            echo "Error: Photo file not found: $PHOTO" >&2
            exit 1
          fi
          args=(-F "chat_id=$CHAT_ID" -F "photo=@$PHOTO")
          if [ -n "$MESSAGE" ]; then args+=(-F "caption=$MESSAGE"); fi
          if [ -n "$PARSE_MODE" ]; then args+=(-F "parse_mode=$PARSE_MODE"); fi
          if [ "$SILENT" = "true" ]; then args+=(-F "disable_notification=true"); fi
          api_call "sendPhoto" "${args[@]}"
          if [ "$QUIET" != "true" ]; then
            echo "Photo sent to Telegram: $PHOTO"
          fi
        elif [ -n "$FILE" ]; then
          if [ ! -f "$FILE" ]; then
            echo "Error: Document file not found: $FILE" >&2
            exit 1
          fi
          args=(-F "chat_id=$CHAT_ID" -F "document=@$FILE")
          if [ -n "$MESSAGE" ]; then args+=(-F "caption=$MESSAGE"); fi
          if [ -n "$PARSE_MODE" ]; then args+=(-F "parse_mode=$PARSE_MODE"); fi
          if [ "$SILENT" = "true" ]; then args+=(-F "disable_notification=true"); fi
          api_call "sendDocument" "${args[@]}"
          if [ "$QUIET" != "true" ]; then
            echo "File sent to Telegram: $FILE"
          fi
        else
          send_text_message "$MESSAGE"
          if [ "$QUIET" != "true" ]; then
            echo "Message sent to Telegram."
          fi
        fi
