# feishu-whiteboard-pro

A Claude Code / agent **skill** for building genuinely *designed* Feishu / Lark (飞书) whiteboards —
not just nice colours, but deliberate composition: a clear focal point, real visual hierarchy,
intentional spacing. The board it produces is a real, **editable** Feishu whiteboard inside a doc,
not a screenshot.

It builds on [beautiful-feishu-whiteboard](https://github.com/zarazhangrui/beautiful-feishu-whiteboard)
(its 35 colour palettes and the hard rules of the SVG-whiteboard medium) and adds the layer that was
missing: **how to compose, and how to tell whether the result is actually good.**

## What it adds over a palette library

The medium is deliberately limited — one font, native rects/circles/connectors only, no gradients, no
filters, no opacity, no motion. So "beautiful" here means composition, hierarchy, rhythm, colour
discipline, and whitespace. This skill turns two soft, improvised steps into **gates**:

```
Understand content
   │
   ├─▶ GATE 1 · Design brief      archetype + focal point + colour strategy + type roles + anti-cliché
   ▼
Compose against a skeleton        archetype coordinates + fixed type scale + 8px spacing grid
   │
   ▼
Predict defects (fit-check)       deterministic: label-too-wide / gutter-intrusion / bleed, BEFORE render
   │
   ▼
Render → fix correctness          overflow / overlap / clipping / hand-drawn arrows
   │
   ▼
GATE 2 · Design critique          score hierarchy/balance/density/contrast/alignment; an independent
   │                              reviewer for boards that ship; fix the weakest axis; repeat
   ▼
Write into Feishu → verify live → deliver
```

- **`fit-check`** ([scripts/fit-check.mjs](scripts/fit-check.mjs)) — estimates every label's width
  (CJK ≈ 1em, Latin ≈ 0.6em) and flags overflow / gutter-intrusion / canvas-bleed *before* you render.
  Deterministic, no model cost.
- **Independent critique** — for boards that matter, a separate reviewer scores the render
  adversarially, so colour-only "fake" focal points and lopsided balance get caught instead of
  rationalised.

## Examples

Three gold-standard boards, one shared palette so they read as a series. Open the matching `.svg` as a
starting skeleton; its coordinates are already critique-clean.

| System map | Pipeline + fork/join | Swimlane sequence |
|---|---|---|
| ![system map](examples/01-system-map.png) | ![pipeline](examples/02-pipeline-fork.png) | ![sequence](examples/03-swimlane-sequence.png) |

## Prerequisites

- **Node 20+**
- **[`lark-cli`](https://www.npmjs.com/package/@larksuite/cli)** installed and authenticated:
  `npm install -g @larksuite/cli`, then `lark-cli config init` (scan the QR) and `lark-cli auth login`
- **`@larksuite/whiteboard-cli`** — used via `npx`, auto-downloads, no install needed
- A **Feishu / Lark account** (boards are written to your own tenant)

Run [`scripts/preflight.sh`](scripts/preflight.sh) to check all of the above.

## Install

Use the [`skills`](https://github.com/vercel-labs/skills) CLI — it detects your agent (Claude Code,
Cursor, Codex, …) and symlinks the skill into the right directory for you:

```bash
# global (user-level), available in all your projects:
npx skills add -g LcpMarvel/feishu-whiteboard-pro

# …or project-level, into the current repo only:
npx skills add LcpMarvel/feishu-whiteboard-pro
```

To try it once without installing: `npx skills use LcpMarvel/feishu-whiteboard-pro`.

<details>
<summary>Manual install (clone + symlink)</summary>

```bash
git clone https://github.com/LcpMarvel/feishu-whiteboard-pro.git

# Claude Code (user-level skills):
ln -s "$(pwd)/feishu-whiteboard-pro" ~/.claude/skills/feishu-whiteboard-pro
```

</details>

Restart the session; the skill then triggers whenever you ask to create or polish a Feishu whiteboard,
infographic, diagram, or visual explainer.

## What's in the box

| Path | What |
|---|---|
| [`SKILL.md`](SKILL.md) | The gated pipeline and orchestration |
| [`COMPOSITION.md`](COMPOSITION.md) | Archetype library (coordinate skeletons), type scale, spacing grid, anti-cliché list — the core |
| [`CRITIQUE.md`](CRITIQUE.md) | Post-render design rubric (5 axes) + independent-review instructions |
| [`RULES.md`](RULES.md) | Hard limits of the Feishu SVG whiteboard medium, verified empirically |
| [`CATALOG.md`](CATALOG.md) + [`templates/`](templates/) | 35 colour palettes |
| [`examples/`](examples/) | Gold-standard boards per archetype |
| [`scripts/`](scripts/) | `fit-check.mjs` (pre-render predictor) + `preflight.sh` |

## Credits & license

MIT. The 35 palettes and the medium rules are adapted from
**[beautiful-feishu-whiteboard](https://github.com/zarazhangrui/beautiful-feishu-whiteboard)** by
**Zara Zhang ([@zarazhangrui](https://github.com/zarazhangrui))** — © Zara Zhang, MIT. The composition,
critique, fit-check, and gated-pipeline layers are original additions. The design-judgment approach is
inspired by the **impeccable / frontend-design** skills (no code copied). See [`LICENSE`](LICENSE).
