# Composition — Feishu Whiteboard

Colour and the medium rules are handled elsewhere (CATALOG.md, RULES.md). This file is about
**where things go and how big they are**: the part the old skill left to improvisation. Three systems
and an archetype library. Use them as a scaffold to fill, not a free canvas to fill from scratch.

All coordinates assume a logical space **≈1600 wide** (let height follow the content). They are a
starting skeleton — nudge them, but keep the *proportions* and the *spacing rhythm*.

---

## 1. The grid (spacing system)

Consistent spacing is what separates "designed" from "boxes someone dropped on a canvas". One spacing
scale, used everywhere. Base module = **8**; every gap is a multiple of it.

| Token | Value | Use |
|---|---|---|
| Outer margin | **80** | canvas edge → first content. Never let content touch the edge. |
| Section gap | **56–72** | between major regions (title block → body, row → row) |
| Gutter | **40** | between sibling panels/columns in the same row |
| Panel padding | **32** | panel border → its inner content (text, sub-shapes) |
| Inline gap | **16–24** | between stacked lines/items inside a panel |
| Tight gap | **8** | label → its value, icon → its text |

Working frame: with margin 80, the content band is **x ∈ [80, 1520]**, width **1440**. Carve columns
out of 1440 minus gutters (e.g. 3 columns = (1440 − 2·40)/3 ≈ **453** each).

**Rhythm, not uniformity.** Equal padding everywhere reads as monotony. Give the focal region more
air than the rest; let a secondary cluster sit tighter. Vary deliberately, never randomly.

---

## 2. The type scale (single font: Noto Sans SC)

There is no typeface choice — hierarchy is **size + weight + casing** only. Use these five roles; the
contrast between adjacent steps is ≥1.4×, never a flat scale. Every label is a `<text>`; never set
`font-family`. Keep nothing below 16 (RULES.md).

| Role | Size | Weight | Use |
|---|---|---|---|
| **Display** | 64–80 | 900 (black) | the board title, or one hero number/word. **At most one per board.** |
| **Heading** | 32–40 | 700 (bold) | region / panel titles |
| **Subhead** | 22–26 | 700 | sub-titles, the lead line inside a panel |
| **Body** | 18–20 | 400–500 | the actual content text |
| **Caption** | 16 | 500 | small labels, axis ticks, badge text — only inside high-contrast panels |

**Hierarchy is set in the brief, executed here.** Three weights max in play at once. If everything is
bold, nothing is. Big + black is reserved for the focal point you named — don't spend it twice.

---

## 3. Archetype library

Pick by the **relationship in the content**, not by habit. Each archetype gives a skeleton, a focal
strategy, and where the title goes. Place panels on the skeleton; do not free-float.

> **Focal points win on size, not colour.** Each archetype below names a focal element. Making it the
> saturated one is necessary but *not sufficient*: a coloured box the same size as its neighbours
> loses the eye to a near-black box (highest contrast on cream), to anything higher on the canvas, or
> to the title. So make the focal **physically the largest** — large enough to break its siblings'
> shared baseline — and actively *demote* competitors (shrink equal siblings, trim a heavy dark box,
> thin a bright strip). One winner, by size and colour together.

> Title block default (all archetypes unless noted): top-left, `x=80 y=80`, Display title, optional
> one-line Subhead beneath it. Left-aligned reads as more designed than centred for explanatory boards.

### A. Linear Flow / Pipeline — *sequence, process, "X then Y then Z"*
Stages left→right, connected by native arrow connectors (`marker-end`, RULES.md). 3–6 stages.
```
title  x80 y80
stages: 4 panels, y=320, h=300, w≈300, gutter=40   (x = 80, 420, 760, 1100)
arrows: between panels, horizontal, marker-end
```
Focal: the **outcome** stage (last, or the one that matters) — make it larger or the only saturated
fill; others tinted. Don't make all stages identical — that's the cliché. Optional: a thin baseline
rule under the row to ground it.

### B. Swimlanes — *parallel tracks across a shared axis (teams, phases, layers over time)*
2–4 horizontal lanes; a shared left label column; items flow rightward within each lane.
```
title  x80 y80
lane labels: x=80, w=220        (Heading, right-aligned to the lane)
lane bodies: x=320 → 1520, each lane h≈220, vertical gap=40
```
Focal: the lane (or the one item) carrying the message — saturate it, tint the rest. A faint full-width
divider between lanes keeps them legible without boxing every cell.

### C. Hub & Spoke (radial) — *one central concept with satellites; "X has these N aspects"*
Central node, 4–6 satellites around it, straight connectors from hub to each.
```
hub: circle/rounded-rect centred ≈ (800, 540), the largest element
satellites: ≈480px radius around the hub, evenly spaced, smaller, uniform size
connectors: straight lines hub→satellite (no arrowheads unless directional)
```
Focal: the **hub** by definition — biggest, most saturated, Display or Heading type. Satellites are
peers: keep them the *same* size and weight as each other so the hub clearly dominates. Title can sit
top-left or be absorbed into the hub if the hub *is* the title.

### D. Comparison Columns — *vs, before/after, option A vs B (vs C)*
2–3 equal columns; aligned rows of attributes so the eye scans across.
```
title  x80 y80
columns: 2 → w=700 each (x=80, 820); 3 → w≈453 (x=80, 573, 1067); gutter=40
column header: Heading at top of each column, in a coloured cap
shared rows: attribute labels align across columns at the same y
```
Focal: the **recommended / winning** column — give it the saturated fill or a hard offset shadow
(RULES.md), leave the others on tinted ground. Symmetric columns with one asymmetric emphasis beats
three identical ones.

### E. Layered Stack — *architecture tiers, hierarchy of levels, "built on top of"*
Full-width horizontal bands stacked vertically; top = highest abstraction (or vice-versa, state which).
```
title  x80 y80
bands: full content width (x=80→1520), each h≈160, vertical gap=24
       label on the left inside each band; contents as chips to the right
```
Focal: the layer the board is about — saturate that band, tint the others; or widen it slightly.
Bands of *varying* height (the important one taller) reads better than identical stripes.

### F. Timeline — *milestones along a date/phase axis*
One strong horizontal axis; events as nodes above/below, alternating to use vertical space.
```
title  x80 y80
axis: horizontal line y≈540, x=120→1480, with tick marks
nodes: alternate above (y≈380) and below (y≈700) the axis; connector stub to each tick
```
Focal: the current / pivotal milestone — larger node, saturated; past muted, future tinted. Don't
cram every node to the same size; let the key date own more space.

### G. 2×2 Matrix / Quadrant — *two dimensions, four positions (effort/impact, etc.)*
Two labelled axes, four cells; items placed by position, not listed.
```
title  x80 y80
plot: square ≈ 900×900 centred horizontally (x=350→1250, y=240→1140)
axis labels: outside the plot, Heading; quadrant labels: Caption inside each cell corner
```
Focal: the "winning" quadrant (e.g. high-impact/low-effort) — tint its cell, place the hero items
there largest. The axes themselves should be quiet (thin rules), the items loud.

### H. Focus + Detail — *one big idea with supporting points; the anti-grid default*
Asymmetric split: a large focal panel + a column/row of smaller supporting panels. Use this whenever
the content has **one main thing**, instead of reflexively making equal cards.
```
title  x80 y80
focus panel: x=80, w≈880, h≈560 — the hero (Display number / key statement / central diagram)
support: right column, x=1000, w≈520, 3 stacked panels, h≈170, gap=40
```
Focal: the big panel, obviously — it should be 1.5–2× any support panel. This asymmetry *is* the
hierarchy; resist the urge to even it out.

**Combine when needed.** Real boards often nest archetypes (a pipeline whose last stage opens into a
2×2; a focus panel above three comparison columns). Compose; don't force one mould.

---

## 4. Anti-cliché check (run it in the brief)

If a board is forgettable it usually fell into one of these. Name your reflex, then dodge it.

- **The equal-card grid.** N identical rectangles, each icon + title + text. The single most common
  AI-whiteboard tell. Almost any content has a focal point — use **Focus + Detail (H)** or saturate
  one card. Equal weight = no hierarchy = bland.
- **Everything centred.** Centre-aligned title, centred columns, centred text. Reads timid and
  template-y. Default to **left-aligned** titles and text; centre only a true hub or a poster headline.
- **The category-reflex palette.** Tech→blue pipeline, finance→navy+gold, eco→green. If someone could
  guess your palette from the topic alone, pick a different CATALOG style on purpose.
- **Uniform everything.** Same panel size, same padding, same weight throughout. Monotony. Vary the
  focal region's size and air (§1 rhythm, §2 scale).
- **Box-in-a-box.** Panels inside panels inside panels. Each nesting level should earn itself; two is
  usually one too many. A tint or a divider often replaces a border.
- **Decorative chrome.** Kickers, footers, slugs, "v1.0", date stamps, the style name on the canvas.
  Cut all of it (RULES.md). Every text element must be load-bearing.

The litmus: *could someone glance at this and say "an AI made that" with no doubt?* If yes, the
weakest axis is usually hierarchy — go to CRITIQUE.md.
