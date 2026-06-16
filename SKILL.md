---
name: feishu-whiteboard-pro
version: 1.0.0
description: >
  Build beautiful, editable Feishu / Lark (飞书) whiteboards with deliberate composition, not just
  good colour. Use whenever the user wants to create or draw a Feishu whiteboard, infographic,
  diagram, poster, system map, or visual explainer and wants it to actually look designed — strong
  visual hierarchy, intentional layout, breathing room — rather than a templated grid of boxes. The
  agent commits to a design brief (composition archetype + colour strategy + type roles + an
  anti-cliché check) BEFORE drawing, builds against a coordinate skeleton with a fixed type scale and
  spacing grid, then runs a design-critique pass (hierarchy / balance / density / contrast /
  alignment) after rendering and fixes the weakest axis until it clears. Returns the doc link and the
  rendered image, and offers to switch palettes. Requires lark-cli (npm @larksuite/cli) installed and
  authenticated, and a Feishu/Lark account.
license: MIT. Palette templates and the medium rules are adapted from beautiful-feishu-whiteboard (MIT, © Zara Zhang @zarazhangrui); the composition, critique, fit-check, and gated-pipeline layers are original additions. Design-judgment approach inspired by the impeccable / frontend-design skills (no code copied).
---

# Feishu Whiteboard Pro

A design-judgment skill for Feishu SVG whiteboards. It does not just hand you a palette and let you
wing the layout — it forces a **design brief before you draw** and a **design critique after you
render**. The board you produce is a real, editable Feishu whiteboard inside a doc, not a screenshot.

The whiteboard medium is deliberately limited: one font, native rects/circles/connectors only, no
gradients, no filters, no opacity, no motion. So "beautiful" here means **composition, hierarchy,
rhythm, colour discipline, and whitespace** — never effects. Spend your craft there.

Three things make output good, and each has a home:
- **What the medium allows** → [`RULES.md`](RULES.md). Hard limits, verified on the real board. Always read.
- **How to compose** → [`COMPOSITION.md`](COMPOSITION.md). Archetypes with coordinate skeletons, the type scale, the spacing grid. The core of this skill.
- **Whether it's actually good** → [`CRITIQUE.md`](CRITIQUE.md). The post-render design rubric and how to fix each axis.

## When to use

- The user wants a Feishu / Lark whiteboard, infographic, diagram, poster, or visual explainer that
  should look genuinely designed — clear focal point, real hierarchy, not a wall of equal boxes.
- The user gives content ("explain X as a whiteboard", "turn this into a board") and wants it visual,
  editable, and on a Feishu canvas.
- The user names a style, or points at a palette.

## Step 0: prerequisites (check before doing anything)

Run [`scripts/preflight.sh`](scripts/preflight.sh), or check manually:

- **Node 20 or newer.**
- **`lark-cli`** (npm package **`@larksuite/cli`**), installed **and authenticated**. If missing:
  `npm install -g @larksuite/cli`, then `lark-cli config init` (scan the QR), then `lark-cli auth login`.
- **`@larksuite/whiteboard-cli`**, used via `npx`, auto downloads, no install needed.
- A **Feishu / Lark account**. The board is written to the user's own tenant.

If `lark-cli` is missing or not authenticated, tell the user exactly how to install and authenticate,
then stop. You cannot write a board without it.

## The pipeline

The old way — pick a palette, then lay it out "however reads best", then fix overflow — is exactly
how boards end up as bland grids. This skill replaces the two soft steps with **gates**: a design
brief before drawing, a design critique after rendering. Do not skip either.

```
Understand the content
   │
   ├─▶  GATE 1 · Design brief        (before any SVG — see below)
   │
   ▼
Compose against the skeleton         (COMPOSITION.md: archetype coords + type scale + spacing grid)
   │
   ▼
Render → fix correctness             (RULES.md workflow: overflow / overlap / clipping / arrows)
   │
   ▼
GATE 2 · Design critique             (CRITIQUE.md: score, fix the weakest axis, re-render, repeat)
   │
   ▼
Write into Feishu → view live → deliver
```

### 1. Understand the content

Find out what goes on the board: the content, its purpose, the audience. If the *content* is unclear,
ask one short question. Do **not** interrogate the user about visual style — you will commit to that
yourself in the brief, and offer a swap at the end.

### GATE 1 · Design brief (mandatory, before you write any SVG)

Read [`COMPOSITION.md`](COMPOSITION.md) and [`CATALOG.md`](CATALOG.md) first, then **write down** these
five commitments. This is the whole point of the skill — a board drawn without a brief drifts into a
uniform grid. Keep it to a few lines; it is for you, not the board.

1. **Narrative shape → archetype.** What relationship does the content actually have — sequence,
   comparison, hierarchy, radial, matrix, timeline, focus+detail? Pick the matching archetype from
   COMPOSITION.md and take its coordinate skeleton. The content's structure picks the archetype; do
   not default to a column-of-cards.
2. **Focal point.** Name the single thing the eye must hit first, and how it earns that (size, weight,
   colour, isolation, position). Exactly one primary focus per board.
3. **Colour strategy + palette.** Choose a strategy on the commitment axis — **Restrained** (tinted
   ground + one accent), **Committed** (one colour carries 30–60%), or **Full** (3–4 named roles) —
   *then* pick the CATALOG palette that serves it. Strategy first, swatches second.
4. **Type roles.** Assign the COMPOSITION.md type scale to the content: what is Display, what is
   Heading, what is Body, what is Caption. Hierarchy comes from this assignment, not from drawing.
5. **Anti-cliché check.** Write one line: *"The reflex version of this board is ___; I am avoiding it
   by ___."* (e.g. "reflex = three equal icon+title+text cards; avoiding by an asymmetric focus+detail
   split.") If you can't name the reflex, you're probably about to draw it. See COMPOSITION.md §Anti-cliché.

Tell the user, in one line, the archetype and palette you chose and why. Then build.

### 2. Compose against the skeleton

**If your chosen archetype matches one in [`examples/`](examples/), start from that `.svg`** — copy
its structure and replace the content. Its coordinates, gutters, type scale, and connectors are
already correct and critique-clean; editing a gold-standard board beats composing from a blank canvas.

Open **only the one** chosen [`templates/<slug>/design.md`](templates/) for the full palette notes.
Then write the SVG in a logical coordinate space (≈1600–1700 wide), following:

- the **archetype's coordinate skeleton** (COMPOSITION.md) — place panels on it, don't free-float;
- the **type scale** (COMPOSITION.md) — every label is a `<text>`; size/weight come from its assigned role; never set `font-family`;
- the **spacing grid** (COMPOSITION.md) — consistent panel padding, gutters, and section gaps;
- **native shapes only** and every other hard rule in [`RULES.md`](RULES.md).

Only the **content** goes on the canvas — never the prompt, the source, the style name, scope notes,
or any meta/"summary of…" line. (See RULES.md "Never echo the user's instructions".) That context goes
in your chat reply.

### 3. Render → fix correctness

**First, predict defects without rendering** — run the fit-check on your SVG:

```bash
node scripts/fit-check.mjs <dir>/diagram.svg   # path is relative to this skill dir
```

It estimates every label's width (CJK ≈ 1em, Latin ≈ 0.6em) and flags labels wider than their box,
between-box labels that spill into a neighbour, and canvas bleed/clipping — the exact hand-coordinate
defects that otherwise only surface mid-render. Fix every hit (widen the box, shorten the label, open
the gutter), then re-run until clean.

Then follow the build/verify loop in [`RULES.md`](RULES.md): render, **open the PNG and look**, then
fix tight margins, accidental overlaps, clipping, and hand-drawn arrowheads. Edit the `.svg` in place
with small targeted edits; batch all fixes from one view into a single pass before re-rendering. This
step is about **correctness**, not taste — taste is the next gate.

### GATE 2 · Design critique (mandatory, after correctness is clean)

Now judge it as a designer, not a linter. Open [`CRITIQUE.md`](CRITIQUE.md), score the board on its
five axes (hierarchy, balance, density, contrast, alignment), name the **weakest** one, apply that
axis's fix recipe, and re-render. Repeat until no axis is failing (or two passes yield no real gain —
then say what's still imperfect). A board that passes correctness but looks flat almost always fails
**hierarchy** or **balance** first — start there.

For a board the user will actually ship, don't grade your own work — spawn an **independent critique
subagent** given only the render and the rubric, prompted to be adversarial (see CRITIQUE.md
§Independent review). Authorship bias is exactly what makes you rationalise a flat hierarchy.

### 4. Write into Feishu → view live → deliver

Write the SVG into a Feishu doc as an editable whiteboard (commands in [`RULES.md`](RULES.md)), then
view the **live** board image and fix any remaining layout issues (the export is faithful for layout
and fills, but not text colour — verify colour via `--output_as raw` or the live doc).

Deliver **both**: the **Feishu doc link** and the **rendered image**. Then tell the user they can
**switch to a different palette** any time and you'll re-render the same composition in it — note that
a palette swap keeps the composition; only the colours change.

## Files

- **[`RULES.md`](RULES.md)** — medium hard rules + exact build/write/verify commands. Always read.
- **[`COMPOSITION.md`](COMPOSITION.md)** — archetype library, type scale, spacing grid, anti-cliché. The core.
- **[`CRITIQUE.md`](CRITIQUE.md)** — the post-render design rubric, per-axis fixes, and independent review.
- **[`CATALOG.md`](CATALOG.md)** — the 35 palettes with vibe/formality. Pick from this table alone.
- **[`examples/`](examples/)** — gold-standard boards per archetype; start from the matching one.
- **[`templates/<slug>/design.md`](templates/)** — one per palette; open only the chosen one.
- **[`scripts/fit-check.mjs`](scripts/fit-check.mjs)** — pre-render text-fit / gutter / bleed predictor.
- **[`scripts/preflight.sh`](scripts/preflight.sh)** — dependency and auth check.
