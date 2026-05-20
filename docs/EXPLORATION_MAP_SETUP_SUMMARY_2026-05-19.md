# Exploration / Research Map Setup Summary

**Date:** 2026-05-19
**Status:** Baseline established — map live, pressure-tested, code+industry scan applied
**Reversible:** Additive only; nothing in repo state was removed or rewritten
**Next pending action:** Competitor app teardown OR open-dataset scan (user has not yet chosen)

---

## Purpose

Capture, in one place, what was built for the exploration map, the decisions made (especially the rejection of shrink recommendations), and the current state of the artefacts — so the next pass (competitor / dataset) starts from a clean documented baseline rather than from chat memory.

---

## What Was Built

### 1. Master index — `docs/EXPLORATION_TOPICS.md` (1458 lines)
- Entries 1–35 across the original 8 categories:
  Capture & Identification · Reuse & Repair · Recycling & Material Flow ·
  Behaviour & Habit Loops · Community & Civic · Knowledge & Data ·
  Business Model & Sustainability · Cross-cutting Platform & Trust.
- Entry **27a — Token Economy & Pricing Coherence** added as the in-flight
  work anchor (2026-05-19).
- ASCII **dependency view** + **category map** included.
- "Existing artefacts" section links the planning stack and the
  brainstorm files so the map does not pretend to be the only artefact.
- Entries **A1–A25** in a separate provenance-tagged section at the bottom,
  added from the code + docs + industry scan pass. Three new categories
  surfaced there: Platform & Release Engineering, Growth & Distribution
  Surfaces, Disposal Facilities & Local Knowledge.
- Industry signals **A23 (EU DPP / ESPR)**, **A24 (VLM-for-waste research)**,
  **A25 (MRF-side competitors)** were validated via web search before being
  added.

### 2. Frontier bets — `docs/EXPLORATION_FRONTIER.md` (268 lines)
- 10 frontier bets **F1–F10**, each with kill criteria and
  "what would have to be true" tests.

### 3. Phasing — `docs/EXPLORATION_ROADMAP_WHILE_BUILDING.md` (213 lines)
- NOW / NEXT / LATER mapping:
  - **N1–N6** (N6 = Token Economy IN FLIGHT)
  - **X1–X5** next-shelf
  - **L1–L5** later
- Frames the map as concurrent with build, not blocking it.

### 4. Per-topic folder — `docs/exploration/`
- `README.md` (41 lines) — folder convention.
- `backlog.md` (167 lines) — append-only capture with promotion log.
- `ARCHIVE.md` (45 lines) — skeleton for killed/superseded topics
  (no entries yet — nothing has been killed).

### 5. Pressure test artefact — `docs/brainstorm_exploration_map_2026-05-19.md` (267 lines)
- Output of the wide-open-brainstorm run against the initial map.
- Recommended cutting 35 → 10 topics and 5 → 1 NOW reds.
- Preserved in repo even though its recommendations were rejected
  (see "Decisions" below).

### 6. Index — `docs/DOCUMENTATION_INDEX.md`
- New **EXPLORATION / RESEARCH MAP** section linking all of the above.

---

## Decisions

### D1 — Rejected shrink recommendations from brainstorm
- The brainstorm pressure test recommended applying implementation
  discipline (cut, focus, one thing at a time) to the map.
- **Stance:** this is an exploration artefact, not an implementation plan.
  Breadth is the deliverable. Shrinking it defeats the purpose.
- **Accepted only additive changes**: link existing artefacts the map
  ignored, add Token Economy as 27a, add dependency view, create ARCHIVE
  skeleton, reframe Classification History Schema as moat/asset.

### D2 — Source artefacts win over the index
- When source files disagree with `EXPLORATION_TOPICS.md`, source wins;
  the index is updated, never forked.

### D3 — Mirror `travel_agency_agent` structure
- `Docs/EXPLORATION_TOPICS.md` (master) + `Docs/EXPLORATION_FRONTIER.md`
  (frontier) + `Docs/EXPLORATION_ROADMAP_WHILE_BUILDING.md` (phasing) +
  per-topic folder + append-only backlog is a proven pattern from that
  repo and is treated as real evidence the structure works.

### D4 — Preserve trails
- Brainstorm files, promotion log, ARCHIVE skeleton, provenance tags on
  scan-added entries (A1–A25) are all kept linked, even when partial or
  superseded.

### D5 — Scan additions live in a separate provenance section
- A1–A25 are tagged with source (code / existing-docs / industry) so the
  origin of each topic is auditable. They are not merged into the 1–35
  numbering to keep provenance distinguishable from the original
  category synthesis.

### D6 — Token Economy is acknowledged inside the map
- 27a + N6 (IN FLIGHT) ensure the map reflects today's active build
  rather than pretending exploration is happening in a vacuum.

---

## Current State of the Map (numbers)

| Artefact | Lines | What it holds |
|---|---|---|
| `docs/EXPLORATION_TOPICS.md` | 1458 | 35 + 27a + A1–A25 entries, dep view, category map, artefact links |
| `docs/EXPLORATION_FRONTIER.md` | 268 | 10 frontier bets F1–F10 with kill criteria |
| `docs/EXPLORATION_ROADMAP_WHILE_BUILDING.md` | 213 | NOW (N1–N6) / NEXT (X1–X5) / LATER (L1–L5) |
| `docs/exploration/backlog.md` | 167 | Append-only capture + promotion log |
| `docs/exploration/ARCHIVE.md` | 45 | Skeleton (no killed topics yet) |
| `docs/exploration/README.md` | 41 | Folder convention |
| `docs/brainstorm_exploration_map_2026-05-19.md` | 267 | Pressure-test artefact (recommendations rejected, file preserved) |

Total exploration artefact surface: **2459 lines** across 7 files, plus
the DOCUMENTATION_INDEX section.

---

## Pending — Next Pass (not yet chosen)

User has not yet committed to which optional next pass to run. Options on the table:

- **(a) Consumer-app teardown** — Litterati, OpenLitterMap, Bower,
  Trashbot, EPA / BBMP official apps. Output would be new topic entries
  in `EXPLORATION_TOPICS.md` and/or `backlog.md`, provenance-tagged
  `source: competitor-teardown`.
- **(b) Open-dataset scan** — TrashNet, TACO, OpenLitterMap data.
  Output would be entries under Knowledge & Data + a possible new
  Datasets sub-category, provenance-tagged `source: dataset-scan`.

Either pass will be additive in the same provenance-tagged style as
A1–A25. Neither pass renumbers existing entries.

---

## How To Resume This Work

1. Read this file.
2. Skim `docs/EXPLORATION_TOPICS.md` table of contents and the A1–A25 provenance section.
3. Confirm with user which next pass (a / b / both / neither).
4. Append new entries with explicit `source:` tag in the same separate
   section style used for A1–A25 — do **not** merge into the 1–35
   numbering.
5. Append to `docs/exploration/backlog.md` promotion log when anything
   gets promoted out of backlog into the main index.
6. Add a row to the table in this file (or write a follow-up
   `EXPLORATION_MAP_*_YYYY-MM-DD.md`) if the pass meaningfully changes
   the surface.

---

## Cross-references

- Brainstorm stack (synthesis + 8 role files):
  `docs/brainstorm_synthesis_2026-05-19.md` and siblings.
- Exploration map pressure test:
  `docs/brainstorm_exploration_map_2026-05-19.md`.
- Related in-flight worklogs:
  `docs/PHASE0_IMPLEMENTATION_SUMMARY_2026-05-19.md`,
  `docs/WORKLOG_ADDENDUM_SAST_20260312.md`,
  `docs/ai_service_refactor_motto_v2_2026-05-19.md`.
- Token economy backlog: `TOKEN_ECONOMY_TODO.md` (repo root).
