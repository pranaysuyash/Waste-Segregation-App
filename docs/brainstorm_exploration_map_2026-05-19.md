# Wide-Open Brainstorm — Exploration Map Pressure Test (2026-05-19)

**Date:** 2026-05-19
**Mode:** Single-agent (no external LLM CLIs detected); all roles dispatched as strongly differentiated subagent voices in one pass.
**Subject under test:** The exploration/research map just built for the ReLoop:
- [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md) — 35 topics, 8 categories
- [EXPLORATION_FRONTIER.md](EXPLORATION_FRONTIER.md) — 10 frontier bets with kill criteria
- [EXPLORATION_ROADMAP_WHILE_BUILDING.md](EXPLORATION_ROADMAP_WHILE_BUILDING.md) — NOW / NEXT / LATER phase mapping
- [exploration/backlog.md](exploration/backlog.md) — append-only capture

**Seed prompt (reformulated):** Pressure-test this exploration map. Is the structure right for *this* project at *this* stage? What's missing, over-indexed, mis-categorized, or actively counterproductive? What would the user (Pranay) feel opening it? What would kill the map?

**Permission:** Be practical, weird, ambitious, and willing to recommend killing the map itself.

---

## 1. North Star / Product Thesis (10k ft)

The map's *intent* is right: **separate "what we still need to learn" (research) from "what we plan to build" (planning roadmaps).** That distinction doesn't exist anywhere else in this repo, which already drowns in 5+ overlapping roadmap files.

The map's *form* — 35 topics, 8 categories, 4 files — risks reproducing the problem it's solving: another parallel doc tree that decays into the `planning/` graveyard.

Thesis the room converged on: **the structure is right; the scale is wrong; the workflow is missing.**

---

## 2. What Existing Tools / Current Approaches Miss

What the current map *does* add over what was already in the repo:

- A single index of unknowns (none existed)
- Explicit kill criteria for frontier bets (none existed)
- A NOW/NEXT/LATER phase mapping tied to de-risk questions, not feature lists (none existed)
- A round-trip lifecycle: backlog → exploration doc → built artefact + index update (no other doc tree has this)

What it still misses, that the room surfaced:

- **A trigger.** Nothing makes anyone open this file. APP_KNOWLEDGE_BASE.md has a clear "read this before changing anything" forcing function. The exploration map has no such hook.
- **A dependency graph.** Eval Harness blocks Multi-Model Routing blocks On-Device. The map currently presents 35 independent topics. They are not independent.
- **Expiry / staleness.** No topic has a "re-evaluate by" date. Static category maps die quietly.
- **Acknowledgement of existing artefacts.** Today's 9 `brainstorm_*_2026-05-19.md` files on the token economy aren't linked from the map. Neither is `planning/ideas_to_explore.md` (already a 600+ line ideation file). The map walks into a room and pretends it's empty.

---

## 3. Big Ideas, Practical to Wild

### Practical now

1. **Cut 35 topics to ≤10 active topics.** Move the rest to `exploration/backlog.md`. Solo projects can't maintain 35 living research tracks. Travel_agency_agent has a team; this doesn't.
2. **Cap NOW-phase 🔴 tracks to ONE.** Five simultaneous reds means zero reds — everything is equally urgent, so nothing is.
3. **Add a `CURRENTLY_LEARNING.md` file** in repo root that names the *one* exploration in flight, with a deadline. The exploration map describes the *space*; this file describes the *cursor*.
4. **Link the existing artefacts** the map ignores: the 9 brainstorm files from today, `planning/ideas_to_explore.md`, the TOKEN_ECONOMY_TODO.md, and the planning roadmap stack. Otherwise the map looks like it claims to be first.
5. **Add a "stale by" date** to every topic. Default: 90 days. After that, the topic must be re-justified, demoted, or killed.

### High-leverage product concepts

6. **Reframe Classification History Schema as "the dataset, our moat."** It's currently filed as a data-engineering concern. In 18 months it's the asset competitors can't replicate. The framing change is the leverage — same code, different priority.
7. **Promote the Eval Harness to *the first artefact built*** before any other AI-stack research. Nothing else in the AI category is trustworthy until measurement exists. Treat it as a P0 build, not a P0 research topic.
8. **Make "what changes in the user's behaviour" a top-level category** — currently buried under Habit Formation Loop. Every other category is about making the *system* better. The product's reason to exist is behaviour change.

### LLM-backed / automation-heavy

9. **Auto-link discipline:** a CI check that fails if a new doc under `docs/exploration/` doesn't link back to EXPLORATION_TOPICS.md and update its status.
10. **Backlog-mining script:** scan `docs/planning/`, `docs/brainstorm_*`, `TOKEN_ECONOMY_TODO.md`, and grep TODOs in code → propose backlog additions weekly. Manual capture decays; automated capture survives.

### Whimsical / metaphors that clarify state

11. **Kitchen pantry metaphor.** Topics have expiry dates. Backlog is the shopping list. Frontier is the freezer (long-term). Active explorations are "in the fridge — use this week." Library card catalog (the current model) doesn't push action; pantry does.
12. **Recipe of the week.** One topic surfaced everywhere — in `APP_KNOWLEDGE_BASE.md`, in the README, in every brainstorm doc. The map should be ambient, not destination.
13. **Promotion ceremony.** When a topic moves from backlog → exploration → built artefact, the trail is visible (it's already in the promotion log). Make the log front-of-house, not bottom-of-file.

---

## 4. Views, Maps, Organizing Metaphors (Cartographer)

The current map is **flat**. The 8-category ASCII block tells you what exists but not what to do.

Replace with **two views**:

```diagram
╭──── PRIORITY VIEW ────╮           ╭─── DEPENDENCY VIEW ────╮
│                       │           │                        │
│  THIS WEEK   [1 topic]│           │  Eval Harness          │
│  THIS QUARTER [3]     │           │     │                  │
│  THIS YEAR   [6]      │           │     ▼                  │
│  FROZEN      [25]     │           │  Multi-Model Routing   │
│                       │           │     │                  │
│  STALE       [auto-   │           │     ▼                  │
│              flagged] │           │  On-Device Inference   │
╰───────────────────────╯           ╰────────────────────────╯
```

A reader should answer two questions in <10 seconds:

1. **What should I work on right now?** (priority view)
2. **What blocks what?** (dependency view)

Today neither view exists. The category view (AI / Data / UX / etc.) is good for browsing, useless for action.

---

## 5. Memory, Synthesis, Recovery (Archivist)

- **Cross-references missing.** Add an "Existing artefacts" section at the bottom of EXPLORATION_TOPICS.md that links every prior planning / brainstorm / roadmap file the map builds on. Without that, this map looks like Year Zero.
- **Recovery flow missing.** Six months from now, if the founder picks up a stale topic, how do they reconstruct context? Suggested: every exploration doc starts with `**Decision unblocked:**`, `**Evidence reviewed:**`, `**Open questions:**`, `**Last touched:**`. Mandate in the `exploration/README.md`.
- **Archive policy missing.** When does a `[KILLED]` topic move out of the active index into an archive? Suggested: a single `exploration/ARCHIVE.md` with the killed topic + one-line rationale + date. Keeps the trail; clears the surface.

---

## 6. Detection / Status / Intelligence (Operator)

The map has *status badges* (🔴/🟡/🟢) but no detection mechanism for status drift. Add:

- **A weekly review checklist** at the bottom of EXPLORATION_ROADMAP_WHILE_BUILDING.md. 5 minutes:
  1. Any 🔴 not moved in 14 days? Demote or escalate.
  2. Any topic past stale-by date? Re-justify or kill.
  3. Any new entries in `backlog.md` since last review? Promote ≤1.
  4. Any built artefact landed? Update topic status to [✓].
- **An "active research" line in CURRENTLY_LEARNING.md** that's updated weekly. If it's the same line for 3 weeks running, the research has stalled.

---

## 7. Champion's First-Principles Case (defending what was built)

Strongest honest case for the current map exactly as written:

- The travel_agency_agent precedent is real evidence, not aspirational copying. That project ships heavily *and* maintains this structure. Correlation isn't causation, but the structure isn't an obvious cause of paralysis.
- The waste app already has 600+ lines in `planning/ideas_to_explore.md` and 9 brainstorm files from today. The *absence* of categorisation is the failure mode currently in play — the map directly addresses it.
- Frontier bets with explicit kill criteria are genuinely rare and genuinely valuable. The Frontier doc earns its keep on its own.
- The NOW/NEXT/LATER phase mapping has *de-risk questions*, not feature lists. That distinction (research vs build) doesn't exist in any other doc in this repo.
- "Solo project, too much overhead" cuts both ways: a solo founder *especially* needs a single index of unknowns, because there's nobody else holding the context.

**What would make the Champion's view right even if unconventional:** the map is correct *because* it's bigger than the project needs right now — it captures the conceptual surface area the founder is already thinking about across token economy, classification quality, smart bins, B2B. Compression to 10 topics would re-create the "everything is in my head" problem the map exists to solve.

---

## 8. Kill Test Verdict (Executioner)

**Strongest kill case:** *The exploration map is procrastination dressed as rigor.*

Evidence the Executioner brought:

- Repo already has: 5 roadmap files, 1 ideas file, 9 brainstorm files from today alone, a TOKEN_ECONOMY_TODO.md, a TODO/ folder, multiple raw todos files (`code_todos_grep_results.txt`, `todos_consolidated_raw_2025-06-14.txt`).
- Adding 5 more doc files to that pile is *negative-yield work* unless something gets *deleted*.
- The user's actual unblocked work is on token economy (active today). The exploration map talks about everything *except* what the user is actually working on. (Token economy isn't even a topic in the master index.)
- "Living document" is the most-broken promise in this repo. Most planning docs haven't been touched in months. Adding more of them makes the dead-doc ratio worse, not better.

**Did the map survive the kill test?** *Partially.* It survives as a concept; it does not survive at the current scale.

Specifically:

- ✓ The *separation* (research vs planning) survives — that distinction adds real value.
- ✓ Frontier doc with kill criteria survives — unique and lightweight.
- ✗ 35 topics across 8 categories does **not** survive solo-project economics. Cut hard.
- ✗ 5 simultaneous NOW-phase 🔴 tracks does **not** survive — pick one.
- ✗ The map is **disqualified** until it (a) links to the existing artefacts it ignores, and (b) adds the cross-link to the token economy work in flight today.

---

## 9. Champion vs Executioner Arbitration

| Disagreement | Champion says | Executioner says | Resolution |
|---|---|---|---|
| Scale | 35 topics matches the conceptual surface area in the founder's head | 35 topics in a solo project is doc-cosplay | **Cut to 10 active + 25 in backlog.** Keep the surface area, lower the maintenance cost. |
| Doc proliferation | Net-new value (research layer doesn't exist) | Net-negative (worse dead-doc ratio) | **Net-new only if 80% of existing planning docs get archived or merged in parallel.** |
| Living-document risk | This one will be different because it has lifecycle | Every planning doc said that | **Add a 30-day forcing function**: if no exploration doc is written in 30 days, this whole structure is marked failed. |
| Founder feeling | A categorised map relieves "everything in my head" | A 35-item map adds "everything I'm not doing" | **Both true. Resolved by Priority View** (§4) that greys out 25 frozen topics. |

---

## 10. Build Conditions (Blue Hat, next actions)

**Proceed with the exploration map** if and only if:

- [ ] **C1.** Within 7 days, EXPLORATION_TOPICS.md is cut to ≤10 active topics; rest moved to `exploration/backlog.md`.
- [ ] **C2.** Within 7 days, NOW-phase 🔴 tracks reduced to **1**. Others moved to NEXT or demoted to 🟡.
- [ ] **C3.** Within 7 days, the map links the existing artefacts it currently ignores:
  - `planning/ideas_to_explore.md`
  - The 9 `brainstorm_*_2026-05-19.md` token economy files
  - `TOKEN_ECONOMY_TODO.md`
  - `planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md`
- [ ] **C4.** Add a top-level topic for **Token Economy** (currently the active work) — the map can't credibly omit what the founder is actually doing today.
- [ ] **C5.** Within 14 days, write the **first** real exploration doc — `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` or `docs/exploration/EVAL_HARNESS_AND_GOLDEN_SETS.md`. If neither lands in 14 days, the whole structure is marked failed and reverted.
- [ ] **C6.** Within 30 days, demonstrate at least one **promotion** (backlog → exploration doc) and one **kill** (topic marked `[KILLED]`). The lifecycle has to actually circulate.

**Pause** if C1–C4 aren't met in 7 days — the map is becoming what it tried to prevent.

**Kill** if C5 fails — confirmation that the doc structure isn't unblocking real research.

---

## 11. Six-Hat Coverage

- **White (facts):** 35 topics defined; no eval harness exists; 5 🔴 tracks in NOW; solo maintainer; 5+ existing roadmap docs; 9 brainstorm files from today on token economy; 600+ line existing ideation file. The map currently links none of these.
- **Yellow (value):** clear separation of research from build; frontier doc with kill criteria; first explicit dependency on de-risk questions rather than feature lists; mirrors a working pattern from travel_agency_agent.
- **Black (risks):** doc-bloat; maintenance overhead; 35 reds collapse into 0 reds; founder despair on opening; another dead "living document"; map ignores active token-economy work.
- **Green (creative):** kitchen-pantry metaphor with expiry dates; recipe-of-the-week ambient surfacing; CURRENTLY_LEARNING.md as the cursor; auto-link CI check; backlog-mining script.
- **Red (taste):** the map feels comprehensive **and** overwhelming in the same breath. It reads like homework, not invitation. Greying out frozen topics restores energy.
- **Blue (next action):** apply C1–C6 above. Single most leveraged move: **shrink to 10 + add Token Economy + write the first real exploration doc within 14 days.**

---

## 12. Convergence — Where Roles Independently Agreed

Strong signal when multiple roles landed on the same point without prompting:

| Convergence | Roles that agreed |
|---|---|
| **35 topics is too many; cut to ≤10 active** | Skeptic, Executioner, Cartographer, Customer Whisperer |
| **Map must link existing artefacts (brainstorms, ideas_to_explore.md, token economy)** | Archivist, Executioner, Operator |
| **Need a "what I'm learning right now" cursor file, not just the space-map** | Operator, Cartographer, Trickster, Customer Whisperer |
| **Eval Harness is the first artefact to build, not just research** | Strategist, Future Self, Operator |
| **Topics need stale-by dates / forcing functions** | Trickster, Skeptic, Operator, Archivist |
| **Data flywheel / classification history is currently mis-framed as cost, should be moat** | Future Self, Strategist |

Six-way convergence on "cut and shrink" is the loudest signal in the room.

---

## 13. Time-Horizon Leapfrog Pass

**6 months:** map is shrunk to 10 active topics; 3 exploration docs written; eval harness exists in code; cost guardrails live; one topic killed publicly. The map is *used*, not just maintained.

**12 months:** the labelled waste dataset is recognised as the asset it is; on-device tier in field testing; first municipal/RWA pilot live; the exploration map is the way the team (now > 1?) onboards new contributors.

**24 months:** the structure has been reorganised twice in response to what the project actually learned. The original 8 categories are no longer the right cut — the real categories turned out to be (e.g.) "behaviour change," "verified disposal," "rules corpus," "edge cost." That reorganisation is healthy and expected.

**Leapfrog move:** treat the exploration map as a **first-class product feature** for contributors and external collaborators — publish it. A public "what we don't yet know" page becomes a recruiting tool, a partner conversation starter, and a forcing function that no internal map ever achieves. Most projects hide their unknowns; making them visible is unusual and disarming.

---

## 14. What to Build First vs. What to Dream About

**Build this week:**
- Apply C1 (cut to 10), C2 (single NOW red), C3 (link artefacts), C4 (add Token Economy topic).

**Build within 14 days:**
- C5 — first real exploration doc (Eval Harness OR Cost Telemetry).

**Build within 30 days:**
- CURRENTLY_LEARNING.md cursor file.
- Priority View + Dependency View (§4).
- Archive policy + `exploration/ARCHIVE.md`.
- Weekly review checklist.

**Dream about (not now):**
- Publishing the exploration map publicly as a recruiting / partnership tool.
- Auto-link CI check.
- Backlog-mining script that crawls `docs/planning/` and the `brainstorm_*` files.

---

## 15. Reformulated Reusable Prompt

> Pressure-test a research/exploration map for a software project that already has substantial existing planning documentation. Apply the wide-open-brainstorm role panel — Strategist, Champion, Operator, Cartographer, Archivist, Trickster, Skeptic, Future Self, Outsider, Customer Whisperer, Executioner — across three altitudes (10k / 1k / ground). Run an explicit Champion-vs-Executioner arbitration to convert disagreement into build conditions (proceed / prototype / pause / kill). Ensure six-hat coverage. Surface convergence across roles as the strongest signal. Output: build conditions with deadlines and kill triggers, not just commentary.

---

## 16. Follow-up Planning Prompt

> Using the build conditions C1–C6 from `docs/brainstorm_exploration_map_2026-05-19.md`, modify EXPLORATION_TOPICS.md, EXPLORATION_FRONTIER.md, EXPLORATION_ROADMAP_WHILE_BUILDING.md, and exploration/backlog.md so that:
> 1. ≤10 topics remain in active categories; rest move to backlog with a `(moved from index 2026-05-19)` tag.
> 2. NOW phase has exactly one 🔴 track (recommend AI Cost Telemetry OR Eval Harness).
> 3. A new top-level topic "Token Economy & Pricing Coherence" is added, linking to the 9 brainstorm files from 2026-05-19 and TOKEN_ECONOMY_TODO.md.
> 4. A new top-of-file "Existing artefacts this builds on" section links: planning/ideas_to_explore.md, planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md, planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md, TOKEN_ECONOMY_TODO.md, and the brainstorm_*_2026-05-19.md set.
> 5. Repo-root CURRENTLY_LEARNING.md is created with one active research thread.
> 6. Then write the first real exploration doc (cost telemetry OR eval harness), within 14 days, or revert the entire structure.
