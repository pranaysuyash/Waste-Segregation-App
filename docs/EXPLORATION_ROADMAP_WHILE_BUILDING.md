# Exploration Roadmap While Building — Waste Segregation App

**Purpose**: What to investigate *in parallel* with shipping. Maps exploration topics to the build phases they should de-risk before — or alongside — implementation.
**Status**: Living
**Last Updated**: 2026-05-19
**Parent**: [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md)
**Sibling**: [EXPLORATION_FRONTIER.md](EXPLORATION_FRONTIER.md)

---

## How to read this doc

The app is being built in shipping waves. Exploration is not a separate quarter — it runs **in parallel** with the build. This document maps:

- **Build phase** (what's being shipped now / next)
- **Exploration topics that must move forward in lockstep** (from [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md))
- **De-risk question** the exploration must answer before / during the phase
- **Output artefact** that closes the loop

Sources for the build phases:

- [docs/planning/INTEGRATED_DEVELOPMENT_ROADMAP.md](planning/INTEGRATED_DEVELOPMENT_ROADMAP.md)
- [docs/planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md](planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md)
- [docs/planning/unified_project_roadmap.md](planning/unified_project_roadmap.md)
- [TOKEN_ECONOMY_TODO.md](../TOKEN_ECONOMY_TODO.md)

If those move, this map moves with them.

---

## Phase Map

```diagram
╭──────────────────────────╮   ╭──────────────────────────╮   ╭──────────────────────────╮
│ NOW                      │   │ NEXT                     │   │ LATER                    │
│ Stabilise + Cost + Trust │──▶│ Quality + Engagement     │──▶│ Scale + Frontier         │
╰────────────┬─────────────╯   ╰────────────┬─────────────╯   ╰────────────┬─────────────╯
             │                              │                              │
             ▼                              ▼                              ▼
  ╭──────────────────────╮       ╭──────────────────────╮       ╭──────────────────────╮
  │ Cost guardrails      │       │ Eval harness live    │       │ On-device tier ships │
  │ Offline queue ✓      │       │ Region rulesets v1   │       │ Smart-bin QR layer   │
  │ PII / retention v1   │       │ Habit loop v2        │       │ Reuse marketplace v0 │
  │ Onboarding revamp    │       │ Gamification rework  │       │ B2B / school pilot   │
  ╰──────────────────────╯       ╰──────────────────────╯       ╰──────────────────────╯
```

---

## PHASE: NOW — Stabilise, Cost, Trust

Goal: the app is reliably classifying, costs are observable and bounded, and trust foundations (offline, privacy, onboarding) are in place. Nothing shippable from later phases should be funded until these are credible.

### Track N1 — AI Cost & Reliability

- **Topic**: [AI Cost Telemetry & Guardrails (🔴)](EXPLORATION_TOPICS.md#10-ai-cost-telemetry--guardrails-)
- **De-risk question**: For an active user, what does a worst-case month cost us, and which provider/feature drives it?
- **Output**: `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` + a dashboard derived from `ai_cost_tracker.dart` / `cost_guardrail_service.dart`.
- **Built artefact this enables**: per-tier soft / hard caps, automatic provider downgrade, free-tier fair-use enforcement.

### Track N2 — Offline Queue & Sync Contract

- **Topic**: [Offline Queue & Sync (🔴)](EXPLORATION_TOPICS.md#11-offline-queue--sync-)
- **De-risk question**: What is our exact contract when a classification is captured offline, corrected later, or replayed on another device?
- **Output**: `docs/exploration/OFFLINE_QUEUE_AND_SYNC.md` (decision doc, not just description) + acceptance tests against the existing queue.
- **Built artefact this enables**: shipping offline as a first-class promise rather than a "best-effort" hidden feature.

### Track N3 — Privacy / Photo PII

- **Topic**: [Privacy / Photo PII (🔴)](EXPLORATION_TOPICS.md#32-privacy--photo-pii-) + [Data Retention & PII Strategy (🔴)](EXPLORATION_TOPICS.md#14-data-retention--pii-strategy-)
- **De-risk question**: Are we one bad photo away from a serious incident? What's the smallest set of controls that closes that gap?
- **Output**: `docs/exploration/PRIVACY_PHOTO_PII.md` + `docs/exploration/DATA_RETENTION_AND_PII_STRATEGY.md`, both reviewed against `docs/legal/` and `docs/security/`.
- **Built artefact this enables**: an explicit, documented baseline that all future monetisation, B2B, and partner conversations can stand on.

### Track N4 — Onboarding & Activation

- **Topic**: [Onboarding & Activation (🔴)](EXPLORATION_TOPICS.md#19-onboarding--activation-)
- **De-risk question**: What is our time-to-first-successful-scan today, and where does the funnel leak?
- **Output**: `docs/exploration/ONBOARDING_AND_ACTIVATION.md` with funnel measurement + a prioritised remediation list.
- **Built artefact this enables**: any growth / acquisition spend; without this, install $$ leaks immediately.

### Track N5 — Moderation & Safety baseline

- **Topic**: [Moderation & Safety (🔴)](EXPLORATION_TOPICS.md#23-moderation--safety-)
- **De-risk question**: Can a single bad actor or single bad photo currently take the community feed sideways? What's the minimum safety net before any social growth investment?
- **Output**: `docs/exploration/MODERATION_AND_SAFETY.md` with a tiered escalation policy.

---

## PHASE: NEXT — Quality, Engagement, Region Depth

Goal: the AI is measurably improving, the experience is sticky beyond novelty, and the "what to do with this waste" advice is correct for the user's location.

### Track X1 — Eval Harness & Golden Sets

- **Topic**: [Eval Harness & Golden Sets (🔴)](EXPLORATION_TOPICS.md#5-eval-harness--golden-sets-)
- **De-risk question**: Before we swap providers, change prompts, or add an on-device tier, how do we know we made things better and not worse?
- **Output**: `docs/exploration/EVAL_HARNESS_AND_GOLDEN_SETS.md` + a labelled golden set checked into the repo (with PII review).
- **Built artefact this enables**: trustworthy iteration on the AI stack.

### Track X2 — Multi-Model Routing + Disposal Reasoning Stage

- **Topics**: [Multi-Model AI Routing (🔴)](EXPLORATION_TOPICS.md#1-multi-model-ai-routing--seed), [Disposal Reasoning Stage (🟡)](EXPLORATION_TOPICS.md#3-disposal-reasoning-stage-), [Classification Confidence (🟡)](EXPLORATION_TOPICS.md#2-classification-confidence--uncertainty-)
- **De-risk question**: Should "what is this?" and "what do I do with it?" be one model call or two? How do we route?
- **Output**: `docs/exploration/MULTI_MODEL_AI_ROUTING.md` + `docs/exploration/DISPOSAL_REASONING_STAGE.md`.
- **Built artefact this enables**: cheaper, faster, and more correct classifications; a path to on-device for the common case.

### Track X3 — Region-Aware Rulesets

- **Topic**: [Region-Aware Rulesets (🔴)](EXPLORATION_TOPICS.md#4-region-aware-rulesets-)
- **De-risk question**: Can we design a ruleset schema and seed at least one credible city (Bangalore) without it collapsing under maintenance?
- **Output**: `docs/exploration/REGION_AWARE_RULESETS.md` + a seed YAML/JSON for one city.
- **Built artefact this enables**: localised disposal advice that's defensible.

### Track X4 — Gamification Rework + Habit Loop

- **Topics**: [Gamification Depth (🟡)](EXPLORATION_TOPICS.md#16-gamification-depth-), [Habit Formation Loop (🟡)](EXPLORATION_TOPICS.md#17-habit-formation-loop-)
- **De-risk question**: Is current gamification rewarding the *right* behaviour or just any behaviour? Where's the week-3 retention cliff?
- **Output**: `docs/exploration/GAMIFICATION_DEPTH.md` + `docs/exploration/HABIT_FORMATION_LOOP.md`.
- **Built artefact this enables**: a v2 gamification system tied to disposal correctness, not scan volume.

### Track X5 — Firestore Cost & History Schema

- **Topics**: [Firestore Cost & Indexing (🟡)](EXPLORATION_TOPICS.md#13-firestore-cost--indexing-), [Classification History Schema (🟡)](EXPLORATION_TOPICS.md#12-classification-history-schema-)
- **De-risk question**: What's our per-MAU cost on Firestore today, and what's the schema we want to lock in before growth makes migrations painful?
- **Output**: `docs/exploration/FIRESTORE_COST_AND_INDEXING.md` + `docs/exploration/CLASSIFICATION_HISTORY_SCHEMA.md`.

---

## PHASE: LATER — Scale, Frontier, B2B

Goal: the product extends beyond the individual user — to bins, schools, cities, brands — and the on-device tier carries the cost story.

### Track L1 — On-Device Inference Tier

- **Topics**: [On-Device Inference (🔴)](EXPLORATION_TOPICS.md#6-on-device-inference-), [Battery / Thermal (🟢)](EXPLORATION_TOPICS.md#8-battery-thermal--memory-budget-), [Model Cascades (🟡)](EXPLORATION_TOPICS.md#7-model-cascades-)
- **De-risk question**: Can a Flutter-shippable local model handle the common case within battery and quality budget?
- **Output**: `docs/exploration/ON_DEVICE_INFERENCE.md` + `docs/exploration/DEVICE_BUDGET.md`.
- **Frontier dependency**: [F1. Fully On-Device Multi-Model Stack](EXPLORATION_FRONTIER.md#f1-fully-on-device-multi-model-stack).

### Track L2 — Smart-Bin / QR-Bin Layer

- **Topics**: [Smart-Bin Integration (🟢)](EXPLORATION_TOPICS.md#24-smart-bin-integration--frontier), [Municipal APIs (🟡)](EXPLORATION_TOPICS.md#25-municipal-apis-bbmp-etc-)
- **De-risk question**: Can the cheapest possible "smart bin" (a QR code) earn its keep with one RWA or school?
- **Output**: `docs/exploration/SMART_BIN_INTEGRATION.md` + pilot summary.
- **Frontier dependency**: [F5. Smart-Bin / QR-Bin Aggregation Layer](EXPLORATION_FRONTIER.md#f5-smart-bin--qr-bin-aggregation-layer).

### Track L3 — B2B / School Wedge

- **Topics**: [B2B / Enterprise Wedge (🟢)](EXPLORATION_TOPICS.md#29-b2b--enterprise-wedge-), [Persona Journeys (🟡)](EXPLORATION_TOPICS.md#15-persona-journeys-), [Carbon / Impact Accounting (🟡)](EXPLORATION_TOPICS.md#30-carbon--impact-accounting-)
- **De-risk question**: Which segment (school, RWA, corporate) is the cleanest first wedge, and what's the smallest admin surface that earns the deal?
- **Output**: `docs/exploration/B2B_ENTERPRISE_WEDGE.md` + a pilot proposal.
- **Frontier dependency**: [F10. Education-First White-Label for Schools](EXPLORATION_FRONTIER.md#f10-education-first-white-label-for-schools).

### Track L4 — Continuous Learning Loop

- **Topics**: feedback loop between Eval Harness, History Schema, and Classification Confidence.
- **De-risk question**: Can user corrections be turned into a defensible, ethical, weekly improvement cycle?
- **Frontier dependency**: [F3. Continuous Learning Loop from User Corrections](EXPLORATION_FRONTIER.md#f3-continuous-learning-loop-from-user-corrections).

### Track L5 — Local Reuse Marketplace (pilot only)

- **Topic**: [Local Reuse Marketplace (🟢)](EXPLORATION_TOPICS.md#22-local-reuse-marketplace-)
- **De-risk question**: Does the reuse surface complement or compete with the core classify loop?
- **Frontier dependency**: [F4. Neighbourhood Reuse Marketplace](EXPLORATION_FRONTIER.md#f4-neighbourhood-reuse-marketplace).

---

## Cross-Cutting Discipline

These exploration practices apply regardless of phase. Treat them as guardrails.

1. **No model / prompt / routing change without a golden-set evaluation result attached.**
2. **No new data-collection surface without the privacy / retention answer in the same PR.**
3. **No "agent / AI" feature ships without a documented autonomy contract (suggest / confirm / act / silent).** Inherits from the project's broader [Agent Quality Standards](../../../AGENT_QUALITY_STANDARDS.md).
4. **Every exploration doc must declare**:
   - The decision it unblocks.
   - The kill criteria that would let us drop it.
   - The downstream artefact / code change it points to.
5. **Promote / kill — don't let docs drift.** When an exploration completes, update [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md) status and either link to the built artefact or mark `[KILLED]` with a one-line reason.

---

## Status Snapshot (2026-05-19)

| Phase | Track | Topic | Status |
|------:|------|-------|--------|
| NOW | N1 | AI Cost & Guardrails | 🔴 Seeded — no exploration doc yet |
| NOW | N2 | Offline Queue Contract | 🔴 Code exists, contract under-specified |
| NOW | N3 | Privacy / Photo PII + Retention | 🔴 Partial coverage in `docs/security/`, `docs/legal/` |
| NOW | N4 | Onboarding Activation | 🔴 Not instrumented |
| NOW | N5 | Moderation Baseline | 🔴 Not formalised |
| NEXT | X1 | Eval Harness | 🔴 Missing as first-class artefact |
| NEXT | X2 | Multi-Model Routing + Disposal | 🟡 Seeded |
| NEXT | X3 | Region-Aware Rulesets | 🔴 Implicit in prompts today |
| NEXT | X4 | Gamification + Habit Loop | 🟡 v1 lives in code; needs critical rework |
| NEXT | X5 | Firestore + History Schema | 🟡 Implicit |
| LATER | L1 | On-Device Inference | 🔴 (frontier-paced) |
| LATER | L2 | Smart-Bin / QR Layer | 🟢 |
| LATER | L3 | B2B / School Wedge | 🟢 |
| LATER | L4 | Continuous Learning Loop | 🟢 |
| LATER | L5 | Reuse Marketplace | 🟢 |

Update this snapshot whenever a topic's status changes in [EXPLORATION_TOPICS.md](EXPLORATION_TOPICS.md).
