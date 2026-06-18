---
name: feishu-whiteboard-pro
description: >
  把内容生成为「真正设计过」的可编辑飞书白板——强视觉层级、有意图的构图、留白，而不是
  一堆等大方块。先定设计简报（构图原型 + 配色策略 + 字号角色 + 反套路检查）再画，按坐标
  骨架施工，渲染后跑设计评审（层级/平衡/密度/对比/对齐）补到最弱项达标，最后写进你自己的
  飞书文档成为可编辑白板。飞书走扣子「平台授权」，一键授权即用（见 CREDENTIALS.md）。
---

# 飞书白板大师

一个面向飞书 SVG 白板的**设计判断**技能。它不是给你一套配色就让你随手摆——它强制
**画之前先写设计简报**、**渲染后做设计评审**。产出是写进你飞书文档里的、真实可编辑的白板。

白板媒介是刻意受限的：单一字体、只有原生矩形/圆/连接线、无渐变、无滤镜、无透明度、无动效。
所以这里的「好看」= **构图、层级、节奏、配色克制、留白**，绝不靠特效。功力花在这些上。

三件事决定成败，各有归属：
- **媒介允许什么** → `RULES.md`。硬限制，真机验证过。必读。
- **怎么构图** → `COMPOSITION.md`。带坐标骨架的原型、字号体系、间距栅格。技能核心。
- **到底好不好** → `CRITIQUE.md`。渲染后的设计评分表与逐项修法。

## 何时使用

- 用户想要一张飞书 / Lark 白板、信息图、流程图、海报、系统图或可视化讲解，且要它**看起来
  真的被设计过**——清晰焦点、真实层级，不是一墙等大方块。
- 用户给了内容（"把 X 讲成白板""把这段变成图"），想要它可视化、可编辑、在飞书画布上。

## 第 0 步：前置条件（动手前先查）

- **飞书授权**：技能以**用户本人身份**写入其飞书租户，走扣子**平台授权**——用户在扣子里一键授权飞书，
  运行时扣子把用户的 `user_access_token` 注入环境变量 `COZE_FEISHU_BOARD_$COZE_PROJECT_ID`，**无需用户建应用、
  填密钥或跑设备码**（详见 [`CREDENTIALS.md`](CREDENTIALS.md)）。技能代码不碰 OAuth。
- 沙箱已具备 Python（写入层，标准库即可）、Node（本地渲染）、`npx @larksuite/whiteboard-cli`（npx 自动下载）。

## 管线（两道闸门，都不能跳）

```
理解内容
   │
   ├─▶  闸门 1 · 设计简报      （写任何 SVG 之前 —— 见下）
   ▼
按骨架构图                     （COMPOSITION.md：原型坐标 + 字号体系 + 间距栅格）
   │
   ▼
渲染 → 修正确性                （RULES.md：溢出 / 重叠 / 裁切 / 箭头）
   │
   ▼
闸门 2 · 设计评审              （CRITIQUE.md：评分、补最弱项、重渲、循环）
   │
   ▼
写进飞书 → 看实时白板 → 交付
```

### 1. 理解内容
弄清白板要承载什么：内容、目的、受众。内容不清就问一个短问题。**不要**问用户视觉风格——
那是你在简报里自己定，最后再提供换色。

### 闸门 1 · 设计简报（强制，写 SVG 之前）
先读 [`COMPOSITION.md`](COMPOSITION.md) 和 [`CATALOG.md`](CATALOG.md)，再**写下**这五条承诺
（叙事形状→原型、焦点、配色策略+palette、字号角色、反套路检查）。详见 COMPOSITION.md。
配色优先选 CATALOG.md 里的锚点 palette（可靠、可换肤）；若没有合适的，按
[`templates/GENERATE.md`](templates/GENERATE.md) **现场生成**一套——它产出同样的 frontmatter 形态，
照样可换肤，本轮内联使用即可（不必写进技能目录）。
用一句话告诉用户你选了哪个原型和 palette、为什么，然后开画。

### 2. 按骨架构图
匹配的原型若在 [`examples/`](examples/) 里有，就从那个 `.svg` 起步、替换内容。在逻辑坐标
空间（≈1600–1700 宽）写 SVG，遵循 COMPOSITION.md 的骨架/字号/栅格，以及 RULES.md 全部硬规则。
只把**内容**放上画布——绝不放提示词、来源、风格名或任何 meta 行。

### 3. 渲染 → 修正确性
先不渲染预测缺陷：`node scripts/fit-check.mjs <dir>/diagram.svg`（标签过宽/挤占/出血）。
然后按 RULES.md 渲染并**真的打开 PNG 看**：
`npx -y @larksuite/whiteboard-cli@^0.2.11 -i <dir>/diagram.svg -o <dir>/diagram.png -f svg`
就地小步改 SVG，一次看到的问题合并一轮改完再重渲。这步只管**正确**，不管品味。

### 闸门 2 · 设计评审（强制，正确性干净后）
按 [`CRITIQUE.md`](CRITIQUE.md) 五轴（层级/平衡/密度/对比/对齐）打分，点名**最弱**一项，套用
其修法重渲，循环到没有不及格轴。要真正交付的白板，最好让一个独立评审子 agent 只拿渲染图
和评分表、以对抗姿态评。

### 4. 写进飞书 → 看实时白板 → 交付

授权由扣子**平台授权**托管：用户在扣子里授权过飞书后，token 在运行时自动注入
（环境变量 `COZE_FEISHU_BOARD_$COZE_PROJECT_ID`），**技能这步不做任何 OAuth**。若该变量缺失，写入脚本会直接
报错提示去扣子完成授权——把这句提示作为本轮消息转达用户即可，不要自己尝试任何授权流程。

直接写入并导出：

```bash
python3 scripts/feishu_write.py --svg <dir>/diagram.svg --title "标题" --image <dir>/board.png
```

它以**用户本人身份**建文档（内嵌 `<whiteboard type="svg">`，服务端解析成可编辑节点）→ 返回**文档链接 +
白板 token** → 导出白板图 `board.png`。`board.png` 对版面/填充忠实、但文字颜色不可靠（颜色以实时文档为准），
而且是飞书把任意画板补白成 ~2560×2560 的**固定方图预览**——**仅用于核对实时白板**，不作交付图。

交付**两样**：飞书**文档链接** + 第 3 步本地渲染的 `diagram.png`（贴合构图、无补白），**不要**交付方图 `board.png`。
然后告诉用户可随时**换 palette**，同构图重渲，只改颜色。

## 文件
- **[`RULES.md`](RULES.md)** — 媒介硬规则。必读。
- **[`COMPOSITION.md`](COMPOSITION.md)** — 原型库、字号体系、间距栅格、反套路。核心。
- **[`CRITIQUE.md`](CRITIQUE.md)** — 渲染后设计评分表 + 逐轴修法 + 独立评审。
- **[`CATALOG.md`](CATALOG.md)** — 精选 palette 锚点（vibe/formality 一览），按此表选色。由 `templates/` 生成，勿手改。
- **[`templates/GENERATE.md`](templates/GENERATE.md)** — 没有合适锚点时，如何现场生成一套同形态 palette。
- **[`examples/`](examples/)** — 各原型的金标准白板，从匹配的那张起步。
- **[`templates/<slug>/design.md`](templates/)** — 每个 palette 一份（frontmatter：mood + 颜色 + 描边 + `catalog:` 块），只开你选中的那个。
- **[`scripts/fit-check.mjs`](scripts/fit-check.mjs)** — 渲染前文字适配/出血预测。
- **[`scripts/feishu_write.py`](scripts/feishu_write.py)** — 以用户身份直连飞书 OpenAPI 建文档 + 导出图（token 由扣子平台授权注入）。
- **[`CREDENTIALS.md`](CREDENTIALS.md)** — 飞书授权说明（扣子平台授权，一键即用）。

## 来源与许可（源码层署名，非商店营销文案）
MIT，详见随包 [`LICENSE`](LICENSE)。配色与媒介规则改编自 beautiful-feishu-whiteboard（© Zara Zhang，MIT）；构图/评审/fit-check/管线层为原创新增。
> 注：本段是源码层署名（满足 MIT + 扣子来源标注要求）。商店「详细介绍」营销文案不含此致谢。
