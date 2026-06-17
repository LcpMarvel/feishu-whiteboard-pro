#!/usr/bin/env bash
# feishu_auth.sh — headless Feishu auth for the Coze skill, via the official lark-cli.
#
# A-prime model (validated 2026-06-17 end-to-end in the Coze sandbox): the user authorizes
# in their browser; the board is written --as user into THE USER'S OWN tenant. No per-user
# manual app setup, no secret typed by anyone, no backend, no ISV.
#
# WHY THIS IS STRUCTURED IN STAGES:
# The Coze agent's command channel chokes on lark-cli's interactive TTY output (QR/spinner)
# with "shell.execute ... chunk exceed the limit". So the one interactive, blocking step —
# app registration (`config init --new`, which has no --no-wait) — is run in the BACKGROUND
# with output redirected to a file, and we scrape the verification URL from that file instead
# of streaming it. The scope-grant step uses lark-cli's clean non-blocking flags
# (`auth login --no-wait --json` / `--device-code`), which emit plain JSON and don't choke.
#
# Subcommands (SKILL.md orchestrates them across conversation turns):
#   status                  -> print auth status (is the user logged in?)
#   app-begin               -> ensure an app exists; if not, background-register one and print
#                              VERIFY_URL=<url> for the user to authorize (idempotent: never
#                              creates a second app)
#   app-finish              -> wait for the backgrounded registration to complete; APP_OK / APP_PENDING
#   login-begin             -> start scope authorization; prints {verification_url, device_code} JSON
#   login-finish <code>     -> complete scope authorization with the device_code, then print status
#
# State/persistence: lark-cli stores app config + tokens under LARKSUITE_CLI_CONFIG_DIR.
# Point it at a persistent path (e.g. the project mount) so a user authorizes only once.
# lark-cli reads LARKSUITE_CLI_* only — NOT FEISHU_*.
set -euo pipefail

if command -v lark-cli >/dev/null 2>&1; then
  LARK=(lark-cli)
else
  LARK=(npx -y @larksuite/cli@latest)
fi

STATE_DIR="${LARK_SKILL_STATE:-/tmp/lark-skill}"
mkdir -p "$STATE_DIR"
APPREG_LOG="$STATE_DIR/appreg.log"
APPREG_PID="$STATE_DIR/appreg.pid"

# True if an app is already configured (so we never register a duplicate).
app_configured() {
  "${LARK[@]}" config show 2>/dev/null | grep -q '"appId"'
}

# Extract the first authorization URL from a log file (URL is non-secret).
scrape_url() {
  grep -oaE 'https://[^[:space:]"]+' "$1" 2>/dev/null \
    | grep -iE 'verif|device|oauth|applink|/qr|accounts\.(feishu|larksuite)' | head -1 \
    || grep -oaE 'https://[^[:space:]"]+' "$1" 2>/dev/null | head -1
}

cmd="${1:-}"; shift || true
case "$cmd" in
  status)
    "${LARK[@]}" auth status
    ;;

  app-begin)
    # Power-user / test shortcut: bring an existing app's creds via env (non-interactive,
    # no browser registration). Keeps the secret out of the agent — it comes from env only.
    if [ -n "${LARKSUITE_CLI_APP_ID:-}" ] && [ -n "${LARKSUITE_CLI_APP_SECRET:-}" ] && ! app_configured; then
      printf '%s' "$LARKSUITE_CLI_APP_SECRET" | "${LARK[@]}" config init \
        --app-id "$LARKSUITE_CLI_APP_ID" --app-secret-stdin >/dev/null
    fi
    if app_configured; then echo "APP_OK"; exit 0; fi

    # Fresh app: register one in the user's tenant via device flow. This call BLOCKS until the
    # user authorizes, so run it detached and scrape the URL from its log (never stream it).
    : > "$APPREG_LOG"
    nohup "${LARK[@]}" config init --new </dev/null >"$APPREG_LOG" 2>&1 &
    echo $! >"$APPREG_PID"
    for _ in $(seq 1 45); do
      url="$(scrape_url "$APPREG_LOG")"
      if [ -n "$url" ]; then echo "VERIFY_URL=$url"; exit 0; fi
      sleep 1
    done
    echo "NO_URL: registration emitted no URL in 45s; log tail:" >&2
    tail -n 40 "$APPREG_LOG" >&2
    exit 1
    ;;

  app-finish)
    # Poll until the backgrounded registration writes the app config (user authorized).
    for _ in $(seq 1 150); do
      if app_configured; then echo "APP_OK"; exit 0; fi
      if [ -f "$APPREG_PID" ] && ! kill -0 "$(cat "$APPREG_PID" 2>/dev/null)" 2>/dev/null; then
        app_configured && { echo "APP_OK"; exit 0; }
        echo "APP_FAILED: registration exited without config; log tail:" >&2
        tail -n 40 "$APPREG_LOG" >&2
        exit 1
      fi
      sleep 2
    done
    echo "APP_PENDING: still waiting for the user to authorize app registration" >&2
    exit 2
    ;;

  login-begin)
    # Non-blocking, clean JSON output (no spinner) -> safe through the agent channel.
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
