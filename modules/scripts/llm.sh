        #!/usr/bin/env bash
        set -euo pipefail

        MODEL_DEFAULT="opencode/deepseek-v4.1-flash-free"
        MINIMAL_INSTRUCTION="Answer with the absolute minimum number of tokens: give only the essential result. No explanation, no preamble, no markdown formatting, no code fences, no backticks. If a command is requested, output only the command itself."
        VERBOSE_INSTRUCTION="Answer in a complete and helpful way, like a chat assistant: explain the details that matter and include useful context. Normal formatting is welcome. Do not restrict yourself to a bare minimum."
        JQ=jq
        STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/opencode-llm"
        SESSION_FILE="$STATE_DIR/session.json"

        show_help() {
          cat <<'EOF'
NAME:
  llm - Ask a question through the OpenCode v2 background server

SYNOPSIS:
  llm [OPTIONS] [QUESTION...]
  echo "QUESTION" | llm [OPTIONS]

DESCRIPTION:
  llm sends your question to the OpenCode v2 background service running on
  this machine and prints the assistant answer to stdout. By default it uses
  the free model opencode/deepseek-v4.1-flash-free, which is served through
  your signed-in OpenCode account.

  Answers are minimal by default (only the essential result, no explanations).
  Use --verbose for a full conversational answer.

  When the answer is a single executable command and llm runs in a terminal,
  it asks whether to run it: type y or yes to execute it, anything else to
  skip. The offer is disabled automatically when the output is piped or
  redirected, so llm stays safe to use in scripts.

  A single session is kept between invocations, so follow-up questions have
  context. Use -n/--new to start a fresh conversation.

OPTIONS:
  -v, --verbose       Full answer instead of the minimal default
  -m, --model MODEL   Model as provider/model
                      (default: opencode/deepseek-v4.1-flash-free)
  -n, --new           Discard the current session and start a fresh one
  -h, --help          Show this help

EXAMPLES:
  llm "show me the command to untar a file"
  llm "same thing but for zip files"
  llm --verbose "explain what tar -xzf does"
  echo "capital of France?" | llm
  llm -m opencode-go/deepseek-v4.1-flash "write a bash loop over files"
EOF
        }

        read_session_field() {
          if [ -f "$SESSION_FILE" ]; then
            "$JQ" -r --arg f "$1" '.[$f] // empty' "$SESSION_FILE" 2>/dev/null || true
          fi
        }

        write_session() {
          mkdir -p "$STATE_DIR"
          "$JQ" -nc --arg id "$1" --arg model "$2" '{id: $id, model: $model}' > "$SESSION_FILE"
        }

        ensure_service() {
          if ! opencode2 service status >/dev/null 2>&1; then
            echo "llm: starting opencode2 background service..." >&2
            opencode2 service start >/dev/null 2>&1 || true
            for _ in $(seq 1 40); do
              opencode2 service status >/dev/null 2>&1 && return 0
              sleep 0.25
            done
            echo "llm: error: opencode2 service did not start" >&2
            exit 1
          fi
        }

        create_session() {
          local payload response id
          payload=$("$JQ" -nc --argjson m "$MODEL_REF" '{title: "llm", model: $m}')
          response=$(opencode2 api post /api/session --data "$payload") || {
            echo "llm: error: could not create a session on the OpenCode server" >&2
            exit 1
          }
          id=$(printf '%s' "$response" | "$JQ" -r '.data.id // empty')
          if [ -z "$id" ]; then
            echo "llm: error: unexpected response while creating a session" >&2
            exit 1
          fi
          write_session "$id" "$MODEL"
          printf '%s' "$id"
        }

        ask() {
          local payload admitted t0 out
          payload=$("$JQ" -nc --arg t "$PROMPT" '{text: $t}')
          admitted=$(opencode2 api post "/api/session/$SESS/prompt" --data "$payload" 2>/dev/null) || return 1
          t0=$(printf '%s' "$admitted" | "$JQ" -r '.data.time.created // 0' 2>/dev/null) || t0=0
          opencode2 api post "/api/experimental/session/$SESS/wait" >/dev/null 2>&1 || return 1
          out=$(opencode2 api get "/api/session/$SESS/message" 2>/dev/null) || return 1
          printf '%s' "$out" | "$JQ" -r --argjson t0 "$t0" \
            '[.data[] | select(.type == "assistant" and .time.created >= $t0)][0].content // [] | map(select(.type == "text") | .text) | join("")' \
            || return 1
        }

        # --- argument parsing -------------------------------------------------
        MODEL="$MODEL_DEFAULT"
        NEW_SESSION=false
        VERBOSE=false
        PROMPT_ARGS=()

        while [ $# -gt 0 ]; do
          case "$1" in
            -h|--help) show_help; exit 0 ;;
            -m|--model)
              if [ $# -lt 2 ]; then
                echo "llm: --model requires a value" >&2
                exit 1
              fi
              MODEL="$2"; shift 2 ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -n|--new) NEW_SESSION=true; shift ;;
            --) shift; PROMPT_ARGS+=("$@"); break ;;
            -*) echo "llm: unknown option: $1" >&2; exit 1 ;;
            *) PROMPT_ARGS+=("$1"); shift ;;
          esac
        done

        if [ ${#PROMPT_ARGS[@]} -gt 0 ]; then
          PROMPT="${PROMPT_ARGS[*]}"
        elif [ ! -t 0 ]; then
          PROMPT=$(cat)
        else
          echo 'llm: no question given; try: llm "how do I untar a file?"' >&2
          exit 1
        fi

        if [ "$VERBOSE" = true ]; then
          PROMPT=$(printf '%s\n\n%s' "$VERBOSE_INSTRUCTION" "$PROMPT")
        else
          PROMPT=$(printf '%s\n\n%s' "$MINIMAL_INSTRUCTION" "$PROMPT")
        fi

        # --- model reference (provider/id#variant) ----------------------------
        if [ "$MODEL" = "${MODEL#*/}" ]; then
          echo "llm: model must look like provider/model (got: $MODEL)" >&2
          exit 1
        fi
        PROVIDER="${MODEL%%/*}"
        REST="${MODEL#*/}"
        MODEL_ID="${REST%%#*}"
        VARIANT=""
        if [ "$REST" != "$MODEL_ID" ]; then VARIANT="${REST#*#}"; fi
        MODEL_REF=$("$JQ" -nc --arg p "$PROVIDER" --arg i "$MODEL_ID" --arg v "$VARIANT" \
          '{providerID: $p, id: $i} + (if $v == "" then {} else {variant: $v} end)')

        # --- session handling -------------------------------------------------
        ensure_service

        SESS=$(read_session_field id)
        STORED_MODEL=$(read_session_field model)

        if [ "$NEW_SESSION" = true ]; then
          if [ -n "$SESS" ]; then
            opencode2 api delete "/api/session/$SESS" >/dev/null 2>&1 || true
          fi
          SESS=""
        fi

        if [ -z "$SESS" ]; then
          SESS=$(create_session)
        elif [ "$STORED_MODEL" != "$MODEL" ]; then
          if opencode2 api post "/api/session/$SESS/model" \
            --data "$("$JQ" -nc --argjson m "$MODEL_REF" '{model: $m}')" >/dev/null 2>&1; then
            write_session "$SESS" "$MODEL"
          else
            opencode2 api delete "/api/session/$SESS" >/dev/null 2>&1 || true
            SESS=$(create_session)
          fi
        fi

        # --- ask and print ----------------------------------------------------
        ANSWER=""
        if ! ANSWER=$(ask); then
          # The session may be stale (service restarted, deleted in the TUI, ...)
          opencode2 api delete "/api/session/$SESS" >/dev/null 2>&1 || true
          SESS=$(create_session)
          if ! ANSWER=$(ask); then
            echo "llm: error: request to the OpenCode server failed" >&2
            exit 1
          fi
        fi

        if [ -n "$ANSWER" ]; then
          printf '%s\n' "$ANSWER"
        else
          echo "llm: warning: the model returned no text" >&2
        fi

        # --- offer to run the answer if it looks like a single command --------
        if [ -n "$ANSWER" ] && [ -t 1 ] && [ -r /dev/tty ] && [[ "$ANSWER" != *$'\n'* ]]; then
          read -r FIRST_WORD _ <<< "$ANSWER"
          if [ -n "$FIRST_WORD" ] && command -v "$FIRST_WORD" >/dev/null 2>&1; then
            printf 'Run the command above? [y/N] ' >&2
            REPLY=""
            read -r REPLY < /dev/tty || REPLY=""
            case "$REPLY" in
              [yY]|[yY][eE][sS])
                exec bash -c "$ANSWER"
                ;;
            esac
          fi
        fi
