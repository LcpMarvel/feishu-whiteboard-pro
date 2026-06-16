# Critique — the post-render design pass

Correctness (overflow, overlap, clipping, arrows) is already clean by the time you're here — that was
the RULES.md loop. This gate is about **taste**: a board can be perfectly correct and still look flat.
Judge it as a designer.

## How to run it

1. **Look at the rendered PNG** (the real one, not from memory).
2. Score each of the five axes below: **pass / weak / fail**.
3. Name the **single weakest axis**. Apply its fix recipe with small targeted SVG edits.
4. **Re-render and look again.** Repeat.
5. Stop when no axis is `fail` and at most one is `weak` — or when two passes produce no real gain, in
   which case say plainly what's still imperfect rather than looping forever.

Fix **one axis per pass**, strongest-leverage first. A flat board almost always fails **Hierarchy**
or **Balance** before anything else — start there, not on alignment nitpicks.

### Independent review (for boards that matter)

You grade your own work generously — that's the trap. For any board the user will actually ship,
get a second pair of eyes that didn't build it:

- **Spawn a critique subagent** (Agent tool, e.g. `Explore` or general) and give it *only* the
  rendered PNG and the five axes below. Prompt it adversarially: *"You did not make this board. Find
  the single weakest axis and argue why it fails. Be harsh; do not praise."* Take its verdict as the
  weakest-axis input to step 3 above.
- A reviewer with no authorship bias catches the flat hierarchy or the lopsided balance you've
  already rationalised. Apply its finding, re-render, and only then trust the result.
- For a quick throwaway board, self-critique is fine. Scale the rigour to the stakes.

This pairs with the deterministic pre-render check (`scripts/fit-check.mjs`, run during the build):
fit-check catches *measurable* defects (a label wider than its box, a gutter intrusion, canvas
bleed) before you render; this gate and the independent reviewer catch *taste* defects that no
measurement can. Run both — they cover different failure classes.

## The five axes

### 1. Hierarchy — *is there an obvious first thing the eye hits?*
Squint at it (or imagine it blurred). If three regions compete equally, it fails. There must be one
clear focal point, then a clear second tier, then the rest.
- **Fail looks like:** everything the same size/weight; no entry point; reads as a uniform field.
- **Colour alone does not make a focal point.** This is the most common self-deception: "it's the
  focal because it's the saturated green one." A saturated box the *same size* as its neighbours will
  lose the first fixation to a higher-contrast element (a near-black box is the highest-contrast
  object on a cream canvas), to anything placed higher (top reads first), or to the title. The focal
  must also win on **size or isolation**, not just hue.
- **Fix:** make the focal element **physically the largest** object — enlarge it so it breaks its
  siblings' shared baseline and visibly outsizes them — and give it the only saturated fill. Then
  *demote the competitors*: shrink equal-sized siblings, cut a heavy black box's second line, thin a
  bright accent strip. A board whose stated purpose is one focal point but which has three co-equal
  anchors is a hierarchy failure of intent, not polish. (COMPOSITION.md §2, §3.)

### 2. Balance — *is visual weight distributed, or pooled in one corner?*
Dark/saturated masses are "heavy". Check that weight isn't all top-left with an empty bottom-right, and
that the composition isn't accidentally symmetric-and-dull.
- **Fail looks like:** one dense corner + large dead space elsewhere; or perfectly mirrored and lifeless.
- **Fix:** move or resize a secondary cluster to counter the heavy mass; pull content to fill dead
  zones, or intentionally let whitespace frame the focal point (active negative space, not a gap).
  Prefer deliberate asymmetry (COMPOSITION.md §H) over forced symmetry.

### 3. Density — *enough breathing room, and even across the board?*
Check padding and gaps against COMPOSITION.md §1. Cramped panels and edge-touching text read cheap;
vast empty panels read unfinished.
- **Fail looks like:** text jammed to panel borders; numerals touching edges; or one panel 80% empty
  while its neighbour overflows.
- **Fix:** enforce panel padding 32 and the section/gutter gaps; rebalance content between over- and
  under-full panels; widen a tight panel rather than shrinking its text below 16.

### 4. Contrast — *does every element read clearly against its ground?*
Text legibility and figure/ground separation. Remember opacity is ignored and the **PNG export
renders text colour unreliably** — verify colour via `+query --output_as raw` or the live board, not
the exported PNG (RULES.md).
- **Fail looks like:** mid-tone text on a mid-tone fill; small light text on near-black; two adjacent
  panels in near-identical fills that visually merge.
- **Fix:** push text to a high-contrast pair (dark ink on light, or large bold light on saturated
  dark); separate merging panels by a stronger fill step, a border, or a gutter. Use solid lighter
  hexes for tints, never alpha (RULES.md).

### 5. Alignment — *are edges and baselines on a shared grid?*
The cheapest tell of "thrown together". Panel edges, text starts, and connector endpoints should
land on shared x/y lines.
- **Fail looks like:** panels off by a few px; ragged left edges across a column; arrows meeting boxes
  off-centre; inconsistent column widths.
- **Fix:** snap edges to the COMPOSITION.md content band (x=80→1520) and column maths; align text
  starts to a shared x; centre connector endpoints on panel mid-lines. Make near-equal things exactly
  equal.

## One-line bar to clear

> A clear focal point, weight that feels settled, even breathing room, every label legible, edges on
> a grid — **and it does not look like an AI made it** (COMPOSITION.md §4). If all five hold, ship it.
