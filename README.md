# Examples — gold-standard boards

Worked boards that passed both gates (fit-check clean, design critique clear) and rendered well on
the real Feishu board. Each pairs a `.svg` (the editable source) with its `.png` (the render).

**Use them as a starting skeleton.** When the content matches one of these relationships, open the
matching `.svg`, copy its structure, and replace the content — coordinates, gutters, type scale, and
arrow connectors are already correct. This is faster and safer than composing from scratch, and it
anchors quality. Re-run `scripts/fit-check.mjs` after editing, since your labels differ in length.

`01`–`03` share one palette ([Riso Brut](../templates/riso-brut/)) so they read as a series. `04`–`07`
each use a **different** palette — Riso Brut, [Riptide Cobalt](../templates/riptide-cobalt/),
[Coral](../templates/coral/), and a **generated** one (`07`) — to show the composition is
palette-independent: swapping the palette keeps the layout and only changes the colours.

| File | Archetype (COMPOSITION.md) | Palette | Focal technique | Good for |
|---|---|---|---|---|
| `01-system-map` | System map (vertical zones + focal container) | Riso Brut | Subject node is the only saturated fill, largest, with an orange offset shadow; supporting nodes stay on cream | "where X sits", positioning, component/service maps |
| `02-pipeline-fork` | Linear flow with a symmetric fork/join (§A) | Riso Brut | The parallel section is enlarged and colour-blocked; the sequential prep/finalize steps are quiet cream boxes | processes, request lifecycles, "then it splits and rejoins" |
| `03-swimlane-sequence` | Swimlanes (§B), time flowing down | Riso Brut | One lane (the protagonist) gets a green header + heavier lifeline, giving a flat sequence diagram a focal | sequence diagrams, handshakes, protocols, multi-actor timing |
| `04-radial-system-map` | System map — radial / hub-and-spoke | Riso Brut | The central engine outsizes every satellite (~1.7×) **and** carries the only offset shadow, so it wins by size + colour, not colour alone; spokes are labelled connectors | hub-and-spoke architectures, "everything around a core", agent/platform maps |
| `05-comparison-matrix` | Comparison matrix (§D), 3 columns × 7 rows | Riptide Cobalt | Per-row colour-blocking marks the winning option; a taller colour-blocked verdict band closes the grid as the focal | option trade-offs, "X vs Y vs Z", decision tables |
| `06-timeline` | Timeline, time flowing left → right | Coral | Eras are ground bands; the climax era is a saturated hero band and the single key milestone is a dark hero card that wins hierarchy | histories, roadmaps, evolution, "how we got here" |
| `07-hierarchy` | Hierarchy — nested containment + relationship arrows | **generated** | Depth from nested fills (canvas → panel → slate → teal), not shadow; the focal layer holds the darkest mass | object models, containment trees, system decomposition |

## What makes each one work (so you can reproduce it, not just copy)

- **01** — a literal box-and-arrow architecture diagram is the AI-slop reflex (equal grey boxes, all-blue, draw.io look). It avoids that with an asymmetric vertical spine (external → cloud → the focal edge zone), exactly one saturated node that visibly **outsizes** its siblings, and warm cream + collision colour instead of tech-blue.
- **02** — the reflex is a flat row of identical numbered step boxes. It breaks the row: prep and finalize are quiet horizontal mini-rows, but the two parallel lanes blow up into the visual centre, because that fork is what the content is actually about. The fork is a single centred trunk that splits symmetrically — not a lopsided branch — and the join box is a quiet cream box, not a competing dark mass.
- **03** — the reflex is the grey mechanical sequence diagram. It uses the focal-lane move (colour one participant's whole lane) to create hierarchy where a sequence diagram normally has none, frames the polling `loop` as a distinct block, fills the otherwise-empty right side with a tall "concurrent work" panel, and highlights the one load-bearing message (the orange `commit`) in the accent colour.
- **04** — the reflex is N equal boxes joined by lines. It makes the hub dominate on **two** axes (largest size *and* the only saturated, shadowed fill) so the eye lands on the core first and then follows labelled spokes outward — colour alone would lose to a bigger or higher box, so size carries it too.
- **05** — the reflex is a flat grid where every cell reads equally and you can't see who wins. It colour-blocks the winning cell per row and closes with a taller verdict band, so the comparison has a *conclusion*, not just data. Note it deliberately leaves the weaker column honestly emptier rather than colouring cells to fake visual balance — the critique caught and kept this.
- **06** — the reflex is evenly-spaced dots on a line. It groups time into era bands, escalates to a saturated hero band at the climax era, and promotes one milestone to a dark hero card, so the timeline has a peak instead of a flat ribbon.
- **07** — the reflex is an indented bullet tree (or all-equal boxes). It encodes containment as **nested fill-darkness** (canvas → panel → slate → deep teal) instead of shadows, concentrates the darkest mass in the focal layer, and — notably — runs on a palette **generated** via [`templates/GENERATE.md`](../templates/GENERATE.md) ("Steel Infra", a cool teal/slate register), demonstrating that a fresh palette drops straight into the same composition.
