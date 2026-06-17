#!/usr/bin/env bash
# Assemble a self-contained Coze skill package under coze/dist/.
# The shared core lives once at the repo root; this copies it next to the
# Coze-specific SKILL.md / CREDENTIALS.md / scripts so the upload is self-contained
# (the Coze sandbox loads files from inside the skill folder).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
dist="$here/dist"

rm -rf "$dist"
mkdir -p "$dist/scripts"

# Coze-specific (override the Claude Code SKILL.md with the Coze one)
cp "$here/SKILL.md" "$dist/SKILL.md"
cp "$here/CREDENTIALS.md" "$dist/CREDENTIALS.md"
cp "$here/scripts/feishu_auth.sh" "$dist/scripts/feishu_auth.sh"
cp "$here/scripts/feishu_write.sh" "$dist/scripts/feishu_write.sh"

# License must travel with the distributed copy (MIT requirement). The store
# 详细介绍 marketing text stays clean of attribution; the credit lives here + in SKILL.md.
cp "$root/LICENSE" "$dist/LICENSE"

# Shared core — single-sourced at repo root
for f in RULES.md COMPOSITION.md CRITIQUE.md CATALOG.md; do
  cp "$root/$f" "$dist/$f"
done
cp "$root/scripts/fit-check.mjs" "$dist/scripts/fit-check.mjs"
cp -R "$root/templates" "$dist/templates"
cp -R "$root/examples" "$dist/examples"

chmod +x "$dist/scripts/feishu_auth.sh" "$dist/scripts/feishu_write.sh" 2>/dev/null || true

echo "✅ Assembled Coze package at: $dist"
echo "   Upload / sync this folder into 扣子编程 (code.coze.cn) as the skill."
echo "   Note: the lark-cli device-code auth + --as user write path still needs the one-shot live test."
