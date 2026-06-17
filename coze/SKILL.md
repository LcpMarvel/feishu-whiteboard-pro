---
name: 飞书白板大师
description: >
  把内容生成为「真正设计过」的可编辑飞书白板——强视觉层级、有意图的构图、留白，而不是
  一堆等大方块。先定设计简报（构图原型 + 配色策略 + 字号角色 + 反套路检查）再画，按坐标
  骨架施工，渲染后跑设计评审（层级/平衡/密度/对比/对齐）补到最弱项达标，最后写进你自己的
  飞书文档成为可编辑白板。需要一个飞书自建应用凭证（见 CREDENTIALS.md）。
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

- **飞书授权**：技能以**用户本人身份**写入其飞书租户，走 `lark-cli` 设备码授权——给用户一个授权链接、
  点一下即可，**无需用户建应用或填密钥**（详见 [`CREDENTIALS.md`](CREDENTIALS.md)）。授权在第 4 步按需触发。
- 沙箱已具备 Node（本地渲染）、`npx @larksuite/whiteboard-cli`、`lark-cli`（均 npx 自动下载）。

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

### 4. 授权 → 写进飞书 → 看实时白板 → 交付

授权用 [`scripts/feishu_auth.sh`](scripts/feishu_auth.sh)，**交互命令已封装成后台+刮 URL**，不要在一轮里
阻塞等待。每次给用户的授权链接都作为**本轮最终消息**发出（可配 `lark-cli auth qrcode` 生成二维码），等
用户确认授权后**下一轮**再续。

先查状态：`bash scripts/feishu_auth.sh status`。若 user 身份已 ready 且 token 有效 → 直接跳到写入。
否则按需走授权（首次最多两次浏览器授权，之后凭 `LARKSUITE_CLI_CONFIG_DIR` 持久化复用）：

```bash
# ① 确保有应用（首次会后台注册一个，打印 VERIFY_URL；幂等，不会重复建）
bash scripts/feishu_auth.sh app-begin       # → APP_OK 或 VERIFY_URL=<给用户授权的链接>
#    若是 VERIFY_URL：把链接发给用户授权，下一轮：
bash scripts/feishu_auth.sh app-finish       # → APP_OK（或 APP_PENDING 再等）

# ② 授予读写权限（输出 verification_url + device_code 的 JSON）
bash scripts/feishu_auth.sh login-begin      # 把 verification_url 发给用户授权，记下 device_code
#    用户授权后，下一轮：
bash scripts/feishu_auth.sh login-finish <device_code>   # 完成并打印 auth status
```

授权就绪后写入并导出：

```bash
bash scripts/feishu_write.sh --svg <dir>/diagram.svg --title "标题" --image <dir>/board.png
```

它以**用户本人身份**建文档（内嵌 `<whiteboard type="svg">`，服务端解析成可编辑节点）→ 返回**文档链接 +
白板 token** → 导出白板图。打开导出图核对版面（导出对版面/填充忠实，但文字颜色不可靠，颜色以实时文档为准）。

交付**两样**：飞书**文档链接** + 渲染图。然后告诉用户可随时**换 palette**，同构图重渲，只改颜色。

## 文件
- **[`RULES.md`](RULES.md)** — 媒介硬规则。必读。
- **[`COMPOSITION.md`](COMPOSITION.md)** — 原型库、字号体系、间距栅格、反套路。核心。
- **[`CRITIQUE.md`](CRITIQUE.md)** — 渲染后设计评分表 + 逐轴修法 + 独立评审。
- **[`CATALOG.md`](CATALOG.md)** — 35 套 palette，按此表选色。
- **[`examples/`](examples/)** — 各原型的金标准白板，从匹配的那张起步。
- **[`templates/<slug>/design.md`](templates/)** — 每个 palette 一份，只开你选中的那个。
- **[`scripts/fit-check.mjs`](scripts/fit-check.mjs)** — 渲染前文字适配/出血预测。
- **[`scripts/feishu_auth.sh`](scripts/feishu_auth.sh)** — 设备码授权（begin/complete/status）。
- **[`scripts/feishu_write.sh`](scripts/feishu_write.sh)** — 以用户身份写进飞书 + 导出图。
- **[`CREDENTIALS.md`](CREDENTIALS.md)** — 飞书授权说明（授权即用，无需自建应用）。

## 来源与许可（源码层署名，非商店营销文案）
MIT，详见随包 [`LICENSE`](LICENSE)。配色与媒介规则改编自 beautiful-feishu-whiteboard（© Zara Zhang，MIT）；构图/评审/fit-check/管线层为原创新增。
> 注：本段是源码层署名（满足 MIT + 扣子来源标注要求）。商店「详细介绍」营销文案不含此致谢。
