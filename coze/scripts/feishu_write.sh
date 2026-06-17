#!/usr/bin/env bash
# feishu_write.sh — write an SVG into the user's Feishu as an editable whiteboard, via lark-cli
# acting AS THE USER (so the doc lands in the user's own Drive, owned by them — no permission
# grant gymnastics). Requires a completed `feishu_auth.sh` (auth login --as user) first.
#
# Flow (mirrors the local skill's RULES.md, minus the interactive login):
#   docs +create  -> new doc containing <whiteboard type="svg">…</whiteboard>  (server parses SVG
#                    into editable whiteboard nodes); returns the doc URL + whiteboard block token
#   whiteboard +query --output_as image  -> export a PNG to eyeball the live board
#
# Usage:
#   feishu_write.sh --svg <path> [--title <str>] [--image <out.png>]
set -euo pipefail

if command -v lark-cli >/dev/null 2>&1; then
  LARK=(lark-cli)
else
  LARK=(npx -y @larksuite/cli@latest)
fi

svg="" title="白板" image=""
while [ $# -gt 0 ]; do
  case "$1" in
    --svg)   svg="${2:?}";   shift 2 ;;
    --title) title="${2:?}"; shift 2 ;;
    --image) image="${2:?}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$svg" ] || { echo "--svg <path> is required" >&2; exit 2; }
[ -f "$svg" ] || { echo "svg not found: $svg" >&2; exit 1; }

svg_content="$(cat "$svg")"
content="<title>${title}</title><whiteboard type=\"svg\">${svg_content}</whiteboard>"

# Create the doc with the embedded whiteboard, as the authorized user.
created="$("${LARK[@]}" docs +create --api-version v2 --content "$content" --as user)"
echo "$created"

# Extract doc URL + whiteboard block token from the JSON (node is always present in the sandbox).
read -r doc_url wb_token < <(printf '%s' "$created" | node -e '
  let s=""; process.stdin.on("data",d=>s+=d).on("end",()=>{
    const j=JSON.parse(s); const doc=(j.data&&j.data.document)||j.document||{};
    const b=(doc.new_blocks||[]).find(x=>x.block_type==="whiteboard")||{};
    process.stdout.write((doc.url||"-")+" "+(b.block_token||"-"));
  });')

echo "DOC_URL=$doc_url"
echo "WHITEBOARD_TOKEN=$wb_token"

if [ -n "$image" ] && [ "$wb_token" != "-" ]; then
  "${LARK[@]}" whiteboard +query --whiteboard-token "$wb_token" \
    --output_as image --output "$image" --as user
  echo "IMAGE=$image"
fi
