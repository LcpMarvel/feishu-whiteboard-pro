#!/usr/bin/env bash
# Assemble a self-contained Coze skill package, and optionally deploy it into a project root.
#
#   bash build.sh                     # assemble into coze/dist/ (repo-local staging)
#   bash build.sh /workspace/projects # also lay the package contents AT that dir (Coze project
#                                       root), so skill files sit at the root — NOT nested.
#
# The shared design core lives once at the repo root; this copies it next to the Coze-specific
# SKILL.md / scripts so the deployed skill is self-contained. A `.coze` manifest (skill_package=skill name)
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
cp "$here/scripts/feishu_write.py" "$dist/scripts/feishu_write.py"

# License must travel with the distributed copy (MIT requirement). The store
# 详细介绍 marketing text stays clean of attribution; the credit lives here + in SKILL.md.
cp "$root/LICENSE" "$dist/LICENSE"

# Shared core — single-sourced at repo root
for f in RULES.md COMPOSITION.md CRITIQUE.md CATALOG.md; do
  cp "$root/$f" "$dist/$f"
done
cp "$root/scripts/fit-check.mjs" "$dist/scripts/fit-check.mjs"
cp -R "$root/templates" "$dist/templates"

# Examples: ship ONLY the editable .svg sources — they are the runtime starting points
# (SKILL.md step 2: "从那个 .svg 起步"). The rendered .png gallery is reference-only
# (README / store listing), is never read by the skill flow, and is ~90% of the package
# weight, so it stays OUT of the deployed package.
#
# LEAN=1 strips examples/ entirely — a maximally-lean isolation build used to test whether
# Coze's BuildGitCode timeout has anything to do with the payload at all.
if [ -n "${LEAN:-}" ]; then
  echo "   (LEAN build: skipping examples/)"
else
  mkdir -p "$dist/examples"
  cp "$root"/examples/*.svg "$dist/examples"/
fi

chmod +x "$dist/scripts/feishu_write.py" 2>/dev/null || true

# Zero-.git guarantee: the package is PURE FILES, never a git working tree. A nested .git
# (e.g. accidentally copied along with a source dir) is the prime suspect for Coze's
# BuildGitCode stall — strip any that snuck in.
find "$dist" -name .git -prune -exec rm -rf {} + 2>/dev/null || true

echo "✅ Assembled Coze package at: $dist (pure files, no .git)"

# Coze packer convention (confirmed against a Coze-generated reference skill on disk):
#   - SOURCE folder = the skill `name`, WITHOUT any suffix (e.g. `feishu-whiteboard/`),
#     containing SKILL.md + scripts/ + ...
#   - `.coze` skill_package = "<name>.skill" — the packer strips `.skill` to find the source
#     folder. Without the `.skill` suffix [build][skill] fails "skill not found in source code".
#     (`<name>.skill` itself is the BUILT package the pipeline emits — we do NOT create it.)
#   - name MUST be ASCII — a non-ASCII (Chinese) folder name gets mangled in the tar.
# So: folder = ASCII slug (no suffix); skill_package = slug + ".skill"; Chinese display name
# lives in SKILL.md frontmatter / store listing, NOT in this path.
SKILL_DIR="feishu-whiteboard-pro"

TARGET="${1:-}"
if [ -n "$TARGET" ]; then
  if [ "$(cd "$TARGET" 2>/dev/null && pwd || true)" = "$dist" ]; then
    echo "   (target is the staging dir; nothing to copy)"
  else
    pkg="$TARGET/$SKILL_DIR"
    rm -rf "$pkg"            # safe: only the skill subfolder, never the whole TARGET
    mkdir -p "$pkg"
    cp -R "$dist/." "$pkg"/
    # Pure files only — never let a .git ride into the deployed skill folder.
    find "$pkg" -name .git -prune -exec rm -rf {} + 2>/dev/null || true
    # Format mirrors the Coze-generated reference .coze exactly: 2-space indent, spaces around
    # `=`, skill_package first. skill_package = "<SKILL_DIR>.skill" (ASCII); name = SKILL_DIR.
    cat > "$TARGET/.coze" <<EOF
[skill]
  skill_package = "$SKILL_DIR.skill"
  name = "$SKILL_DIR"
  description = "一句话把内容生成为有设计感、可编辑的飞书白板：先定设计简报（构图原型+配色+字号角色），按坐标骨架施工，渲染后过五轴设计评审，最后以你本人身份写进你自己的飞书云文档，成为可编辑白板。"
  project_name = "$SKILL_DIR"
  project_description = "面向飞书 SVG 白板的设计判断技能：构图原型库 + 精选配色锚点（可现场生成换肤）+ 渲染前文字预检 + 渲染后五轴评审（层级/平衡/密度/对比/对齐），产出写进你飞书、真实可编辑的白板，而非方框网格截图。"
EOF
    # 平台授权下没有本地凭证文件：token 由扣子运行时注入（FEISHU_USER_ACCESS_TOKEN），
    # 不落盘、不进 git，所以无需任何 .gitignore 自愈逻辑。
    echo "✅ Deployed: skill files at $pkg/ ; manifest at $TARGET/.coze"
  fi
fi
