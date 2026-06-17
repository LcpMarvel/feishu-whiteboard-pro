#!/usr/bin/env bash
# feishu_auth.sh — headless Feishu auth for the Coze skill, via the official lark-cli.
#
# A-prime model (validated 2026-06-17 end-to-end in the Coze sandbox): the user authorizes
# in their browser; the board is written --as user into THE USER'S OWN tenant. No per-user
# manual app setup, no secret typed by anyone, no backend, no ISV.
#
# WHY STAGED + BACKGROUNDED:
# The Coze agent's command channel chokes on lark-cli's interactive TTY output (QR/spinner)
# with "shell.execute ... chunk exceed the limit". So the one interactive, blocking step —
# app registration (`config init --new`, which has no --no-wait) — is run in the BACKGROUND
# with output redirected to a file, and we scrape the verification URL from that file instead
# of streaming it. The scope-grant step uses lark-cli's clean non-blocking flags
# (`auth login --no-wait --json` / `--device-code`), which emit plain JSON and don't choke.
#
# NOTE: deliberately NOT `set -e` — this script branches on many commands that legitimately
# return non-zero (grep with no match, "not configured" status, a still-running bg PID). We
# keep `set -u`/`pipefail` and handle outcomes explicitly so a benign non-zero never kills it.
#
# Subcommands (SKILL.md orchestrates them across conversation turns):
#   status                  -> print auth status
#   app-begin               -> ensure an app exists; if not, background-register one and print
#                              VERIFY_URL=<url> (idempotent: never creates a second app)
#   app-finish              -> wait for the backgrounded registration to complete; APP_OK / APP_PENDING
#   login-begin             -> start scope authorization; prints {verification_url, device_code} JSON
#   login-finish <code>     -> complete scope authorization with the device_code, then print status
#
# lark-cli reads LARKSUITE_CLI_* only (NOT FEISHU_*). Point LARKSUITE_CLI_CONFIG_DIR at a
# persistent path so a user authorizes only once.
set -uo pipefail

if command -v lark-cli >/dev/null 2>&1; then
  LARK=(lark-cli)
else
  LARK=(npx -y @larksuite/cli@latest)
fi

STATE_DIR="${LARK_SKILL_STATE:-/tmp/lark-skill}"
mkdir -p "$STATE_DIR"
APPREG_LOG="$STATE_DIR/appreg.log"
APPREG_PID="$STATE_DIR/appreg.pid"

# True iff an app is already configured (so we never register a duplicate).
app_configured() {
  "${LARK[@]}" config show 2>/dev/null | grep -q '"appId"'
}

# Print the first authorization URL found in a log file (never fails the script).
scrape_url() {
  local f="$1" u
  u="$(grep -oaE 'https://[^[:space:]"]+' "$f" 2>/dev/null \
        | grep -iE 'verif|device|oauth|applink|/qr|accounts\.(feishu|larksuite)' | head -1)"
  [ -z "$u" ] && u="$(grep -oaE 'https://[^[:space:]"]+' "$f" 2>/dev/null | head -1)"
  printf '%s' "$u"
}

cmd="${1:-}"; shift || true
case "$cmd" in
  status)
    "${LARK[@]}" auth status
    ;;

  app-begin)
    # Power-user / test shortcut: bring an existing app's creds via env (non-interactive).
    if [ -n "${LARKSUITE_CLI_APP_ID:-}" ] && [ -n "${LARKSUITE_CLI_APP_SECRET:-}" ] && ! app_configured; then
      printf '%s' "$LARKSUITE_CLI_APP_SECRET" \
        | "${LARK[@]}" config init --app-id "$LARKSUITE_CLI_APP_ID" --app-secret-stdin >/dev/null 2>&1
    fi
    if app_configured; then echo "APP_OK"; exit 0; fi

    # Fresh app: register one in the user's tenant via device flow. This BLOCKS until the user
    # authorizes, so run it detached and scrape the URL from its log (never stream it).
    : > "$APPREG_LOG"
    nohup "${LARK[@]}" config init --new </dev/null >"$APPREG_LOG" 2>&1 &
    echo $! > "$APPREG_PID"
    for _ in $(seq 1 60); do
      url="$(scrape_url "$APPREG_LOG")"
      if [ -n "$url" ]; then echo "VERIFY_URL=$url"; exit 0; fi
      sleep 1
    done
    echo "NO_URL: no verification URL appeared in 60s. Log tail:" >&2
    tail -n 40 "$APPREG_LOG" >&2
    exit 1
    ;;

  app-finish)
    for _ in $(seq 1 150); do
      if app_configured; then echo "APP_OK"; exit 0; fi
      if [ -f "$APPREG_PID" ]; then
        pid="$(cat "$APPREG_PID" 2>/dev/null)"
        if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
          if app_configured; then echo "APP_OK"; exit 0; fi
          echo "APP_FAILED: registration exited without writing config. Log tail:" >&2
          tail -n 40 "$APPREG_LOG" >&2
          exit 1
        fi
      fi
      sleep 2
    done
    echo "APP_PENDING: still waiting for the user to authorize app registration" >&2
    exit 2
    ;;

  login-begin)
    # Non-blocking, clean JSON (no spinner) -> safe through the agent channel.
    "${LARK[@]}" auth login --recommend --no-wait --json
    ;;

  login-finish)
    code="${1:?usage: feishu_auth.sh login-finish <device_code>}"
    "${LARK[@]}" auth login --device-code "$code"
    "${LARK[@]}" auth status
    ;;

  *)
    echo "usage: feishu_auth.sh {status|app-begin|app-finish|login-begin|login-finish <device_code>}" >&2
    exit 2
    ;;
esac
