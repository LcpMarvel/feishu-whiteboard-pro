# Examples — gold-standard boards

Worked boards that passed both gates (fit-check clean, design critique clear) and rendered well on
the real Feishu board. Each pairs a `.svg` (the editable source) with its `.png` (the render).

**Use them as a starting skeleton.** When the content matches one of these relationships, open the
matching `.svg`, copy its structure, and replace the content — coordinates, gutters, type scale, and
arrow connectors are already correct. This is faster and safer than composing from scratch, and it
anchors quality. Re-run `scripts/fit-check.mjs` after editing, since your labels differ in length.

All three are the same palette ([Riso Brut](../templates/riso-brut/)) so they read as a series: one
warm cream canvas, 4px ink borders, hard offset shadows, one saturated focal colour. Swapping the
palette keeps the composition and only changes the colours.

| File | Archetype (COMPOSITION.md) | Focal technique | Good for |
|---|---|---|---|
| `01-system-map` | System map (vertical zones + focal container) | Subject node is the only saturated fill, largest, with an orange offset shadow; supporting nodes stay on cream | "where X sits", positioning, component/service maps, who-talks-to-whom |
| `02-pipeline-fork` | Linear flow with a symmetric fork/join (§A) | The parallel section is enlarged and colour-blocked; the sequential prep/finalize steps are quiet cream boxes | processes, request lifecycles, anything with a "then it splits and rejoins" shape |
| `03-swimlane-sequence` | Swimlanes (§B), time flowing down | One lane (the protagonist every message touches) gets a green header + heavier lifeline, giving an otherwise-flat sequence diagram a clear focal | sequence diagrams, handshakes, protocols, multi-actor timing |

## What makes each one work (so you can reproduce it, not just copy)

- **01** — a literal box-and-arrow architecture diagram is the AI-slop reflex (equal grey boxes, all-blue, draw.io look). It avoids that with an asymmetric vertical spine (external → cloud → the focal edge zone), exactly one saturated node that visibly **outsizes** its siblings, and warm cream + collision colour instead of tech-blue.
- **02** — the reflex is a flat row of identical numbered step boxes. It breaks the row: prep and finalize are quiet horizontal mini-rows, but the two parallel lanes blow up into the visual centre, because that fork is what the content is actually about. The fork is a single centred trunk that splits symmetrically — not a lopsided branch — and the join box is a quiet cream box, not a competing dark mass.
- **03** — the reflex is the grey mechanical sequence diagram. It uses the focal-lane move (colour one participant's whole lane) to create hierarchy where a sequence diagram normally has none, frames the polling `loop` as a distinct block, fills the otherwise-empty right side with a tall "concurrent work" panel, and highlights the one load-bearing message (the orange `commit`) in the accent colour.
