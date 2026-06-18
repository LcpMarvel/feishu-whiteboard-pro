# feishu-whiteboard-pro

A Claude Code / agent **skill** for building genuinely *designed* Feishu / Lark (飞书) whiteboards —
not just nice colours, but deliberate composition: a clear focal point, real visual hierarchy,
intentional spacing. The board it produces is a real, **editable** Feishu whiteboard inside a doc,
not a screenshot.

It builds on [beautiful-feishu-whiteboard](https://github.com/zarazhangrui/beautiful-feishu-whiteboard)
(its colour palettes and the hard rules of the SVG-whiteboard medium) and adds the layer that was
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

Seven gold-standard boards, each critique-clean and rendered on a real Feishu board. They span
different archetypes and palettes — one even on a *generated* palette — yet all come from the same
pipeline, so the composition is palette-independent. Open the matching `.svg` in
[`examples/`](examples/) as a starting skeleton; its coordinates are already critique-clean.

**Four complex boards, four different palettes:**

| | |
|:--:|:--:|
| ![Radial system map](examples/04-radial-system-map.png)<br>**Radial system map** · Riso Brut | ![Comparison matrix](examples/05-comparison-matrix.png)<br>**Comparison matrix** · Riptide Cobalt |
| ![Timeline](examples/06-timeline.png)<br>**Timeline** · Coral | ![Hierarchy](examples/07-hierarchy.png)<br>**Hierarchy** · *generated* palette |

**Three foundational boards, one shared palette (Riso Brut):**

| | | |
|:--:|:--:|:--:|
| ![System map](examples/01-system-map.png)<br>**System map** | ![Pipeline + fork/join](examples/02-pipeline-fork.png)<br>**Pipeline + fork / join** | ![Swimlane sequence](examples/03-swimlane-sequence.png)<br>**Swimlane sequence** |

## Colour — a curated set, or generated to fit

Colour here is a **design system, not a swatch list**: every palette assigns roles (canvas, ink,
accents, panels) with usage notes and a commitment dosage, so the agent knows *how* to deploy each
colour, not just which hex exists.

- **A tight curated set.** [`CATALOG.md`](CATALOG.md) lists the anchor palettes spanning restrained →
  bold; pick one by mood and formality. Each is one `templates/<slug>/design.md` and is the single
  source of truth — the catalogue table is generated from them by `scripts/build-catalog.mjs`.
- **Generated when none fits.** If no anchor matches the brief, the skill generates a palette via
  [`templates/GENERATE.md`](templates/GENERATE.md) — OKLCH shade derivation, tinted neutrals, role
  dosage, and the medium's own constraints (canvas never pure white, ink never `#000`, flat / no
  alpha). It comes out in the **same frontmatter shape** as an anchor, so it stays swappable and can be
  saved as a template. The hierarchy board above runs on a generated "Steel Infra" palette.
- **Swap any time.** A palette swap keeps the composition and only changes the colours.

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
| [`templates/`](templates/) | A tight set of curated colour palettes (one `design.md` each) — the single source of truth |
| [`CATALOG.md`](CATALOG.md) | The pick-a-style table, **generated** from `templates/` by `scripts/build-catalog.mjs` |
| [`templates/GENERATE.md`](templates/GENERATE.md) | How to generate a fresh palette (same frontmatter shape) when no anchor fits |
| [`examples/`](examples/) | Seven gold-standard boards per archetype (editable `.svg` + render) |
| [`scripts/`](scripts/) | `fit-check.mjs` (pre-render predictor), `build-catalog.mjs` (regenerate CATALOG), `preflight.sh` |

## Credits & license

MIT. A curated, distilled subset of the palettes and the medium rules are adapted from
**[beautiful-feishu-whiteboard](https://github.com/zarazhangrui/beautiful-feishu-whiteboard)** by
**Zara Zhang ([@zarazhangrui](https://github.com/zarazhangrui))** — © Zara Zhang, MIT. The composition,
critique, fit-check, gated-pipeline, and palette-generation layers are original additions. The
design-judgment approach is inspired by the **impeccable / frontend-design** skills (no code copied).
See [`LICENSE`](LICENSE).
