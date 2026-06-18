# Generating a palette (when no anchor fits)

The [`CATALOG.md`](../CATALOG.md) anchors are the **reliable, swappable skins** — prefer one of them.
Generate a palette only when none of them serves the brief's mood, or the user wants a specific hue
the anchors don't carry. A generated palette must come out **structurally identical to an anchor**
(same `design.md` frontmatter) so it can be swapped, critiqued, and persisted like any other.

The colour *theory* below (OKLCH derivation, tinted neutrals, role dosage, dangerous combinations) is
distilled from the **impeccable** skill's `color-and-contrast` reference — borrowed and adapted to this
medium, no code copied. What impeccable can't know is the whiteboard medium; those rules come first.

## Medium constraints that shape every palette (non-negotiable)

These override any web/UI colour habit — the board is flat SVG, not CSS:

- **Canvas is never pure white.** Use a warm/tinted off-white (a hair of chroma, lightness ~92–96%).
  Pure white reads cheap and unprinted; the off-white temperature is the whole "designed paper" feel.
- **Ink is never pure `#000`.** Use a warm near-black with a tiny hue cast (lightness ~10–20%). Pure
  black is harsh and flat against a tinted ground.
- **Opacity is ignored — no alpha, ever.** Need a lighter tone, a tint, or a "faded" note surface?
  Compute a *real lighter hex*; never rely on transparency (RULES.md). A gradient becomes two flat tones.
- **Text-on-fill is asymmetric.** Large bold light text reads on a saturated or dark fill; **small
  light text on a coloured/near-black fill is unreliable** — put small text in a high-contrast panel
  (paper/cream) with dark ink. (RULES.md.)
- **Judge colour on the live board or `--output_as raw`, never the exported PNG** — the PNG renders
  text colour unreliably.

## Recipe

1. **Strategy + dosage** (from GATE 1, the commitment axis):
   - **Restrained** — tinted ground + **one** accent, accent ≤ ~10% of visual weight.
   - **Committed** — one colour carries 30–60% (large fields, hero bands); the rest neutral.
   - **Full** — 3–4 named roles that collide; use 2–3 per scene, never all at once.
2. **Pick the accent hue first** — a mood/brand decision. Do **not** reflex to blue (hue ~250) or
   warm orange (hue ~60); those are the AI-design defaults, not an answer.
3. **Derive shades in OKLCH**, then convert to hex: hold hue + chroma roughly constant and vary
   lightness; **drop chroma as you approach white or black** (high chroma at the extremes looks
   garish). Give every accent a `-dark` sibling for layered/comparison blocks (it also replaces any
   gradient — flat only).
4. **Canvas** = a very light tint cast toward the accent hue (L ~92–96%, chroma ~0.005–0.02). Warm, not white.
5. **Ink** = warm near-black, cast toward the accent/warm (L ~10–20%, small chroma). Not `#000`.
6. **Neutrals** = tint toward the accent hue (chroma 0.005–0.015) — pure grey reads dead next to
   colour. Provide a secondary and a tertiary text grey.
7. **Paper/panel** = if the canvas is saturated, add a near-white panel fill so small dark text has a
   home.
8. **Validate by role, not by eye**: body text ≥ 4.5:1 contrast, large/bold ≥ 3:1. Screen the
   dangerous combos — grey on colour (washed out), red/green (8% can't separate), yellow on white,
   blue on red (vibrates). Fix by darkening the background-coloured text or moving to a panel.
9. **Stroke language**: pick border weight + radius to match the mood (hairline warm-charcoal for
   tidy/editorial; 3–4px ink for brutalist; low/zero radius for squared, 12 for friendly-soft).

## Emit it as a template

Write the frontmatter **exactly like an anchor** (see any `templates/<slug>/design.md`):

```yaml
---
name: <Title Case>
description: >
  <one-or-two-line mood + the core strategy: what is canvas, what carries the accent, what's the spark>
catalog:
  level: Restrained | Balanced | Bold      # how loud it feels
  formality: Low | Medium | High
  vibe: <short comma phrase>
  signature:                               # canvas first, then 2–3 defining accents
    - "#RRGGBB <name>"
    - "#RRGGBB <name>"
colors:
  <role>: "#RRGGBB"   # per-colour usage note — which role it plays (canvas / ink / accent / panel / text-on-fill)
  # ... a one-line dosage rule (how many accents per scene, what carries text on a fill)
stroke:
  structural: "<border weight + where>"
  radius: "<0–N; the mood>"
# depth: FLAT — ... (or a `shadow:` block if the look uses hard offset shadows)
---

# <Name>
```

**Where it goes depends on who's running** — a generated palette is data the *user* owns, so default
to never writing into the skill's own directory:

- **Ephemeral (default, and the right choice at user runtime).** Keep this frontmatter block inline
  for the current board only. If the user might want it again, paste it into **their own project** (a
  `palettes/` note, the board's source folder — anywhere under their working dir), and re-feed it next
  time. This survives skill upgrades and never needs write access to the skill.
- **Do NOT persist into this skill's `templates/` at user runtime.** The skill usually lives in a
  managed install dir (`~/.claude/skills/…` or a plugin cache): a template written there is **wiped on
  the next `skills add` upgrade**, the try-once `skills use` dir is ephemeral, and writing outside the
  user's project may be denied or prompt. It would look saved and silently vanish.
- **Persist as a real template only when authoring the skill** — i.e. you're working inside a clone /
  this git repo. Then save `templates/<slug>/design.md` and run `node scripts/build-catalog.mjs`; it's
  durable because it's version-controlled. To ship a palette upstream, that's the path: add it here,
  open a PR. The generation layer and the curated set use one format precisely so this graduation is
  a copy, not a rewrite.
