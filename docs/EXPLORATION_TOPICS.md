# Exploration Topics — Master Index

**Purpose**: Living document tracking research areas for the Waste Segregation App
**Status**: Active — continuously updated as the project evolves
**Last Updated**: 2026-05-20
**Sibling docs**:
- [EXPLORATION_FRONTIER.md](EXPLORATION_FRONTIER.md) — high-ambition / "boil the ocean" frontier bets
- [EXPLORATION_ROADMAP_WHILE_BUILDING.md](EXPLORATION_ROADMAP_WHILE_BUILDING.md) — what to explore in parallel with shipping
- [exploration/](exploration/) — per-topic detailed exploration docs
- [exploration/backlog.md](exploration/backlog.md) — raw, append-only idea backlog
- [exploration/ARCHIVE.md](exploration/ARCHIVE.md) — `[KILLED]` and `[✓]` topics moved out of the active index
- [brainstorm_exploration_map_2026-05-19.md](brainstorm_exploration_map_2026-05-19.md) — wide-open-brainstorm pressure test of this map

---

## Existing Artefacts This Map Builds On

This index is **not Year Zero**. It augments and indexes (does not replace) a substantial body of prior ideation and planning. Anyone working with this map should treat the following as primary source material:

**Planning / roadmap stack** (what we plan to build):
- [planning/ideas_to_explore.md](planning/ideas_to_explore.md) — long-running ideation capture (Technical / UX / Business)
- [planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md](planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md) — strategic feature vision
- [planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md](planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md)
- [planning/INTEGRATED_DEVELOPMENT_ROADMAP.md](planning/INTEGRATED_DEVELOPMENT_ROADMAP.md)
- [planning/unified_project_roadmap.md](planning/roadmap/unified_project_roadmap.md)
- [planning/REMAINING_ROADMAP_ITEMS.md](planning/REMAINING_ROADMAP_ITEMS.md)
- [planning/roadmap/innovative_features_roadmap.md](planning/roadmap/innovative_features_roadmap.md)
- [planning/roadmap/DISPOSAL_INSTRUCTIONS_ROADMAP.md](planning/roadmap/DISPOSAL_INSTRUCTIONS_ROADMAP.md)
- [design/UI_ROADMAP_COMPREHENSIVE.md](design/UI_ROADMAP_COMPREHENSIVE.md)

**Active work in flight (2026-05-19)**:
- [../TOKEN_ECONOMY_TODO.md](../TOKEN_ECONOMY_TODO.md) — active token economy execution list
- [brainstorm_strategist_2026-05-19.md](brainstorm_strategist_2026-05-19.md)
- [brainstorm_champion_2026-05-19.md](brainstorm_champion_2026-05-19.md)
- [brainstorm_operator_2026-05-19.md](brainstorm_operator_2026-05-19.md)
- [brainstorm_cartographer_2026-05-19.md](brainstorm_cartographer_2026-05-19.md)
- [brainstorm_skeptic_2026-05-19.md](brainstorm_skeptic_2026-05-19.md)
- [brainstorm_trickster_2026-05-19.md](brainstorm_trickster_2026-05-19.md)
- [brainstorm_executioner_2026-05-19.md](brainstorm_executioner_2026-05-19.md)
- [brainstorm_future_self_2026-05-19.md](brainstorm_future_self_2026-05-19.md)
- [brainstorm_synthesis_2026-05-19.md](brainstorm_synthesis_2026-05-19.md)
- [ai_service_refactor_motto_v2_2026-05-19.md](ai_service_refactor_motto_v2_2026-05-19.md)

**TODO / engineering surface**:
- [TODO/](TODO/), [code_todos_grep_results.txt](code_todos_grep_results.txt), [todo_grep_results.txt](todo_grep_results.txt)

If you see drift between this index and any of the above, **the source artefact wins**. Update this index, don't fork it.

---

## How to Use This Document

**This is the master index**. It provides:

- A categorized map of every active exploration area
- Why each area matters for the Waste Segregation App specifically
- Current status and owner (where known)
- Links to detailed research docs under `docs/exploration/`

**For deep research**, each topic should have (or grow) its own document under `docs/exploration/`:

- `docs/exploration/MULTI_MODEL_AI_ROUTING.md`
- `docs/exploration/ON_DEVICE_INFERENCE.md`
- `docs/exploration/SMART_BIN_INTEGRATION.md`
- etc.

**To add new topics**:

1. Append a rough capture to [exploration/backlog.md](exploration/backlog.md).
2. When a topic is mature enough to act on, promote it: add an entry to this index, create the detailed doc under `docs/exploration/`, and link both directions.
3. If a topic is killed, mark it `[KILLED]` with a one-line rationale — preserve the trail.

**Precedence with existing planning docs**:

- This index is the **research/exploration** layer. It does not replace:
  - `docs/planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md` — strategic feature roadmap
  - `docs/planning/unified_project_roadmap.md` / `docs/planning/INTEGRATED_DEVELOPMENT_ROADMAP.md` — execution roadmaps
  - `docs/planning/ideas_to_explore.md` — long-running brainstorm capture
- Treat planning docs as **what we plan to build**, and this index as **what we still need to learn to build it well**.

---

## Topic Categories

```
╭───────────────────────────────────────────────────────────────────────────────╮
│                EXPLORATION TOPICS MASTER MAP — WASTE SEG APP                  │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  AI & VISION                                  ON-DEVICE & EDGE                │
│  ├── Multi-Model AI Routing       [🔴]        ├── On-Device Inference   [🔴] │
│  ├── Classification Confidence    [🟡]        ├── Model Cascades        [🟡] │
│  ├── Disposal Reasoning Stage     [🟡]        ├── Battery / Thermal     [🟢] │
│  ├── Region-Aware Rulesets        [🔴]        └── Offline-First Flow    [🟡] │
│  └── Eval Harness & Golden Sets   [🔴]                                       │
│                                                                               │
│  DATA, COST & RELIABILITY                     USER EXPERIENCE & ENGAGEMENT    │
│  ├── AI Cost Telemetry & Guardrails [🔴]      ├── Persona Journeys      [🟡] │
│  ├── Offline Queue & Sync           [🔴]      ├── Gamification Depth    [🟡] │
│  ├── Classification History Schema  [🟡]      ├── Habit Formation Loop  [🟡] │
│  ├── Firestore Cost & Indexing      [🟡]      ├── Accessibility & I18n  [🟡] │
│  └── Data Retention & PII Strategy  [🔴]      └── Onboarding Activation [🔴] │
│                                                                               │
│  COMMUNITY & SOCIAL                           IoT, SMART CITY & PARTNERS      │
│  ├── Community Feed Trust Layer   [🟡]        ├── Smart-Bin Integration [🟢] │
│  ├── Family / Group Mechanics     [🟡]        ├── Municipal APIs (Global) [🟡] │
│  ├── Local Reuse Marketplace      [🟢]        ├── Collector Network     [🟢] │
│  └── Moderation & Safety          [🔴]        └── Hardware Partners     [🟢] │
│                                                                               │
│  BUSINESS & GROWTH                            COMPLIANCE & TRUST              │
│  ├── Token Economy & Pricing      [🔴]        ├── Privacy / Photo PII   [🔴] │
│  ├── Monetization & Pricing Tiers [🟡]        ├── Regional Regulations  [🟡] │
│  ├── B2B / Enterprise Wedge       [🟢]        ├── Content Provenance    [🟢] │
│  ├── Carbon / Impact Accounting   [🟡]        └── Audit / Telemetry     [🟡] │
│  └── Distribution & Partnerships  [🟢]                                       │
│                                                                               │
│  PIPELINE EVOLUTION                                                           │
│  ├── Capture → Classify → Educate → Dispose → Reward loop                    │
│  ├── Continuous Learning from User Corrections                                │
│  └── Active Learning & Hard-Example Mining                                    │
│                                                                               │
╰───────────────────────────────────────────────────────────────────────────────╯

Legend:
[🔴] = High priority — blocks next phase or de-risks core promise
[🟡] = Medium priority — enables scale / quality / retention
[🟢] = Low priority — frontier bet, not yet load-bearing
[ ]  = Not started     [✓] = Completed     [KILLED] = Dropped with rationale
```

---

## Dependency View — What Blocks What

The category map above is for **browsing**. This view is for **sequencing**. Don't open a downstream exploration before its upstream is at least sketched.

```diagram
                       ╭──────────────────────────╮
                       │  Eval Harness &          │
                       │  Golden Sets        [🔴] │  ← upstream of all AI work
                       ╰────────────┬─────────────╯
                                    │
            ╭───────────────────────┼────────────────────────╮
            ▼                       ▼                        ▼
  ╭──────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
  │ Classification   │   │ Multi-Model AI       │   │ Disposal Reasoning   │
  │ Confidence  [🟡] │   │ Routing         [🔴] │   │ Stage           [🟡] │
  ╰────────┬─────────╯   ╰──────────┬───────────╯   ╰──────────┬───────────╯
           │                        │                          │
           │                        ▼                          ▼
           │            ╭──────────────────────╮   ╭──────────────────────╮
           │            │ On-Device Inference  │   │ Region-Aware         │
           │            │ + Model Cascades[🔴] │   │ Rulesets        [🔴] │
           │            ╰──────────┬───────────╯   ╰──────────┬───────────╯
           │                       │                          │
           └───────────────────────┼──────────────────────────┤
                                   ▼                          ▼
                       ╭──────────────────────────────────────────────╮
                       │  AI Cost Telemetry & Guardrails        [🔴] │
                       │  (informed by all of the above)              │
                       ╰──────────────────────────────────────────────╯

  ╭──────────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
  │ Classification       │──▶│ Continuous Learning  │──▶│ Active Learning &   │
  │ History Schema  [🟡] │   │ Loop (F3)            │   │ Hard-Example Mining │
  │ (the dataset = moat) │   │                      │   │                      │
  ╰──────────────────────╯   ╰──────────────────────╯   ╰──────────────────────╯

  ╭──────────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
  │ Privacy / Photo PII  │──▶│ Data Retention & PII │──▶│ Regional Regulations │
  │ [🔴]                 │   │ Strategy        [🔴] │   │                 [🟡] │
  ╰──────────────────────╯   ╰──────────────────────╯   ╰──────────────────────╯

  ╭──────────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
  │ Token Economy &      │──▶│ Monetization &       │──▶│ AI Cost Telemetry    │
  │ Pricing Coherence    │   │ Pricing Tiers   [🟡] │   │ & Guardrails    [🔴] │
  │ [🔴] (in flight)     │   │                      │   │                      │
  ╰──────────────────────╯   ╰──────────────────────╯   ╰──────────────────────╯

  ╭──────────────────────╮   ╭──────────────────────╮   ╭──────────────────────╮
  │ Smart-Bin QR Layer   │──▶│ Municipal APIs       │──▶│ Carbon / Impact      │
  │ (F5)            [🟢] │   │ (BBMP, etc.)    [🟡] │   │ Accounting      [🟡] │
  ╰──────────────────────╯   ╰──────────────────────╯   ╰──────────────────────╯
```

Reading rules:

- Arrows mean **research dependency**, not strict implementation order. You can sketch downstream while upstream is open, but don't *decide* downstream until upstream has an answer.
- **Eval Harness** is the single most leveraged upstream — without it, no AI-stack change can be trusted. Treat as P0.
- **Classification History Schema** sits in the centre of the data-flywheel chain — see entry 12 for the reframing.

---

## AI & VISION

### 1. Multi-Model AI Routing 🔴 [SEED]

**Status**: High priority — partially captured in [planning/ideas_to_explore.md](planning/ideas_to_explore.md). Needs a real exploration doc.

**Overview**: Today the app routes most classification through a single AI service (`lib/services/ai_service.dart`, `enhanced_ai_api_service.dart`). The product reality is a **stack** of tasks: detection, segmentation, classification, disposal reasoning, locality lookup. Each has different latency, cost, and accuracy trade-offs.

**Key questions**:

- Which tasks belong on-device vs cloud-first?
- Should disposal guidance be a separate reasoning stage from vision classification?
- What confidence thresholds trigger fallback (local → cloud, small → large model)?
- How do we route per-image based on apparent complexity (single object vs cluttered scene)?
- How do we keep latency low for the common case while still handling edge cases well?

**Research areas**:

- Candidate on-device VLMs (Gemma 3n, MiniCPM-V, SmolVLM, MobileSAM, Apple Vision)
- Cloud fallback ladder (Gemini Flash → Pro → multi-model arbitration)
- Task-specialised models vs single multi-task model
- Cost-per-classification telemetry already in `ai_cost_tracker.dart`

**Deliverable**: `docs/exploration/MULTI_MODEL_AI_ROUTING.md` covering candidate stack, routing rules, eval methodology, cost model.

**Related**: On-Device Inference, AI Cost Telemetry, Eval Harness.

---

### 2. Classification Confidence & Uncertainty 🟡

**Status**: Seed — current code surfaces a confidence score but does not formally model uncertainty.

**Overview**: The user needs to know "the app is unsure — please confirm" vs "this is plastic, here's how to dispose". Today there's no calibrated uncertainty layer or explicit "ambiguous" state.

**Key questions**:

- What confidence calibration applies across providers (Gemini, OpenAI, on-device)?
- When should we ask the user a clarifying question vs answer outright?
- How do uncertainty signals feed back into the gamification / education loop?
- How do we distinguish "model unsure" from "image bad" (motion blur, framing)?

**Deliverable**: `docs/exploration/CLASSIFICATION_CONFIDENCE.md` defining the uncertainty contract, UI states, and feedback flow.

**Related**: Multi-Model AI Routing, Onboarding Activation, Eval Harness.

---

### 3. Disposal Reasoning Stage 🟡

**Status**: Implicit today — classification and disposal advice are coupled in prompts and `disposal_instructions_service.dart`.

**Overview**: Disposal correctness is **regionally specific**. The same plastic film is recyclable in one city and not another. Mixing classification (visual) with disposal (policy) makes both harder to evaluate, version, and localise.

**Key questions**:

- Should disposal advice be a separate, evidence-grounded reasoning step (RAG over a regional rules corpus)?
- Where does the rules corpus live, and who maintains it?
- How do we version "what we told the user" so we can revisit if rules change?
- How does this interact with the planned smart-bin / municipal integration?

**Deliverable**: `docs/exploration/DISPOSAL_REASONING_STAGE.md`.

**Related**: Region-Aware Rulesets, Smart-Bin Integration, Audit / Telemetry.

---

### 4. Region-Aware Rulesets 🔴

**Status**: Largely hard-coded / prompt-resident today.

**Overview**: India-first (BBMP), with global ambitions. The "right answer" depends on city/municipality/building rules. The app has no first-class concept of a region-aware ruleset.

**Key questions**:

- Schema for a ruleset: jurisdiction, material taxonomy, bin colours, exceptions, sources.
- Sourcing strategy: curated, crowdsourced, scraped, partner-supplied?
- Trust model: how do we mark a ruleset as "verified vs community-submitted"?
- Update cadence and override path when local reality differs from official rules.

**Deliverable**: `docs/exploration/REGION_AWARE_RULESETS.md`.

**Related**: Disposal Reasoning Stage, Smart-Bin Integration, Municipal APIs.

---

### 4a. Global Municipal Policy Engine 🔴

**Status**: Active build track (2026-05-20 onward). No longer local-only.

**Overview**: Policy correctness must scale beyond one city. We now have a canonical policy engine + rule-pack registry surface in code (`local_policy_engine.dart`, `local_policy_rule_packs.dart`), and this should be treated as a global municipal platform lane rather than BBMP-only feature work.

**Key questions**:

- How do we represent policy packs per authority/jurisdiction with strict versioning and provenance?
- What is the plugin + rule-pack contract for adding a new city without app-level branching?
- Which fields are mandatory in every policy decision for auditability (`rule_pack_id`, `policy_plugin_id`, compliance status, evaluated timestamp)?
- How do we validate and promote policy packs (draft -> reviewed -> production)?
- What is the global rollout strategy (India metro tier first, then international jurisdictions)?

**Current code anchors**:

- `lib/services/local_policy_engine.dart` — canonical policy evaluation/apply entrypoint
- `lib/services/local_policy_rule_packs.dart` — data-driven rule-pack registry
- `lib/services/local_guidelines_plugin.dart` — multi-city plugin routing scaffolds (BBMP, BMC, MCD)

**Deliverable**: `docs/exploration/GLOBAL_MUNICIPAL_POLICY_ENGINE.md`.

**Related**: Region-Aware Rulesets (#4), Municipal APIs (#25), Regional Regulations (#33), Audit / Telemetry (#35), B2B / Enterprise Wedge (#29).

---

### 5. Eval Harness & Golden Sets 🔴

**Status**: Missing as a first-class artefact. Ad-hoc tests in `test/`. No labelled golden set with held-out evaluation.

**Overview**: We cannot improve the AI stack without a measurable, repeatable evaluation. Needed before any model swap, prompt change, or routing rule change can be trusted.

**Key questions**:

- What's the minimum viable golden set (size, diversity, sources)?
- Which metrics matter — top-1 accuracy, calibration error, disposal-advice correctness, latency, cost?
- How do we collect labelled data ethically from user corrections?
- How is this wired into CI so model/prompt drift is caught early?

**Deliverable**: `docs/exploration/EVAL_HARNESS_AND_GOLDEN_SETS.md`.

**Related**: Multi-Model AI Routing, Classification Confidence, Continuous Learning.

---

## ON-DEVICE & EDGE

### 6. On-Device Inference 🔴

**Status**: Not implemented. Today every classification is a cloud call.

**Overview**: On-device inference unlocks offline use, privacy, faster perceived latency, and lower per-classification cost. Critical for emerging markets and as a competitive moat.

**Key questions**:

- Which Flutter-compatible runtimes work in practice (TFLite, MLC LLM, llama.cpp, MediaPipe, Apple Core ML, Android NNAPI)?
- What's the smallest model that solves the *common* case (single, well-lit, single-object scan) with acceptable quality?
- How do we ship model weights — bundled, lazy-downloaded, gated by device tier?
- What's the iOS/Android parity story given Apple Silicon vs Snapdragon NPU differences?

**Deliverable**: `docs/exploration/ON_DEVICE_INFERENCE.md`.

**Related**: Multi-Model AI Routing, Model Cascades, Battery / Thermal.

---

### 7. Model Cascades 🟡

**Status**: Conceptual. Cost-tier ladder discussed in `dynamic_pricing_service.dart` and `ai_cost_tracker.dart`, but no on-device tier exists yet.

**Overview**: A small on-device classifier handles "easy" cases; ambiguous results escalate to cloud. Should be deterministic and observable, not magic.

**Key questions**:

- What features drive escalation: confidence, entropy, scene complexity, user override history?
- How do we audit each escalation so we can tune the threshold?
- Does the cascade also include "ask the user a question" as a tier (active clarification)?

**Deliverable**: Folded into `docs/exploration/MULTI_MODEL_AI_ROUTING.md` and `docs/exploration/ON_DEVICE_INFERENCE.md`.

---

### 8. Battery, Thermal & Memory Budget 🟢

**Status**: Not measured systematically.

**Overview**: On-device inference is only viable if it doesn't tank battery, overheat the phone, or get the app killed for memory pressure. Especially relevant for the lower-end Android devices common in target markets.

**Key questions**:

- Per-classification energy cost on representative devices?
- Memory ceiling that keeps the app eligible for background work?
- How do we degrade gracefully on low-end devices (skip on-device, force cloud, force throttle)?

**Deliverable**: `docs/exploration/DEVICE_BUDGET.md`.

---

### 9. Offline-First Flow 🟡

**Status**: Partial — see `lib/services/cache_service.dart`, `offline_queue_*`, `QUALITY_GATE_OFFLINE_QUEUE_INTEGRATION.md`.

**Overview**: Offline classification capture + delayed sync is a strong wedge for fieldwork, schools, rural use. Today the queue exists but the end-to-end offline experience isn't a first-class promise.

**Key questions**:

- What's the canonical user contract when offline (capture only? cached classify? best-effort local?)?
- How do we reconcile when the user corrects a classification that was already shared to family/community?
- What happens to in-flight gamification rewards earned offline?

**Deliverable**: `docs/exploration/OFFLINE_FIRST_FLOW.md`.

**Related**: On-Device Inference, Classification History Schema.

---

## DATA, COST & RELIABILITY

### 10. AI Cost Telemetry & Guardrails 🔴

**Status**: In progress — `lib/services/ai_cost_tracker.dart`, `cost_guardrail_service.dart`, `cost_tracking_interceptor.dart` exist. Need an explicit policy doc.

**Overview**: AI cost is the single biggest scaling risk. Without per-user, per-feature, per-tier budgets and observable spend, the unit economics break before they're noticed.

**Key questions**:

- Per-user daily / monthly budgets — soft vs hard caps.
- Free-tier abuse mitigations (anonymous users, throwaway accounts, automation).
- Provider-level fallback when budget exhausted: smaller model? On-device only? Queue for tomorrow?
- Telemetry: dashboards we still need vs ones already wired in Firebase.

**Deliverable**: `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md`.

**Related**: Monetization & Pricing Tiers, On-Device Inference, Audit / Telemetry.

---

### 11. Offline Queue & Sync 🔴

**Status**: Implementation exists; semantics and conflict resolution under-specified.

**Overview**: When a classification is captured offline, what happens at sync? What about gamification points awarded against stale state? What about classifications corrected on another device?

**Key questions** (also see `QUALITY_GATE_OFFLINE_QUEUE_INTEGRATION.md`):

- Conflict-resolution policy per record type (classification, feedback, gamification, social).
- Idempotency keys for resubmission after network failure.
- Visible UI for "pending sync" with retry / cancel.
- Telemetry for stuck queues.

**Deliverable**: `docs/exploration/OFFLINE_QUEUE_AND_SYNC.md`.

---

### 12. Classification History Schema — *The Dataset Is the Moat* 🟡

**Status**: Stored via `classification_storage_service.dart`, `classification_migration_service.dart`. Schema evolution path under-documented. **Currently mis-framed as a data-engineering cost; should be framed as the project's primary defensible asset.**

**Reframing (from brainstorm pressure test, 2026-05-19)**: Every cloud-AI competitor will get to the same model quality we get to. The thing they can't replicate is a labelled, regionally-grounded waste-classification dataset built from real user corrections over years. That dataset lives in this schema. **Treat schema choices as moat choices, not migration choices.**

**Overview**: Classification history is the single most valuable user-owned artefact *and* the project's strongest long-term competitive position. Today the schema is implicit. We need an explicit contract for migrations, exports, downstream analytics, **and training-readiness**.

**Key questions**:

- Versioned schema with explicit migration steps.
- User-export contract (CSV / JSON / open formats) — relevant to GDPR-style asks.
- **Training-readiness fields**: what provenance, labels, corrections, region, model-version, prompt-version metadata must each record carry so it's directly usable for fine-tuning or eval-set growth without expensive re-derivation later?
- Anonymisation strategy if records feed model training.
- Consent posture that allows this asset to compound (opt-in defaults vs explicit-consent gates).

**Asset framing — what we're building, not just what we're storing**:

- The labelled dataset (image × label × correction × region × disposal-outcome) is the input to F3 (Continuous Learning Loop) and F8 (Brand / Manufacturer Closed-Loop Data).
- Schema decisions today (do we keep the original image? at what resolution? do we record the *correction chain*, not just the latest label?) determine whether the asset compounds or has to be rebuilt.
- This is upstream of On-Device Inference (training data for distilled models) and Continuous Learning (label source).

**Deliverable**: `docs/exploration/CLASSIFICATION_HISTORY_SCHEMA.md` — explicitly framed as a dataset/moat doc, not just a migration doc.

**Related**: Data Retention & PII (consent posture), Offline Queue & Sync, Eval Harness (downstream consumer), Continuous Learning (downstream consumer), F8 Brand / Manufacturer Data (downstream consumer).

---

### 13. Firestore Cost & Indexing 🟡

**Status**: Implicit. `firestore_batch_service.dart`, `firestore_schema_registry.dart` exist, but no formal cost model.

**Overview**: Reads, writes, and index storage on Firestore can become the dominant infra cost once user counts grow. Indexing decisions made early are expensive to undo.

**Key questions**:

- Current read/write hot paths and per-user cost projection.
- Aggregation patterns (materialised counters, scheduled functions) vs live queries.
- Index audit — which composite indexes are load-bearing, which are dead?

**Deliverable**: `docs/exploration/FIRESTORE_COST_AND_INDEXING.md`.

---

### 14. Data Retention & PII Strategy 🔴

**Status**: Partially captured in `docs/security/`, `docs/legal/`. No single retention policy document.

**Overview**: User-submitted photos are PII-adjacent and sometimes contain people, license plates, addresses. Retention, deletion, and training-use must be explicit before any monetisation or data-sharing move.

**Key questions**:

- Default retention windows per data class.
- "Delete my account" semantics — soft vs hard, latency, cascade.
- Photo redaction / blurring before any training reuse.
- Region-specific obligations (DPDP Act in India, GDPR in EU, COPPA for kids).

**Deliverable**: `docs/exploration/DATA_RETENTION_AND_PII_STRATEGY.md`.

**Related**: Privacy / Photo PII, Regional Regulations.

---

## USER EXPERIENCE & ENGAGEMENT

### 15. Persona Journeys 🟡

**Status**: Partial coverage across `docs/design/user_experience/user_flows/` and `docs/planning/ideas_to_explore.md`.

**Overview**: The app's value differs sharply across personas — household user, parent/family, school/teacher, RWA/society admin, municipal partner, sustainability officer. Without explicit per-persona journeys, the UX optimises for the median and serves no one well.

**Key questions**:

- Which personas justify dedicated flows now vs later?
- Where do journeys converge (shared classify flow) vs diverge (admin dashboards, classroom features)?
- What's the minimum persona-specific surface that earns retention?

**Deliverable**: `docs/exploration/PERSONA_JOURNEYS.md` — index pointing at per-persona sub-docs.

---

### 16. Gamification Depth 🟡

**Status**: Implemented at v1 — `gamification_service.dart`, achievements, streaks. Needs critical review.

**Overview**: Gamification is currently feature-rich but mechanically shallow — points, streaks, achievements. Question: does it actually drive correct disposal behaviour, or just classification volume?

**Key questions**:

- Are we rewarding the right behaviour (correct disposal vs more scans)?
- Long-term retention — what happens after novelty wears off (week 3 cliff)?
- Family/group mechanics — cooperative vs competitive vs both?
- Anti-cheating — what stops users farming points with photos of the same item?

**Deliverable**: `docs/exploration/GAMIFICATION_DEPTH.md`.

**Related**: Habit Formation Loop, Family / Group Mechanics.

---

### 17. Habit Formation Loop 🟡

**Status**: Not formalised. Implicit in gamification and notifications.

**Overview**: The app's environmental impact depends on **sustained behaviour change**, not one-time scans. This is a behavioural-science problem, not just a UX problem.

**Key questions**:

- What's the cue → routine → reward loop we're actually building?
- Which notifications drive return vs annoy?
- How does the loop adapt as the user's competence grows (educational scaffolding)?

**Deliverable**: `docs/exploration/HABIT_FORMATION_LOOP.md`.

---

### 18. Accessibility & Internationalisation 🟡

**Status**: l10n scaffolding present (`lib/l10n/`). Accessibility audit incomplete.

**Overview**: Target users include kids, elderly, low-literacy populations, and non-English speakers. Visual-first design helps but isn't enough.

**Key questions**:

- Screen-reader coverage for the classification flow.
- Voice-first capture as an accessibility path, not just a feature.
- Low-literacy iconography and audio guidance.
- Language priority order beyond English / Hindi.

**Deliverable**: `docs/exploration/ACCESSIBILITY_AND_I18N.md`.

---

### 19. Onboarding & Activation 🔴

**Status**: Onboarding flow exists; activation funnel not instrumented as a first-class concern.

**Overview**: First scan in first session is the hinge. If a user uninstalls before successfully classifying something they care about, nothing else matters.

**Key questions**:

- Time-to-first-successful-scan benchmark.
- Skip-onboarding-and-recover path.
- What's the "aha" moment we're optimising for? (correct classification? disposal advice? rewards?)

**Deliverable**: `docs/exploration/ONBOARDING_AND_ACTIVATION.md`.

---

## COMMUNITY & SOCIAL

### 20. Community Feed Trust Layer 🟡

**Status**: Community feed exists (`community_service.dart`). No formal trust or anti-abuse layer.

**Overview**: User-generated content (classifications shared, comments, reactions) is a vector for misinformation and abuse. Trust needs to be designed in, not retrofitted.

**Key questions**:

- Verification levels — anonymous, email-verified, identity-verified.
- Reporting and takedown flow.
- Misinformation handling when a community-shared "correct" answer is wrong.

**Deliverable**: `docs/exploration/COMMUNITY_TRUST_LAYER.md`.

**Related**: Moderation & Safety, Content Provenance.

---

### 21. Family / Group Mechanics 🟡

**Status**: Family features implemented at v1 — `firebase_family_service.dart`.

**Overview**: Family / household / classroom / society groups are a strong retention surface. Mechanics need to be deliberate, not just "groups exist".

**Key questions**:

- Role model (parent / kid / admin / member / observer).
- Privacy boundaries within a group.
- Cross-group movement (kid graduates from family to school group).

**Deliverable**: `docs/exploration/FAMILY_GROUP_MECHANICS.md`.

---

### 22. Local Reuse Marketplace 🟢

**Status**: Frontier idea — captured in `planning/ideas_to_explore.md`.

**Overview**: Items become waste only when no one wants them. A neighbourhood-scoped reuse marketplace (give-away, swap, sell) reduces input volume to the waste stream.

**Key questions**:

- Is this a feature, a separate surface, or a separate product?
- Trust, safety, and logistics at neighbourhood scale.
- Interaction with existing local platforms (OLX, WhatsApp groups, society apps).

**Deliverable**: `docs/exploration/LOCAL_REUSE_MARKETPLACE.md`.

---

### 23. Moderation & Safety 🔴

**Status**: Light moderation hooks exist; no comprehensive safety policy.

**Overview**: Photos, comments, family members, kid users — the surface area for safety problems is wide. Required before any meaningful community growth.

**Key questions**:

- Child-safety surfaces (COPPA, India DPDP, age gating).
- Image moderation pipeline (NSFW, PII, faces).
- Escalation paths for abuse reports.

**Deliverable**: `docs/exploration/MODERATION_AND_SAFETY.md`.

---

## IoT, SMART CITY & PARTNERS

### 24. Smart-Bin Integration 🟢 [FRONTIER]

**Status**: Frontier — discussed in `STRATEGIC_ROADMAP_COMPREHENSIVE.md`.

**Overview**: IoT-enabled bins that log disposals, fill-levels, and feed municipal collection routing. High narrative value but high integration cost.

**Key questions**:

- Hardware partner vs reference design vs aggregation layer.
- What's the smallest useful integration (QR code on a bin) before any real IoT?
- Who pays — municipality, RWA, app, brand sponsor?

**Deliverable**: `docs/exploration/SMART_BIN_INTEGRATION.md`.

---

### 25. Municipal APIs (BBMP, etc.) 🟡

**Status**: Aspirational. No concrete integration today.

**Overview**: City-level partnerships unlock authoritative rulesets, official drop-off locations, collection schedules, and credibility. They are slow but defensible.

**Key questions**:

- Which cities are reachable and have data worth integrating?
- What's the lightest-touch integration that earns the badge (link out, scheduled scrape, API)?
- How do we keep the rulesets fresh if the city's data is stale?

**Deliverable**: `docs/exploration/MUNICIPAL_PARTNER_INTEGRATION.md`.

**Related**: Region-Aware Rulesets, Smart-Bin Integration.

---

### 26. Informal Collector Network 🟢

**Status**: Frontier. Particularly relevant in Indian and emerging-market contexts.

**Overview**: Informal waste collectors (kabadiwalas, ragpickers) are the actual end-state for most recyclable material. Connecting users directly to them could short-circuit a lot of friction.

**Key questions**:

- Onboarding model for collectors (literacy, devices, payments).
- Trust and verification.
- Interaction with formal municipal flows — complement or conflict?

**Deliverable**: `docs/exploration/INFORMAL_COLLECTOR_NETWORK.md`.

---

### 27. Hardware Partners 🟢

**Status**: Frontier. None engaged.

**Overview**: Smart bins, weighing scales, embedded cameras at apartment chutes — partnerships that put the app where waste actually happens.

**Deliverable**: Folded into `SMART_BIN_INTEGRATION.md` until a real partner conversation justifies a standalone doc.

---

## BUSINESS & GROWTH

### 27a. Token Economy & Pricing Coherence 🔴 [IN FLIGHT — 2026-05-19]

**Status**: **Active research and execution today.** Multi-role brainstorm produced 9 perspective docs (`brainstorm_*_2026-05-19.md`) plus a [synthesis](brainstorm_synthesis_2026-05-19.md). Execution surface in [../TOKEN_ECONOMY_TODO.md](../TOKEN_ECONOMY_TODO.md). This topic was added to the exploration index on 2026-05-19 after a pressure test showed the map omitting the work actually in flight.

**Overview** (from [Cartographer brainstorm](brainstorm_cartographer_2026-05-19.md)): The current token economy has three disconnected territories — Instant Analysis (labelled "5 tokens" but actually charges 0), Batch Analysis (labelled "1 token", actually charges 1), and Premium (no visible connection to tokens). Users see a price tag that contradicts the receipt. The brain resolves the contradiction by ignoring the sign.

**Key questions** (drawn from the 2026-05-19 brainstorm set):

- **Coherence**: what does a token *mean*, end-to-end, across capture → classify → result → history → premium → settings? One unit, one meaning, one visible balance, one consistent ledger.
- **Pricing reality vs labelling**: where do labels lie about cost? Where does the receipt match? The "5 tokens, charge 0" contradiction is the canonical bug.
- **Premium ↔ token economy bridge**: is premium "more tokens", "no tokens", "different tokens", or a separate axis entirely? Today it's a separate universe.
- **Balance visibility**: when should a user see their token balance, before vs after action?
- **Abuse / fairness**: anonymous-user economics, free-tier sustainability, what stops a single user from draining the AI cost budget.
- **Cross-link to AI Cost Telemetry**: the token model is the user-facing layer over real provider cost — see entry 10.

**Asset framing**: token economy clarity is upstream of monetization decisions (entry 28), brand trust, and the credibility of every "premium" surface. It is also the user-visible expression of [AI Cost Telemetry & Guardrails](#10-ai-cost-telemetry--guardrails-) — these two topics must agree on the same conceptual ledger.

**Deliverable**: a coherent token-economy decision doc that resolves the three-territory contradiction. Likely path:

1. Synthesis already exists at [brainstorm_synthesis_2026-05-19.md](brainstorm_synthesis_2026-05-19.md) — promote relevant conclusions into a permanent `docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md`.
2. That doc must reference [../TOKEN_ECONOMY_TODO.md](../TOKEN_ECONOMY_TODO.md) as the live execution checklist, and update it as decisions land.

**Related**: Monetization & Pricing Tiers (entry 28, downstream), AI Cost Telemetry & Guardrails (entry 10, sibling layer), Onboarding & Activation (entry 19 — first-token UX is part of activation), Audit / Telemetry (entry 35 — token ledger is part of the audit surface).

**Source artefacts (must not be forked)**:

- [brainstorm_strategist_2026-05-19.md](brainstorm_strategist_2026-05-19.md)
- [brainstorm_champion_2026-05-19.md](brainstorm_champion_2026-05-19.md)
- [brainstorm_operator_2026-05-19.md](brainstorm_operator_2026-05-19.md)
- [brainstorm_cartographer_2026-05-19.md](brainstorm_cartographer_2026-05-19.md)
- [brainstorm_skeptic_2026-05-19.md](brainstorm_skeptic_2026-05-19.md)
- [brainstorm_trickster_2026-05-19.md](brainstorm_trickster_2026-05-19.md)
- [brainstorm_executioner_2026-05-19.md](brainstorm_executioner_2026-05-19.md)
- [brainstorm_future_self_2026-05-19.md](brainstorm_future_self_2026-05-19.md)
- [brainstorm_synthesis_2026-05-19.md](brainstorm_synthesis_2026-05-19.md)
- [../TOKEN_ECONOMY_TODO.md](../TOKEN_ECONOMY_TODO.md)
- [ai_service_refactor_motto_v2_2026-05-19.md](ai_service_refactor_motto_v2_2026-05-19.md) (related refactor of the cost-bearing AI surface)

---

### 28. Monetization & Pricing Tiers 🟡

**Status**: Premium model exists (`premium_features.hive`, `dynamic_pricing_service.dart`). Pricing logic not justified from first principles.

**Overview**: Premium-vs-free split determines unit economics. Today the split is intuitive, not data-driven.

**Key questions**:

- What's the **value** in the premium tier (cloud quality? family seats? offline pack? educational content?)?
- Anchor pricing across regions (India vs US purchasing power).
- Family / group plans vs per-seat.
- Free-tier limits that drive conversion without breaking the core promise.

**Deliverable**: `docs/exploration/MONETIZATION_AND_PRICING_TIERS.md`.

**Related**: AI Cost Telemetry, B2B / Enterprise Wedge.

---

### 29. B2B / Enterprise Wedge 🟢

**Status**: Frontier.

**Overview**: Corporates, schools, RWAs, hotels all have sustainability mandates. The same core tech with reporting, admin, and bulk seats is a different product.

**Key questions**:

- Which segment has the cleanest wedge (schools? corporate ESG? hospitality?).
- What admin surfaces are table-stakes (dashboard, exports, SSO)?
- White-label vs first-party — when does each make sense?

**Deliverable**: `docs/exploration/B2B_ENTERPRISE_WEDGE.md`.

---

### 30. Carbon / Impact Accounting 🟡

**Status**: Surface-level — points and stats, but no defensible methodology.

**Overview**: The app's headline narrative is environmental impact. Claims about CO₂ saved, plastic diverted, etc. need methodology backing or they become a liability.

**Key questions**:

- Which impact framework (EPA, IPCC, regional)?
- How do we attribute impact to user action vs ambient behaviour?
- How do we expose uncertainty in impact numbers without killing motivation?

**Deliverable**: `docs/exploration/CARBON_AND_IMPACT_ACCOUNTING.md`.

---

### 31. Distribution & Partnerships 🟢

**Status**: Frontier.

**Overview**: Organic install is slow. Channels — schools, RWAs, brand partners, municipal pilots, sustainability NGOs — are how this product gets reach. Each channel changes the product.

**Deliverable**: `docs/exploration/DISTRIBUTION_AND_PARTNERSHIPS.md`.

---

## COMPLIANCE & TRUST

### 32. Privacy / Photo PII 🔴

**Status**: Implicit. No formal photo-PII policy.

**Overview**: User photos can contain faces, license plates, addresses, medical info. Required as a foundation before any model training, data sharing, or partner integration.

**Key questions**:

- On-device face/PII redaction before any upload.
- Explicit consent UI for any photo use beyond classification.
- Cross-border data flow constraints.

**Deliverable**: `docs/exploration/PRIVACY_PHOTO_PII.md`.

**Related**: Data Retention & PII, Moderation & Safety.

---

### 33. Regional Regulations 🟡

**Status**: Partial. `docs/legal/`, `docs/security/` exist.

**Overview**: India DPDP, EU GDPR, COPPA in the US, regional waste-rule jurisdictions all apply. Tracking obligations explicitly avoids retrofitting compliance.

**Deliverable**: `docs/exploration/REGIONAL_REGULATIONS.md`.

---

### 34. Content Provenance 🟢

**Status**: Frontier.

**Overview**: As classifications, disposal advice, and educational content are increasingly model-generated, provenance (model, prompt, version, sources) becomes important for trust and for handling drift.

**Deliverable**: Folded into `EVAL_HARNESS_AND_GOLDEN_SETS.md` for now.

---

### 35. Audit / Telemetry 🟡

**Status**: Partial — analytics services exist, no single audit policy.

**Overview**: For trust, debugging, and compliance, we need a single answer to "what did the app do for this user, when, and why?" This crosses analytics, logs, and ML decisions.

**Deliverable**: `docs/exploration/AUDIT_AND_TELEMETRY.md`.

---

## PIPELINE EVOLUTION

The end-to-end user pipeline today:

```diagram
╭──────────╮   ╭───────────╮   ╭──────────╮   ╭──────────╮   ╭────────╮
│ Capture  │──▶│ Classify  │──▶│ Educate  │──▶│ Dispose  │──▶│ Reward │
│ (camera) │   │ (AI/cloud)│   │ (content)│   │ (advice) │   │ (game) │
╰──────────╯   ╰─────┬─────╯   ╰──────────╯   ╰──────────╯   ╰────────╯
                     │
                     ▼
              ╭─────────────╮
              │  Feedback / │
              │  Corrections│──▶ active learning, golden-set growth
              ╰─────────────╯
```

Open questions across the pipeline:

- **Capture**: voice/audio capture, batch capture, video, third-party share intents.
- **Classify**: see AI & Vision and On-Device sections above.
- **Educate**: how educational content scales without becoming generic; see `educational_content_service.dart`.
- **Dispose**: see Region-Aware Rulesets, Smart-Bin Integration.
- **Reward**: see Gamification Depth, Habit Formation Loop.
- **Feedback**: continuous learning loop — see Eval Harness, Classification History Schema.

---

## Maintenance

- **Owner**: project lead (Pranay) until delegated.
- **Cadence**: review monthly; refresh priority bands; archive completed/killed topics with rationale.
- **Drift check**: before opening a new exploration doc, re-read this index and `exploration/backlog.md` to avoid duplicate work.
- **Cross-references**: any new doc under `docs/exploration/` MUST link back to this index and update the relevant entry status.

---

# Additional Topics Surfaced 2026-05-19 (Code + Industry Scan)

**Provenance**: this section was added after a directed scan of `lib/services/` (73 services), `lib/screens/` (42 screens), `lib/models/` (33 models), `lib/providers/` (14 providers), the `docs/` subfolders (admin/, analytics/, security/, technical/, launch/, etc.), and a 2025–2026 industry literature pass (EU ESPR / Digital Product Passport timelines, VLM-for-waste-classification papers, AMP Robotics / Greyparrot / Recycleye MRF-side competitors, EU Battery Regulation). The first pass of the map (entries 1–35 + 27a) missed the 25+ topics below — they are real, in code, in docs, or in active regulation and should be on the index.

New entries are numbered `A1–A25` and grouped into (a) additions to existing categories, (b) new categories that didn't exist in the first pass, and (c) industry / external signals that aren't a code surface but should be tracked as research inputs.

---

## A — Additions to Existing Categories

### A1. Image Capture & Quality Gate 🔴

**Category**: AI & Vision (upstream of every classification call)

**Status**: Code lives in `lib/services/image_quality_gate.dart`, `enhanced_image_processing_service.dart`, `enhanced_image_service.dart`, `tflite_preprocessing_helper.dart`, `thumbnail_migration_service.dart`. Integration described in [QUALITY_GATE_OFFLINE_QUEUE_INTEGRATION.md](QUALITY_GATE_OFFLINE_QUEUE_INTEGRATION.md). Not yet on the exploration index.

**Why this is a topic, not just code**: Image quality is the single biggest predictor of classification accuracy. "Bad photo → model unsure" is currently indistinguishable from "good photo → model unsure" in the user's experience. The gate is the place where this gets disentangled.

**Key questions**:

- What's the minimum gate (blur / framing / lighting / single-object / object-presence) that catches the bottom 20% of inputs without frustrating users?
- Does the gate run before or after capture (predict-then-shoot vs. shoot-then-check)?
- How does the gate signal feed Multi-Model Routing — bad gate score → escalate, skip on-device, or refuse?
- What does an "improve your photo" coaching UX look like that doesn't read as scolding?

**Deliverable**: `docs/exploration/IMAGE_CAPTURE_AND_QUALITY_GATE.md`.

**Related**: Multi-Model AI Routing (#1), Classification Confidence (#2), On-Device Inference (#6), Onboarding & Activation (#19).

---

### A2. AI Race / Multi-Provider Concurrency 🟡

**Category**: AI & Vision

**Status**: Implemented as opt-in `analyzeWithRace` in `EnhancedAiApiService` — see [AI_API_RACE_FAULT_TOLERANCE.md](AI_API_RACE_FAULT_TOLERANCE.md). Currently behind an A/B percentage. Not yet on the exploration index.

**Why this is a topic**: Racing OpenAI + Gemini in parallel changes the latency story but doubles the per-classification cost. It's an explicit cost-vs-latency-vs-quality trade-off that deserves its own decision, not just a feature flag.

**Key questions**:

- When does race-mode pay for itself (latency-sensitive paths, premium tier, retries after first-pass failure)?
- Quality ladder: should the second runner be a *cheaper* model (race-to-floor) or an *equivalent* model (race-to-best-of-N)?
- Cost interaction with token economy (#27a) — is race mode a premium feature or a hidden cost?
- Telemetry: which provider wins, by which margin, on which input class?

**Deliverable**: `docs/exploration/AI_RACE_AND_MULTI_PROVIDER_CONCURRENCY.md`.

**Related**: Multi-Model AI Routing (#1), AI Cost Telemetry (#10), Token Economy (#27a), AI Failure Taxonomy (A3).

---

### A3. AI Failure Modes Taxonomy 🟡

**Category**: AI & Vision

**Status**: `lib/services/ai_failure.dart` exists; no shared taxonomy doc.

**Why this is a topic**: "AI failed" is the single most user-affecting and least-instrumented event class. Today every failure is collapsed into one. They should be at least: provider error / timeout / safety refusal / parse failure / quality-gate rejection / classification with confidence-too-low / contradictory multi-provider answers.

**Key questions**:

- Which failure modes map to which user-facing copy?
- Which failures consume tokens, which don't?
- Which failures should auto-retry, which require user action?
- How do failure rates trend per provider over time (drift detection)?

**Deliverable**: `docs/exploration/AI_FAILURE_TAXONOMY.md`.

**Related**: Token Economy (#27a — failures must not charge), AI Cost Telemetry (#10), Audit / Telemetry (#35).

---

### A4. Model Lifecycle — Download, Selection, Versioning 🟡

**Category**: On-Device & Edge

**Status**: `lib/services/model_download_service.dart`, `model_selection_service.dart`, `vision_model_config.dart` exist. No exploration topic yet.

**Why this is a topic**: On-device inference (#6) is the *capability*; this is the *operations* — how weights get to the device, how the right model gets picked per device tier, how upgrades roll out, how old versions sunset.

**Key questions**:

- Bundle vs lazy-download vs progressive download strategy.
- Per-device-tier model selection (NPU presence, RAM, OS version).
- Versioning + rollback when a downloaded model misbehaves.
- Signature verification — prevent supply-chain swap of model weights.

**Deliverable**: `docs/exploration/MODEL_LIFECYCLE.md`.

**Related**: On-Device Inference (#6), Battery / Thermal (#8), Eval Harness (#5, gating roll-outs).

---

### A5. Object Detection & Multi-Object Scenes 🟡

**Category**: AI & Vision

**Status**: `lib/services/object_detection_service.dart` exists. Today the dominant path assumes single-object classification.

**Why this is a topic**: Real-world waste is cluttered (kitchen counter, recycling pile, garage clean-out). Without object detection / segmentation, the model is forced to pick one label for a scene that should produce N labels.

**Key questions**:

- When does detection precede classification (multi-object scenes) vs replace it (just count items)?
- Does detection run on-device with cloud falling back for segmentation?
- UX: how do you show "5 items detected, classify each"?
- Performance budget — detection + N classification calls is expensive.

**Deliverable**: `docs/exploration/OBJECT_DETECTION_AND_MULTI_OBJECT.md`.

**Related**: Multi-Model AI Routing (#1), On-Device Inference (#6), Image Capture & Quality Gate (A1).

---

### A6. Smart Suggestions / Next-Best-Action 🟡

**Category**: UX & Engagement

**Status**: `lib/services/smart_suggestions_service.dart`, `lib/screens/smart_suggestions_screen.dart` exist. No exploration topic.

**Why this is a topic**: After a classification, the app can do many things (educate, gamify, suggest related disposal, prompt for community share, route to facility, link to reuse marketplace). Which to surface, when, and why — is its own design problem.

**Key questions**:

- Suggestion ranking model — rules vs learned vs context-aware?
- How do suggestions degrade gracefully when context is thin (anonymous user, first scan)?
- Anti-pattern guardrails — when do suggestions feel like nagging?

**Deliverable**: `docs/exploration/SMART_SUGGESTIONS_NEXT_BEST_ACTION.md`.

**Related**: Habit Formation Loop (#17), Onboarding & Activation (#19), Notification Strategy (A12).

---

### A7. Knowledge Verification / Quiz Loop 🟢

**Category**: UX & Engagement

**Status**: `lib/screens/quiz_screen.dart` exists; no exploration topic.

**Why this is a topic**: Quizzes are the only mechanism in the app that verifies the user *learned* something, not just *did* something. Strong tie to the educational mission and to gamification depth (#16).

**Key questions**:

- Adaptive difficulty — quiz from the user's own correction history?
- Reward asymmetry — should quiz mastery unlock more than scan volume does?
- Integration with school / classroom B2B wedge (#29).

**Deliverable**: `docs/exploration/KNOWLEDGE_VERIFICATION_QUIZ.md`.

**Related**: Gamification Depth (#16), Habit Formation Loop (#17), B2B / Enterprise Wedge (#29).

---

### A8. AI-Generated Educational Content 🟡

**Category**: UX & Engagement

**Status**: `lib/services/educational_content_service.dart`, `educational_content_analytics_service.dart`, `ai_discovery_content.dart` exist. Mentioned in passing in entry 17 but not as its own topic.

**Why this is a topic**: Generating educational content on demand (LLM) vs curating a fixed library is a fundamentally different operating model — different cost, quality control, freshness, and IP posture.

**Key questions**:

- Generated vs curated vs hybrid — which scales, which is safer?
- Caching strategy when generated content is per-classification.
- Content moderation pipeline for LLM-generated material before user exposure.
- Multilingual generation vs translation.

**Deliverable**: `docs/exploration/AI_GENERATED_EDUCATIONAL_CONTENT.md`.

**Related**: AI Cost Telemetry (#10), Content Provenance (#34), Accessibility & I18n (#18).

---

### A9. Personal Impact Dashboard UX 🟡

**Category**: UX & Engagement (distinct from Carbon Accounting methodology)

**Status**: `lib/screens/impact_dashboard_screen.dart`, `lib/screens/waste_dashboard_screen.dart` exist. Carbon methodology is entry #30; this is the user-facing *presentation* of that data.

**Why a separate topic**: Methodology (what numbers we compute) and presentation (how we make them feel real to the user) have different success criteria. A perfect number presented badly motivates nobody.

**Key questions**:

- Comparison metaphors that work cross-culturally ("X trees" / "Y kg CO₂" / "Z bottles").
- Honest uncertainty without killing motivation.
- Personal vs household vs community framing — which the user remembers.
- Sharing surface — what's the right snippet to post externally?

**Deliverable**: `docs/exploration/PERSONAL_IMPACT_DASHBOARD_UX.md`.

**Related**: Carbon / Impact Accounting (#30), Habit Formation Loop (#17), Social Sharing (A11).

---

### A10-N1. Navigation Information Architecture & Bottom Nav Design 🟡

**Category**: UX & Engagement

**Status**: Current implementation — 5-tab bottom nav (Home, Scan, History, Social, Achievements) with Settings reachable only via a gear icon in the Home header. `lib/widgets/navigation_wrapper.dart` owns the nav bar; `lib/screens/social_screen.dart` uses an in-screen FAB toggle to switch between Community and Family sub-views.

**Why this is a topic**: The app is scan-centric but the Scan tab sits at position 2 (center-ish) with no persistent FAB pattern. Settings is hidden behind a header icon discoverable only from Home. The Social screen uses an FAB toggle for two sub-views — a pattern that's fragile on small screens and invisible on the Community sub-view at bottom-right. As the app grows, the 5-tab structure may not accommodate new contexts (local guidelines, disposal locations, partner programs) without tab proliferation.

**Key questions**:

- Should the primary CTA (scan) be a persistent FAB overlaid on all tabs, or is a dedicated tab sufficient for this usage pattern?
- Is 5 tabs too many for a utility app? What's the right grouping model — task-flow (Scan, Review, Share) vs content (Home, Social, Achievements)?
- Settings discovery: gear icon in header vs Settings tab vs Profile page? Research shows users expect Settings in Profile or nav overflow — a header icon tied to one tab is non-standard.
- Social FAB toggle (Community ↔ Family): should this be top tab bar, segmented control, or separate bottom-nav tabs?
- Does the current nav structure communicate "this is a scanning app" immediately to a new user?
- Returning-user pattern: should the app deep-link back to last scan result or land on Home?

**Deliverable**: `docs/exploration/NAVIGATION_IA.md` — IA options, comparables from scan-centric apps (Yuka, Think Dirty, FoodKeeper), decision framework for FAB-vs-tab, Settings placement recommendation.

**Related**: Onboarding & Activation (entry 19), Persona-Specific Journeys (#16), Home Screen IA (A10-N3).

---

### A10-N2. Mobile UX Patterns for Scan-Centric Utility Apps 🟡

**Category**: UX & Engagement

**Status**: No research doc exists. The app's interaction model is heavily camera-first but the surrounding UI is structured like a content-feed app.

**Why this is a topic**: Scan-centric apps (barcode scanners, plant ID, food label readers) have established UX patterns that differ from social or content apps. The dominant pattern is: persistent viewfinder CTA → instant result → actionable next step → optional save/share. The current app wraps this scan flow inside a content-navigation structure, which may add friction for the primary use case (quick scan while standing at a bin).

**Key questions**:

- What is the minimal tap count from cold launch to classification result? (Target: ≤ 2 taps.)
- Should the camera open directly on first launch / after onboarding?
- How do industry-leading scan-centric apps (Yuka, PictureThis, Google Lens) handle the scan→result→action loop?
- What does "quick re-scan" look like — immediate camera re-open or result-screen back button?
- Haptics and audio as confirmation signals for scan-centric flows.
- Offline-first scan: result display should not block on network; how does the current architecture rank against this?

**Deliverable**: `docs/exploration/SCAN_CENTRIC_UX_PATTERNS.md` — competitive teardown of 5 scan-centric apps, pattern matrix, gap analysis against current implementation.

**Related**: Onboarding & Activation (entry 19), Image Quality Gate (entry in services), Navigation IA (A10-N1).

---

### A10-N3. Home Screen Information Architecture 🟡

**Category**: UX & Engagement

**Status**: `lib/screens/home_screen.dart` — SliverAppBar header with gradient, greeting text, 4 stat chips (Points, Tokens, Streak, Days Active); below: quick-actions, recent activity, featured content sections. Header `expandedHeight` tuning has already caused visual bugs (excess blank space, greeting truncation at 360dp logical width).

**Why this is a topic**: The home screen currently tries to do four jobs at once — personal greeting, stats dashboard, quick-action launcher, and activity feed. Each job has a different mental model and visit frequency. The stat chips (Points, Tokens, Streak, Days) are engagement metrics, not decision-making inputs — their placement in a collapsing hero header means they're most prominent when least useful (on first open) and hidden when most relevant (during a session).

**Key questions**:

- What information does a returning daily user need on home vs a new user on first open?
- Are Points and Tokens useful at a glance, or do they generate anxiety (gamification fatigue)?
- Should home be a dashboard (current) or a launch pad (large scan CTA + minimal chrome)?
- Collapsible SliverAppBar vs fixed header — does the collapse serve any interaction or just burn layout space?
- What should the collapsed/pinned state show? Currently: nothing (toolbarHeight: 0) — is that intentional or a gap?
- How does the home screen hierarchy change when the user has no scans yet vs 100+ scans?

**Deliverable**: `docs/exploration/HOME_SCREEN_IA.md` — wireframe options (dashboard vs launcher vs hybrid), jobs-to-be-done mapping, progressive disclosure model for new vs returning users.

**Related**: Onboarding & Activation (entry 19), Navigation IA (A10-N1), Personal Impact Dashboard UX (A9), Habit Formation Loop (#17).

---

## B — New Category: PLATFORM & RELEASE ENGINEERING

The first pass treated platform / release as out-of-scope for *research*. That was wrong — there are real unknowns here that affect product reach.

### A10. iOS / Android / Web Cross-Platform Parity 🟡

**Status**: Active worklog — see [IOS_ANDROID_PARITY.md](IOS_ANDROID_PARITY.md). Web surface in `lib/web_standalone.dart`, `lib/screens/web_fallback_screen.dart`. Cross-platform feature drift recorded but not researched as a category.

**Why this is a topic**: "Where does this feature work?" and "what subset works on iOS / Android / Web?" determines the actual install / activation funnel. On-device inference, ATT, push notifications, and AdMob all diverge per platform.

**Key questions**:

- Which features intentionally diverge (e.g., on-device inference where NPU is available) vs accidentally diverge?
- Web's role — landing surface, demo, full app, or progressive fallback?
- Feature-flag visibility per platform.

**Deliverable**: `docs/exploration/CROSS_PLATFORM_PARITY.md`.

**Related**: On-Device Inference (#6), A/B Testing & Feature Flags (A13), Launch / Release (A14).

---

### A11. Notification Strategy 🟡

**Status**: `lib/screens/notification_settings_screen.dart` exists; Firebase Messaging integrated. No notification policy doc.

**Why this is a topic**: Push notifications are the single highest-leverage retention surface — and the single fastest path to uninstall if abused. The design space (transactional / coaching / streak / community / re-engagement / disposal-reminder) is wide and largely unowned.

**Key questions**:

- Which notification classes earn long-term opt-in vs trigger uninstall?
- Quiet hours / frequency caps.
- Local-time-aware scheduling (waste collection day reminders) vs server-pushed.
- Re-engagement cadence for dormant users (entry #19's "returning after N weeks").

**Deliverable**: `docs/exploration/NOTIFICATION_STRATEGY.md`.

**Related**: Onboarding & Activation (#19), Habit Formation Loop (#17), Smart Suggestions (A6).

---

### A12. A/B Testing & Feature Flags 🟡

**Status**: `lib/models/ab_testing_config.dart`, `lib/providers/feature_flags_provider.dart` exist; `analyzeWithRace` already uses an A/B percentage (see A2). No experiment-design or analysis methodology.

**Why this is a topic**: Without an experiment harness, "is this better?" is opinion. The infrastructure to *run* experiments exists; the discipline to *interpret* them doesn't.

**Key questions**:

- Minimum sample size per experiment for the current MAU.
- Guardrail metrics — what crashes / cost spikes auto-halt an experiment.
- Naming / lifecycle / cleanup discipline for flags (avoid flag graveyard).
- Server-driven flags (Firebase Remote Config) vs build-time flags.

**Deliverable**: `docs/exploration/AB_TESTING_AND_FEATURE_FLAGS.md`.

**Related**: Remote Config & Kill Switches (A13), Analytics Schema Governance (A18), AI Cost Telemetry (#10, guardrail metric).

---

### A13. Remote Config & Kill Switches 🟡

**Status**: `lib/services/remote_config_service.dart` exists. Used ad-hoc; no governance doc.

**Why this is a topic**: Remote config is the lever to disable a misbehaving feature without a release. It's load-bearing for safety (model swap rollback, cost spike halt, regional disable) and deserves a deliberate contract.

**Key questions**:

- What MUST be remote-controllable (provider downgrade, on-device tier disable, cost cap)?
- Fail-safe defaults when remote config is unreachable.
- Audit log for who flipped what when.

**Deliverable**: `docs/exploration/REMOTE_CONFIG_AND_KILL_SWITCHES.md`.

**Related**: A/B Testing (A12), AI Cost Telemetry (#10), Audit / Telemetry (#35).

---

### A14. Launch Readiness & App Store Compliance 🟡

**Status**: Docs exist — `docs/launch/CLOSED_BETA_SMOKE_CHECKLIST.md`, `docs/launch/LAUNCH_BLOCKERS.md`, `docs/planning/app_store_publication_p0_features.md`. No research-level topic.

**Why this is a topic**: App Store / Play Store rejections (privacy disclosures, ATT, in-app purchase rules, content moderation, kid-targeted features) are recurring product-shaping forces, not one-off chores.

**Key questions**:

- iOS App Store privacy nutrition labels — current vs target state.
- Play Store data safety form — current vs target state.
- Kid-targeted policy implications if the product moves toward classroom use (entry #29).

**Deliverable**: `docs/exploration/LAUNCH_AND_STORE_COMPLIANCE.md`.

**Related**: Privacy / Photo PII (#32), Regional Regulations (#33), Moderation & Safety (#23), B2B / School Wedge (#29 / F10).

---

### A15. Account / Identity Lifecycle 🟡

**Status**: `lib/screens/auth_screen.dart`, anonymous-auth flows, `firebase_cleanup_service.dart`, `fresh_start_service.dart` exist. Existing spec: `docs/planning/account_reset_and_delete_specification.md`. No topic in the index.

**Why this is a topic**: The account lifecycle (anonymous → guest → email-verified → social-linked → premium → deleted) determines what data persists, what survives a reinstall, and what an attacker can do. Today these transitions are implicit.

**Key questions**:

- Anonymous-to-identified merge — what carries over (history, gamification points, premium)?
- Multi-device same-account semantics (already partially in offline queue topic).
- Account deletion contract — soft vs hard, cascade, refund posture.

**Deliverable**: `docs/exploration/ACCOUNT_IDENTITY_LIFECYCLE.md`.

**Related**: Offline Queue & Sync (#11), Data Retention & PII (#14), Token Economy (#27a, balance on reinstall).

---

## C — New Category: GROWTH & DISTRIBUTION SURFACES

Not on the first-pass map at all. These are the *user-acquisition and revenue* surfaces, distinct from the strategic positioning topics (#28 Monetization, #29 B2B, #31 Distribution).

### A16. Deep Links, Sharing & Viral Loops 🟡

**Status**: `lib/services/dynamic_link_service.dart`, `lib/screens/social_screen.dart`, `shared_waste_classification.dart` exist. No growth-loop doc.

**Why this is a topic**: An app whose classification result can be *shared* and produces a *recipient install* is a fundamentally different growth model than one that doesn't. Dynamic links exist; the loop they enable isn't designed.

**Key questions**:

- What's the most-shareable artifact (a classification card, an impact summary, a streak badge)?
- Attribution model — does the sharer get rewarded?
- Deep-link landing UX — open the shared item directly, or land in onboarding?

**Deliverable**: `docs/exploration/DEEP_LINKS_SHARING_VIRAL_LOOPS.md`.

**Related**: Onboarding & Activation (#19), Referral Mechanics (could become A24), Distribution & Partnerships (#31).

---

### A17. Ads / Revenue Diversification 🟢

**Status**: `lib/services/ad_service.dart` exists (AdMob).

**Why this is a topic**: Ads are revenue *and* a tax on UX. The current decision to include AdMob is implicit; the design of where/when/how ads appear, and whether they're worth it vs premium-only, is a real product question.

**Key questions**:

- Eligible ad surfaces vs ad-free surfaces (premium, kid-mode, classroom).
- Format mix — banner vs interstitial vs rewarded.
- Are *rewarded* ads a better fit (earn tokens to scan) — direct tie to token economy (#27a)?
- Brand-safe targeting for a sustainability product.

**Deliverable**: `docs/exploration/ADS_REVENUE_DIVERSIFICATION.md`.

**Related**: Monetization & Pricing Tiers (#28), Token Economy (#27a), Privacy / Photo PII (#32 — ad-tracking interaction).

---

### A18. Analytics Schema Governance 🟡

**Status**: Substantial — `docs/analytics/` (5 docs), `lib/services/analytics_service.dart`, `analytics_schema_validator.dart`, `analytics_models.g.dart`, `analytics_consent_manager.dart`. No exploration entry.

**Why this is a topic**: Analytics events accumulate entropy fast. Without an explicit schema + change-review process, the dashboard "user activated" can mean three things in three months, none documented.

**Key questions**:

- Single source of truth for event names + properties.
- Backward-compatibility contract for event renames / removals.
- Tie to consent (`analytics_consent_manager.dart`) — what events fire pre-consent vs post-consent.
- Auto-generated event catalogue from code for the analytics team.

**Deliverable**: `docs/exploration/ANALYTICS_SCHEMA_GOVERNANCE.md`.

**Related**: Audit / Telemetry (#35), Privacy / Photo PII (#32), A/B Testing (A12 consumer of clean event data).

---

### A19. Consent Architecture 🟡

**Status**: `lib/services/user_consent_service.dart`, `lib/services/analytics_consent_manager.dart`, `lib/screens/consent_dialog_screen.dart` exist. No central consent contract.

**Why this is a topic**: Consent is currently fragmented (analytics consent, ATT, ad consent, training-data consent, photo-upload consent). Users see multiple dialogs; we have no unified record of "what is this user opted into?" Doesn't survive GDPR / DPDP audit.

**Key questions**:

- Single consent ledger per user, versioned.
- Granular vs blanket consent.
- Withdrawal mechanics — what happens when consent revoked mid-stream.
- Consent expiry / re-prompt cadence.

**Deliverable**: `docs/exploration/CONSENT_ARCHITECTURE.md`.

**Related**: Privacy / Photo PII (#32), Data Retention & PII (#14), Regional Regulations (#33), Analytics Schema Governance (A18).

---

## D — New Category: DISPOSAL FACILITIES & LOCAL KNOWLEDGE

A whole product surface absent from the first pass.

### A20. Disposal Facilities Directory 🟡

**Status**: `lib/screens/disposal_facilities_screen.dart`, `facility_detail_screen.dart`, `lib/models/disposal_location.dart`, `lib/services/local_guidelines_plugin.dart` exist. No exploration entry.

**Why this is a topic**: "What is this?" is half the user job. "Where do I take it?" is the other half — and is the bridge into Smart-Bin (#24) and Municipal APIs (#25). Today the directory exists but the data sourcing, freshness, and trust model don't.

**Key questions**:

- Source: crowdsourced / scraped / partner-supplied / hybrid?
- Verification — flag stale, closed, or wrong-info facilities.
- User contributions (A21) feed back into the directory.
- Offline cache for facility list.

**Deliverable**: `docs/exploration/DISPOSAL_FACILITIES_DIRECTORY.md`.

**Related**: Region-Aware Rulesets (#4), Smart-Bin (#24), Municipal APIs (#25), Informal Collector Network (#26).

---

### A21. User Contribution / UGC Pipeline 🟡

**Status**: `lib/screens/contribution_submission_screen.dart`, `contribution_history_screen.dart`, `lib/models/user_contribution.dart` exist. Distinct from community feed (#20).

**Why a separate topic from #20**: Community feed is *social*. Contributions are *data into the system* — new facility, corrected disposal advice, regional rule update, recycling code clarification. Different review pipeline, different incentive design, different trust model.

**Key questions**:

- Review pipeline — what's auto-accepted vs queued for moderator.
- Reputation system for repeat contributors.
- Tie to the rules corpus (entry #4) — a contribution that proposes a rule update.
- Incentive design — tokens? badges? recognition?

**Deliverable**: `docs/exploration/USER_CONTRIBUTION_UGC_PIPELINE.md`.

**Related**: Region-Aware Rulesets (#4), Disposal Facilities Directory (A20), Community Trust Layer (#20), Gamification Depth (#16).

---

### A22. Recycling Code Taxonomy 🟡

**Status**: `lib/models/recycling_code.dart` exists. No exploration entry.

**Why this is a topic**: Plastic recycling codes (resin identification codes #1–#7), paper / cardboard codes, electronics WEEE markings, glass colour codes — the **taxonomy** the app speaks is itself a research surface. Today it's implicit. As the rules corpus (#4) grows, the taxonomy is the join key.

**Key questions**:

- Which taxonomies are first-class (resin codes, GTIN, EU's upcoming DPP IDs, material categories)?
- Translation layer between user-facing language ("milk carton") and taxonomies ("polycoat #7").
- Versioning when an authority renames or restructures (e.g., EU code revisions).

**Deliverable**: `docs/exploration/RECYCLING_CODE_TAXONOMY.md`.

**Related**: Region-Aware Rulesets (#4), Disposal Reasoning Stage (#3), Industry Signal A24 (EU DPP).

---

## E — Industry Signals (Research Inputs, Not Code Surfaces)

These are external developments that shape the map's priorities. Track as research, not as build.

### A23. EU Digital Product Passport / ESPR — Industry Signal 🟡

**Why this matters**: The [Ecodesign for Sustainable Products Regulation (ESPR)](https://data.europa.eu/en/news-events/news/eus-digital-product-passport-advancing-transparency-and-sustainability) mandates Digital Product Passports (DPPs) carrying per-product disposal, material, and circularity data starting 2026 (iron/steel) and rolling through 2029 (mattresses/electronics). [Battery passports become mandatory Feb 2027](https://www.circularise.com/blogs/dpps-required-by-eu-legislation-across-sectors).

**Implication for this app**:

- DPPs are an *authoritative* data source for disposal advice — once products carry them, the app's region-aware rulesets (#4) become a *resolver*, not a primary data source. Architectural implication for entry #4.
- QR / NFC on DPP-carrying products becomes a scan modality that bypasses image classification entirely for in-scope products. New input class.
- Pilot opportunity: be one of the first consumer apps to *consume* DPPs at scale, not just produce them.

**Deliverable**: `docs/exploration/EU_DPP_ESPR_INTEGRATION.md` — track regulatory timeline, prototype DPP-resolver path, identify product categories where DPP becomes the better classification path than vision.

**Related**: Region-Aware Rulesets (#4), Disposal Reasoning Stage (#3), Recycling Code Taxonomy (A22), Smart-Bin (#24, sibling QR layer).

---

### A24. VLM-for-Waste Research Frontier — Industry Signal 🟢

**Why this matters**: A July 2025 paper ([Malla et al., Waste Management 204](https://www.sciencedirect.com/science/article/pii/S0956053X25003502)) shows targeted prompt engineering raises zero-shot VLM waste-classification accuracy by 9.4% to 90.48% — and full supervised fine-tuning to 97.18%. December 2025 [Novelis](https://novelis.io/research-lab/a-comparative-analysis-of-vision-language-models-for-scalable-waste-recognition/) and [MDPI Sensors 2025](https://www.mdpi.com/1424-8220/25/12/3807) work converges on the same finding: prompt + small-model selection beats heavy retraining for this domain.

**Implication**:

- Prompt-engineering-as-research is now a *measured* discipline for waste, not a vibes exercise. Eval Harness (#5) should be designed to surface prompt-version A/B results as a first-class artefact.
- Fine-tuned VLMs in the ~3B–8B class look viable for the on-device tier (#6) without giving up much accuracy.

**Deliverable**: lightweight `docs/exploration/VLM_WASTE_RESEARCH_TRACKER.md` — quarterly literature scan with claims-to-evidence map.

**Related**: Eval Harness (#5), Multi-Model AI Routing (#1), On-Device Inference (#6).

---

### A25. MRF-Side Competitors & B2B Reference Customers — Industry Signal 🟢

**Why this matters**: AMP Robotics ([$55M raise](https://novelis.io/research-lab/a-comparative-analysis-of-vision-language-models-for-scalable-waste-recognition/)), Greyparrot, Recycleye, TOMRA — companies doing vision-based sorting at material recovery facility scale. They define the *upper bound* of what computer-vision-for-waste can mean, and they are *exactly* the kind of customer for the brand / manufacturer data flywheel (frontier F8) and B2B wedge (#29).

**Implication**:

- The consumer app's classification quality benchmark should be the published accuracy claims of these MRF systems (industry-defensible reference).
- Their *failures* (what they can't sort yet) is the most valuable open-research problem and a possible wedge.
- B2B path: become the *consumer-side data partner* to one of these MRF networks.

**Deliverable**: lightweight `docs/exploration/INDUSTRY_COMPETITIVE_LANDSCAPE.md` — annual refresh, claims-to-evidence map, partnership leads.

**Related**: B2B / Enterprise Wedge (#29), F8 Brand / Manufacturer Closed-Loop Data, Distribution & Partnerships (#31).

---

## F — New Category: LOCALITY & CIVIC WASTE INTELLIGENCE

Added 2026-05-20. Long-horizon exploration theme: locality-aware collection data, map-based civic reporting, Waze-style verification, civic-grade trust/reputation (separate from AI tokens), and authority/B2B/B2G dashboards. **Research lane only — not P0.** Canonical track doc: [review/EXPLORATION_AND_RESEARCH_BACKLOG_2026-05-20.md](review/EXPLORATION_AND_RESEARCH_BACKLOG_2026-05-20.md). Entries below are cursors into that doc; the source there wins.

### L1. Locality Collection Data 🟢

**Status**: Seed (2026-05-20). Extends A20 (Disposal Facilities Directory) and `planning/local_recycling_directory.md`. No current code surface for schedules.

**Why this is a topic**: The directory already answers "where do I take it?". The complementary half — "when does collection come to me, and what does it pick up?" — is unbuilt. Schedule + route + disruption data is the lowest-risk wedge in the civic track because it can ship as read-only display before any UGC moderation foundation exists.

**Key questions**:

- Is BBMP / municipal collection schedule data legally republishable?
- Public collector contact info vs personal phone numbers — where is the line?
- MVP sourcing: scrape vs partner vs user-contribution vs hybrid?

**Deliverable**: `docs/exploration/LOCALITY_COLLECTION_DATA.md` (assigned to agent task **Civic-A** in the canonical track doc).

**Related**: A20 Disposal Facilities Directory, #25 Municipal APIs (BBMP), #26 Informal Collector Network, #4 Region-Aware Rulesets.

---

### L2. Map-Based Civic Issue Reporting 🟢

**Status**: Seed (2026-05-20). Builds on A21 (UGC Pipeline) and the existing map stack already in `pubspec.yaml` (`flutter_map`, `flutter_map_marker_cluster`, `flutter_map_heatmap`, `geoflutterfire_plus`, `flutter_map_tile_caching`).

**Why this is a topic**: Civic reporting (missed pickup, illegal dumping, overflowing bin, etc.) is a natural product extension but a moderation-cost minefield. Must launch as pilot-scope only (one apartment, school, or ward) and never public until #32 + #23 have a foundation.

**Key questions**:

- Canonical issue-type enum and lifecycle state machine.
- Pilot-scope gating vs public surface — what changes between them?
- Duplicate detection (proximity + kind + time window).

**Deliverable**: `docs/exploration/CIVIC_ISSUE_REPORTING_SPEC.md` (agent task **Civic-B**).

**Related**: A21 UGC Pipeline, #20 Community Trust, #23 Moderation & Safety, #32 Privacy / Photo PII.

---

### L3. Waze-Style "Still There?" Verification Loop 🟢

**Status**: Seed (2026-05-20). New surface; no current code.

**Why this is a topic**: A geo-tagged civic issue without a freshness signal becomes a stale-pin graveyard. The Waze "is this roadblock still there?" pattern is the proven lightweight verification mechanism. Trust-weighted aggregation + time decay determines whether an issue is still worth surfacing.

**Key questions**:

- Proximity trigger threshold; per-user / per-day prompt caps to avoid notification fatigue and farming.
- Confidence formula combining response counts, trust tiers, and time decay.
- Anti-spam attacks the loop must defeat (drive-by spam, coordinated farming).

**Deliverable**: `docs/exploration/CIVIC_TRUST_AND_VERIFICATION.md` (agent task **Civic-C** — combined with L4).

**Related**: L2, L4, #20 Community Trust, A11 Notification Strategy.

---

### L4. Civic Reputation & Points (Separate from AI Tokens) 🟢

**Status**: Seed (2026-05-20). **Hard constraint: civic reputation must NOT merge into the AI-token ledger.**

**Why this is a topic**: Rewarding civic contributions is necessary for the verification loop to work, but if civic actions earn paid AI tokens, the entire token economy (#27a, `TOKEN_ECONOMY_TODO.md`) becomes farmable through spam reports. A separate `civic_reputation` ledger with no minting path into `tokens` is non-negotiable.

**Key questions**:

- Tier definitions, promotion/demotion rules.
- Earn / penalty event taxonomy.
- Code-level enforcement of separation (separate tables, separate services, audit-grep gate).

**Deliverable**: covered in `docs/exploration/CIVIC_TRUST_AND_VERIFICATION.md` (agent task **Civic-C**) with explicit separation contract reviewed against `TOKEN_ECONOMY_TODO.md`.

**Related**: #27a Token Economy & Pricing Coherence (separation contract), #16 Gamification Depth (avoid double-counting), L2, L3.

---

### L5. Authority / NGO / Apartment Sharing & B2B/B2G Validation 🟢

**Status**: Seed (2026-05-20). Builds on #25 (Municipal APIs) and #29 (B2B / Enterprise Wedge); does not replace their ranking.

**Why this is a topic**: The civic data layer only earns its keep if some buyer pays for it. The product surface (WhatsApp report card → email → PDF → CSV → dashboard) and the buyer hypothesis (apartment association, school, NGO, CSR sponsor, municipality, contractor, recycling partner) need to be designed together — and a first paid pilot needs to close within 6 months or the track de-prioritises.

**Key questions**:

- Which buyer has the highest paid-pilot probability within 6 months?
- Report card and local-language complaint generation (Kannada / Hindi / English).
- Where does this extend #29 and where does it contradict — and why?

**Deliverables**:

- `docs/exploration/CIVIC_AUTHORITY_SHARING.md` (agent task **Civic-D**) — sharing UX.
- `docs/exploration/CIVIC_B2B_B2G_VALIDATION.md` (agent task **Civic-F**) — buyer matrix + first paid pilot hypothesis.

**Related**: #25 Municipal APIs (BBMP), #29 B2B / Enterprise Wedge, #28 Monetization & Pricing Tiers, #31 Distribution & Partnerships.

---

### L6. Civic Privacy, Safety & Moderation Foundation 🔴

**Status**: Seed (2026-05-20). **Gates every other L-entry that touches a public surface.** Inherits from #32, #23, #33, A14, A19.

**Why this is a topic**: Civic photos can contain faces, license plates, children, and homes. Civic reports can defame workers, harass contractors, or map unsafe neighbourhoods. False reports can cause real-world harm. Until on-device blur, EXIF strip, coarse-public-location publication, exact-authority-only ACL, takedown SLA, and abuse-report flow are designed, no L-entry ships beyond pilot scope.

**Key questions**:

- On-device face / license-plate blur — feasible on current minimum target device?
- Two-fidelity coordinate model (`coords_public` coarse vs `coords_exact` ACL-gated) — schema-level enforcement.
- Moderation cost per 1k reports; bandwidth ceiling for the current team.

**Deliverable**: `docs/exploration/CIVIC_PRIVACY_SAFETY_REVIEW.md` (agent task **Civic-E**).

**Related**: #32 Privacy / Photo PII, #23 Moderation & Safety, #33 Regional Regulations, A14 Launch & Store Compliance, A19 Consent Architecture.

---

## Provenance & Sources

- **Code scan**: 73 services, 42 screens, 33 models, 14 providers in `lib/`. Notably new vs first pass: `image_quality_gate.dart`, `model_download_service.dart`, `on_device_vision_service.dart`, `object_detection_service.dart`, `ab_testing_config.dart`, `remote_config_service.dart`, `dynamic_link_service.dart`, `ad_service.dart`, `smart_suggestions_service.dart`, `local_guidelines_plugin.dart`, `analytics_schema_validator.dart`, `user_consent_service.dart`, `disposal_location.dart`, `recycling_code.dart`, `user_contribution.dart`, `ai_failure.dart`, `fresh_start_service.dart`, `firebase_cleanup_service.dart`.
- **Docs scan**: `docs/admin/` (5 docs), `docs/analytics/` (5 docs), `docs/launch/` (2 docs), `docs/security/` (3 docs), `docs/technical/`, `docs/processes/`, `IOS_ANDROID_PARITY.md`, `AI_API_RACE_FAULT_TOLERANCE.md`, `QUALITY_GATE_OFFLINE_QUEUE_INTEGRATION.md`, `TRACK_1_2_CAPTURE_FLOW_INTEGRATION.md`, `WORKLOG_ADDENDUM_SAST_20260312.md`, `planning/account_reset_and_delete_specification.md`, `planning/app_store_publication_p0_features.md`.
- **Industry literature pass (2025–2026)**:
  - [EU's Digital Product Passport — data.europa.eu](https://data.europa.eu/en/news-events/news/eus-digital-product-passport-advancing-transparency-and-sustainability)
  - [DPPs across EU sectors — Circularise](https://www.circularise.com/blogs/dpps-required-by-eu-legislation-across-sectors)
  - [DPP compliance 2026 — Climatiq](https://www.climatiq.io/blog/digital-product-passports-what-you-need-to-know-to-be-ready-for-regulatory-compliance-in-2025)
  - [VLM waste recognition — Malla et al., Waste Management, Aug 2025](https://www.sciencedirect.com/science/article/pii/S0956053X25003502)
  - [VLM waste recognition comparative — Novelis, Dec 2025](https://novelis.io/research-lab/a-comparative-analysis-of-vision-language-models-for-scalable-waste-recognition/)
  - [AI for sustainable recycling — MDPI Sensors 2025](https://www.mdpi.com/1424-8220/25/12/3807)
- **Reading rule**: when any of the above source artefacts disagrees with this index, **the source wins**. Update the index, don't fork.
