# `docs/exploration/` — Per-Topic Research

This folder holds **detailed exploration documents** referenced from the master index.

- **Master index**: [../EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md)
- **Frontier bets**: [../EXPLORATION_FRONTIER.md](../EXPLORATION_FRONTIER.md)
- **Roadmap mapping**: [../EXPLORATION_ROADMAP_WHILE_BUILDING.md](../EXPLORATION_ROADMAP_WHILE_BUILDING.md)
- **Raw idea backlog**: [./backlog.md](./backlog.md) — append-only capture before promotion.

## Naming convention

- `UPPER_SNAKE_CASE.md` for topic-level docs (mirrors travel_agency_agent style):
  - `MULTI_MODEL_AI_ROUTING.md`
  - `EVAL_HARNESS_AND_GOLDEN_SETS.md`
  - `REGION_AWARE_RULESETS.md`
- For dated exploration sessions (snapshots, brainstorms), append the ISO date:
  - `OPEN_EXPLORATION_IDEATION_2026-05-19.md`
  - `OFF_MAP_CANDIDATES_2026-05-19.md`

## Required structure for each doc

Every exploration doc should declare, near the top:

1. **Decision it unblocks** — what code / product change this research enables.
2. **Key questions** — the concrete unknowns being resolved.
3. **Kill criteria** — conditions under which we drop the topic.
4. **Status** — Seed / Active / Decided / Killed, with date.
5. **Links** — back to the master index entry, and to related explorations.

## Status markers are not a close signal

A topic marked `[✓]` (complete), `[🟡]` (medium priority), or `[🟢]` (low priority) in the master index is **always open for further deep dives**. Status reflects current urgency — not that a topic is settled. New information, changed context, or fresh questions can justify re-opening any entry. Document findings, update the status in the index, and include a link back.

## Agent policy: map-first exploration

Any time you encounter something worth even a glance — while checking docs, reading code, browsing online, during research, debugging, feature work, or random discovery — add it to the map. The bar is the lowest possible: if it's interesting enough to notice, it's worth a map entry. Do not filter by category or wait for "meaningful impact." Surface it with a one-liner, link it, and let prioritization happen in the index.

Explicit user requests to add a topic are always honored without extra justification.

**Nothing on the map is deleted unless explicitly requested by the user or recommended with detailed written reasoning.** Status markers are progress indicators, not deletion triggers. Superseded topics are archived in-place or marked.

## Lifecycle

```diagram
╭─────────╮   promote   ╭────────────╮   completes   ╭──────────────╮
│ backlog │────────────▶│ exploration│──────────────▶│ built artefact│
│  .md    │             │   doc      │               │ + index update│
╰────┬────╯             ╰─────┬──────╯               ╰──────┬───────╯
     │                        │                             │     │ killed                      │ killed                      │
     ▼                        ▼                             ▼
   archive in place with rationale     status [✓] in EXPLORATION_TOPICS.md
```
