#!/usr/bin/env bash
# Assemble a self-contained Coze skill package, and optionally deploy it into a project root.
#
#   bash build.sh                     # assemble into coze/dist/ (repo-local staging)
#   bash build.sh /workspace/projects # also lay the package contents AT that dir (Coze project
#                                       root), so skill files sit at the root — NOT nested.
#
# The shared design core lives once at the repo root; this copies it next to the Coze-specific
# SKILL.md / scripts so the deployed skill is self-contained. A `.coze` manifest (skill_package=".")
# is written into the package so the project root is a valid, self-describing Coze skill.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
dist="$here/dist"

# Staging dir is a dedicated folder — safe to wipe. (We never wipe the deploy TARGET below.)
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

# Coze packer locates a skill at <project_root>/<skill_name>/SKILL.md (skill_package="." +
# name). So on deploy we put the package INSIDE a folder named exactly after the skill, and
# write the .coze manifest at the project root.
SKILL_NAME="飞书白板大师"

TARGET="${1:-}"
if [ -n "$TARGET" ]; then
  if [ "$(cd "$TARGET" 2>/dev/null && pwd || true)" = "$dist" ]; then
    echo "   (target is the staging dir; nothing to copy)"
  else
    pkg="$TARGET/$SKILL_NAME"
    rm -rf "$pkg"            # safe: only the skill subfolder, never the whole TARGET
    mkdir -p "$pkg"
    cp -R "$dist/." "$pkg"/
    cat > "$TARGET/.coze" <<'EOF'
[skill]
name="飞书白板大师"
description="一句话把内容生成为有设计感、可编辑的飞书白板：先定设计简报（构图原型+配色+字号角色），按坐标骨架施工，渲染后过五轴设计评审，最后以你本人身份写进你自己的飞书云文档，成为可编辑白板。"
skill_package="."
project_name="飞书白板大师"
project_description="面向飞书 SVG 白板的设计判断技能：构图原型库 + 35 套配色 + 渲染前文字预检 + 渲染后五轴评审（层级/平衡/密度/对比/对齐），产出写进你飞书、真实可编辑的白板，而非方框网格截图。"
EOF
    echo "✅ Deployed: skill files at $pkg/ ; manifest at $TARGET/.coze (skill_package=\".\")"
  fi
fi
