# Exploration Topics — Master Index

**Purpose**: Living document tracking research areas for the ReLoop
**Status**: Active — continuously updated as the project evolves
**Last Updated**: 2026-05-25
**Sibling docs**:
- [EXPLORATION_FRONTIER.md](EXPLORATION_FRONTIER.md) — high-ambition / "boil the ocean" frontier bets
- [EXPLORATION_ROADMAP_WHILE_BUILDING.md](EXPLORATION_ROADMAP_WHILE_BUILDING.md) — what to explore in parallel with shipping
- [exploration/](exploration/) — per-topic detailed exploration docs
- [exploration/backlog.md](exploration/backlog.md) — raw, append-only idea backlog
- [exploration/ARCHIVE.md](exploration/ARCHIVE.md) — `[KILLED]` and `[✓]` topics moved out of the active index
- [brainstorm_exploration_map_2026-05-19.md](brainstorm_exploration_map_2026-05-19.md) — wide-open-brainstorm pressure test of this map
- [review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md](review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md) — 4-layer local-first cascade architecture roadmap (source for entries G1–G6)

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
- Why each area matters for the ReLoop specifically
- Current status and owner (where known)
- Links to detailed research docs under `docs/exploration/`

**For deep research**, each topic should have (or grow) its own document under `docs/exploration/`:

- `docs/exploration/MULTI_MODEL_AI_ROUTING.md`
- `docs/exploration/ON_DEVICE_INFERENCE.md`
- `docs/exploration/SMART_BIN_INTEGRATION.md`
- etc.

**Status markers are not a close signal**: A topic marked `[✓]` (complete), `[🟡]` (medium priority), or `[🟢]` (low priority/frontier) is **always open for further deep dives**. Status only reflects current urgency or delivery state — not that the topic is settled. Any agent or contributor can re-open any entry for deeper exploration if new information, changed context, or fresh questions justify it. Document your findings, update the status, and link back.

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
│  ├── Multi-Model AI Stack         [🔴]        ├── Model Cascades        [🟡] │
│  ├── Classification Confidence    [🟡]        ├── Battery / Thermal      [🟢] │
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
│  │   └── Family Dashboard UI      [🟡]        │                                 │
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
│  LOCAL-FIRST AI ARCHITECTURE (added 2026-05-21)                              │
│  ├── Deterministic Pre-processing Classifier [🔴] (G1)                       │
│  ├── Local-First Privacy Architecture        [🔴] (G2)                       │
│  ├── Confidence Threshold Tuning             [🟡] (G3)                       │
│  ├── Backend Classification Proxy            [🔴] (G4)                       │
│  ├── Batch Classification & Background       [🟢] (G5)                       │
│  └── Offline Degradation UX                  [🟡] (G6)                       │
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

### 1a. Multi-Model AI Stack for the Product Loop 🔴 [SEED]

**Status**: Added 2026-05-21 — deferred roadmap exploration for later work.

**Overview**: Treat classification as a stack, not one model. The stack should orchestrate:

- capture pre-checks (quality/PII),
- per-object vision understanding (detection/segmentation),
- material/category classification,
- regional disposal policy application,
- user correction intake,
- evaluation + data-quality gating,
- model routing and active-learning loops.

This explicitly decouples "understanding the image" from "telling the user what to do."

**Decision it unblocks**: Long-term move from single-cloud dependency toward local-first + escalation-first classification with measurable accuracy/cost gains.

**Key questions**:

- Which stages can be deterministic, and which require learned models?
- What privacy gate is required before any image enters training/eval pools?
- How do we combine duplicate detection, image quality, confidence, and policy risk to route each image?
- Which models are highest leverage for phase 1–2 rollout: quality, duplicate, simple material/category?
- What are the minimal golden/eval definitions before any model upgrade is accepted?
- How do we version model-stack outputs for auditability (component outputs + route + ruleset version)?

**What this lane includes**:

- Waste image classifier (category/material prediction + confidence).
- Multi-object detection and segmentation for cluttered scenes.
- Image-quality precheck (blur, darkness, glare, framing, distance, obstructions).
- Privacy/PII risk scoring (faces, addresses, prescriptions, licenses, etc.).
- Duplicate and near-duplicate suppression (hash + embedding similarity).
- Confidence calibration and explicit `needsReview` states.
- Model router/escalation policy (cache, local, cloud tiering, manual review).
- Region-aware disposal recommendation model (policy-assisted, not policy-decider).
- OCR / label-text extraction and barcode-assisted classification.
- Active learning and correction-question strategy.
- Training-data quality scoring for dataset admission.
- Golden eval dataset and safety-focused evaluation.
- Personalised education, habit, and anti-abuse recommendations.
- On-device start-path (quality + duplicate + simple categories), then expansion to harder cases.

**Preferred sequencing (for later execution)**:

1. Data foundation: consent, correction capture, dataset schema/versioning, redaction, eval harness.
2. Routing readiness: quality + duplicate + calibration + provider-cost routing.
3. Small classifiers: wet/dry/hazardous/e-waste + material family.
4. Advanced CV: detection + segmentation + OCR/barcode-assisted classification.
5. Product intelligence: personalization, abuse detection, retention nudges.

**Kill criteria**:

- No measurable eval improvement after 2–3 controlled routing experiments.
- Privacy risk cannot be reduced to deterministic policy + reviewer workflow.
- Data capture cost exceeds gains without clear moat gain (regional rules, corrections, eval coverage).

**Deliverable**:
- `docs/exploration/MULTI_MODEL_AI_STACK.md` with model-by-model scope, required labels, routing policy, and phase gates.
- `docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md` with input/output contracts and telemetry for each model lane.
- `docs/exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md` for a concrete phase-1 backlog, acceptance criteria, and sequencing.
- `docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md` for consent, redaction, and training/eval-data gate requirements.

**Related**: On-Device Inference, Eval Harness, AI Cost Telemetry, Privacy / Photo PII, Data Retention & PII Strategy.

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

**Status**: Implementation delivered 2026-05-22. 7 city plugins live, `CityPolicyData` helper, `safetyOverride` check type, confidence gating, society override model, and city research playbook all built.

**Overview**: India-first (BBMP), with global ambitions. The "right answer" depends on city/municipality/building rules. The app now has seven city plugins (BBMP production, BMC/MCD/PMC/GHMC/GCC/KMC pilot), a data-driven `CityPolicyData` helper that reduces new-city cost to data + tests, a `safetyOverrideAlways` check type for safety-critical rules, confidence gating that demotes enforcement when ML confidence is low, and a `SocietyPolicyOverride` model for apartment-society-level rule deltas.

**Code anchors**:
- `lib/services/city_policy_data.dart` — data-driven city config with pre-built instances for 7 cities
- `lib/services/local_policy_engine.dart` — `safetyOverrideAlways` check type, confidence gating, provenance fields
- `lib/services/local_guidelines_plugin.dart` — refactored BBMP retains custom compliance; all other cities use `CityDataPluginMixin`
- `lib/services/local_policy_rule_packs.dart` — 7 city rule packs with safety override rules
- `lib/models/society_policy_override.dart` — society-level override model with Firestore-ready serialization

**Key questions**:
- All answered; focus shifted to execution.
- Answered: minimum data contract, society interaction, ML confidence gating.

**Deliverable**: `docs/exploration/REGION_RULES_AND_CITY_EXPANSION_MAP.md` (2026-05-22).

**Related**: Disposal Reasoning Stage, Smart-Bin Integration, Municipal APIs, Global Municipal Policy Engine (#4a), Locality & Civic Waste Intelligence (Section F).

---

### 4a. Global Municipal Policy Engine 🔴

**Status**: Active build track (2026-05-20 onward). 7 cities live, data-driven plugin architecture shipped.

**Overview**: Policy correctness must scale beyond one city. The canonical policy engine + rule-pack registry surface is now augmented with a `CityPolicyData` helper that makes adding a new city a data-entry-plus-tests exercise. Seven cities are live (BBMP production, BMC/MCD/PMC/GHMC/GCC/KMC pilot). `safetyOverrideAlways` check type ensures deterministic safety-critical rules. Confidence gating prevents strong enforcement when ML confidence is low.

**Key questions**:

- Answered: plugin contract, minimum fields, promotion gates, rollout strategy.
- Open: source freshness monitoring (design concept documented in `docs/exploration/SOURCE_FRESHNESS_MONITORING.md`).
- Open: GPS region selection UX (design concept in `docs/exploration/GPS_REGION_SELECTION_UX.md`).

**Current code anchors**:

- `lib/services/local_policy_engine.dart` — policy evaluation with `safetyOverrideAlways`, confidence gating, provenance fields
- `lib/services/local_policy_rule_packs.dart` — 7 city rule packs (BBMP production, 6 pilot)
- `lib/services/local_guidelines_plugin.dart` — 7 city plugins via `CityDataPluginMixin`
- `lib/services/city_policy_data.dart` — data-driven city config helper with 7 pre-built instances
- `lib/models/society_policy_override.dart` — society-level override delta layer

**Deliverables**:
- `docs/exploration/GLOBAL_MUNICIPAL_POLICY_ENGINE.md` (2026-05-21)
- `docs/exploration/REGION_RULES_AND_CITY_EXPANSION_MAP.md` (2026-05-22)
- `docs/playbooks/CITY_RULES_RESEARCH.md` (2026-05-22) — playbook for researching new cities
- `docs/exploration/SOURCE_FRESHNESS_MONITORING.md` (2026-05-22) — design concept
- `docs/exploration/GPS_REGION_SELECTION_UX.md` (2026-05-22) — design concept

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

### 6. On-Device Inference 🟡

**Status**: Phase A+B implemented. `LocalClassifier` interface, `ClassificationPipeline` orchestrating L0→L1→Cloud, `classificationLayer` field on `WasteClassification`, 36 tests. Real on-device ML model (Phase C) deferred — no TFLite model trained yet.

**Overview**: On-device inference unlocks offline use, privacy, faster perceived latency, and lower per-classification cost. Critical for emerging markets and as a competitive moat.

**Key questions**:

- Which Flutter-compatible runtimes work in practice (TFLite, MLC LLM, llama.cpp, MediaPipe, Apple Core ML, Android NNAPI)?
- What's the smallest model that solves the *common* case (single, well-lit, single-object scan) with acceptable quality?
- How do we ship model weights — bundled, lazy-downloaded, gated by device tier?
- What's the iOS/Android parity story given Apple Silicon vs Snapdragon NPU differences?

**Deliverable**: `docs/review/LOCAL_ML_FIRST_PASS_CLASSIFIER_PLAN_2026-05-21.md` (Phase A+B complete). `lib/services/local_classifier_service.dart`, `lib/services/classification_pipeline.dart`, `lib/providers/classification_pipeline_providers.dart`.

**Related**: Multi-Model AI Routing, Model Cascades, Battery / Thermal.

---

### 7. Model Cascades 🟢

**Status**: Implemented. `ClassificationPipeline` (L0 deterministic → L1 on-device ML → Cloud) is the cascade. Escalation policy defined in `LocalClassificationResult.requiresEscalation`: 5 conditions (infra failure, model-flagged, always-escalate categories, safety-sensitive below 0.90, non-safety below 0.75).

**Overview**: A small on-device classifier handles "easy" cases; ambiguous results escalate to cloud. Should be deterministic and observable, not magic.

**Key questions**:

- What features drive escalation: confidence, entropy, scene complexity, user override history?
- How do we audit each escalation so we can tune the threshold?
- Does the cascade also include "ask the user a question" as a tier (active clarification)?

**Deliverable**: `lib/services/classification_pipeline.dart`, `lib/services/local_classifier_service.dart` (escalation logic in `LocalClassificationResult.requiresEscalation`).

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

**Related**: A20 Disposal Facilities Directory, #25 Municipal APIs (BBMP), #26 Informal Collector Network, #4 Region-Aware Rulesets, `docs/exploration/REGION_RULES_AND_CITY_EXPANSION_MAP.md`.

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

---

## G — New Category: LOCAL-FIRST AI ARCHITECTURE

Added 2026-05-21. These topics were surfaced by the Local-First VLM AI Roadmap session (see `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md`). They fill a gap in the first two passes: the cascade routing architecture, deterministic pre-processing, and the privacy/cost implications of layer selection were not individually tracked. None of these duplicate existing entries.

### G1. Deterministic Pre-processing Classifier 🔴

**Category**: AI & Vision / On-Device & Edge (Layer 0 of the local-first cascade)

**Status**: Not implemented. Barcode scanner (`mobile_scanner`) is in `pubspec.yaml` but disabled (line 58, dependency conflict). No color histogram path exists. No `DeterministicClassifier` service exists.

**Overview**: A zero-AI layer that handles items deterministically before any model inference. Two sub-paths:

1. **Barcode scan → product DB lookup**: scan the item's barcode or QR code, look up the product in a database (Open Food Facts API, local product DB, or EU DPP resolver), and return instant classification with zero AI cost. No model needed. High precision for labelled consumer products.

2. **Color histogram → broad category**: compute an HSV histogram on the image to classify items with visually unambiguous color profiles (clearly organic, clearly plastic bottle, clearly newspaper). Fast, runs in-process, zero network cost.

**Expected coverage**: ~30–40% of real-world single-item scans handled at this layer before any model is invoked.

**Why this is a topic, not just a task**: The decision of what qualifies as "high enough confidence for deterministic classification" is a research question. The threshold for barcode coverage and the histogram bucket boundaries require experimentation with real waste image data and the Eval Harness (#5).

**Key questions**:
- Which product DB to use: Open Food Facts (free, ~3M products, network) vs custom local DB (offline, maintenance cost) vs EU DPP resolver (emerging, ESPR mandate 2026+)?
- Histogram bucket design: how many categories, what color ranges, how to handle mixed-material items?
- What's the correct confidence pass threshold for Layer 0 (proposed: >= 0.90)?
- How does Layer 0 interact with barcode detection for partially-visible/blurry barcodes?

**Implementation path**: `lib/services/deterministic_classifier.dart` → new `ClassificationRouter` service → wire before `AiService._analyzeWithOpenAI()` call.

**Deliverable**: `docs/exploration/DETERMINISTIC_CLASSIFIER.md`

**Related**: Multi-Model AI Routing (#1), Confidence Threshold Tuning (G3), On-Device Inference (#6), Eval Harness (#5), A23 (EU DPP — future product DB data source).

---

### G2. Local-First Privacy Architecture 🔴

**Category**: AI & Vision / Compliance & Trust (cross-cutting)

**Status**: Not formalised. The app transmits every classification image to OpenAI or Gemini (cloud providers) today. On-device capability exists as a placeholder (`on_device_vision_service.dart`) but is not production-ready. No explicit user-facing privacy policy exists for "which layers transmit your image."

**Overview**: The 4-layer cascade (see `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md`) creates a privacy-by-design architecture:
- **Layer 0 (deterministic) + Layer 1 (on-device VLM)**: zero image transmission — no third-party sees the image.
- **Layer 2 + Layer 3 (cloud VLMs)**: image bytes transmitted to OpenAI or Google.
- **Layer 4 (disposal reasoning)**: text-only transmitted to Firebase backend, which calls OpenAI text API.

The routing policy determines privacy by determining which layer handles each item. A privacy-conscious user should be able to opt into "local-only" mode (Layer 0 + Layer 1 only, refuse to escalate to cloud). This is a strong differentiator for schools, corporate BYOD environments, and GDPR-sensitive jurisdictions.

**Key questions**:
- Should "local-only" mode be a user setting, a premium feature, or a default for certain personas (kid mode, classroom mode)?
- When the user is in local-only mode and Layer 1 can't achieve confidence, what do we show? ("This item couldn't be identified offline. Enable cloud analysis for more accurate results.")
- Consent flow: before any Layer 2/3 call, does the user need a per-session or per-item consent prompt, or is the privacy policy sufficient?
- How do we surface the per-classification privacy signal ("analysed on device" vs "analysed in cloud") in the result screen?

**Current blocker**: no on-device Layer 1 means there is no privacy-preserving fallback today. The privacy architecture is not buildable until Layer 1 is live (see On-Device Inference, entry #6, and G1).

**Deliverable**: `docs/exploration/LOCAL_FIRST_PRIVACY_ARCHITECTURE.md` — routing policy, consent contract, UX surface for privacy signal, per-layer data-flow diagram.

**Related**: On-Device Inference (#6), G1 (Deterministic Classifier), Privacy / Photo PII (#32), Data Retention & PII (#14), Consent Architecture (A19), Regional Regulations (#33).

---

### G3. Confidence Threshold Tuning 🟡

**Category**: AI & Vision (cross-cutting — affects all four cascade layers)

**Status**: Confidence field exists (`WasteClassification.confidence`, `waste_classification.dart:377`). `VisionModelConfig.confidenceThreshold = 0.7` (default, `vision_model_config.dart:62`). No routing logic reads this field to escalate between layers. No calibration methodology exists.

**Overview**: The 4-layer cascade relies on per-layer confidence thresholds to decide when to escalate. These thresholds are not single constants — they are policy decisions that trade off cost, accuracy, latency, and user experience. A miscalibrated threshold causes silent accuracy loss (too permissive) or unnecessary cost (too conservative).

Current model self-reported confidence is an uncalibrated signal — the model's JSON output `confidence: 0.87` does not reliably mean the result is correct 87% of the time. Calibration (temperature scaling, Platt scaling, or empirical lookup tables from the eval harness) is required before the thresholds are trustworthy.

**Proposed starting thresholds** (hypotheses, not calibrated values):
- Layer 0 pass: >= 0.90
- Layer 1 pass: >= 0.75
- Layer 2 pass: >= 0.60
- Layer 3: always accept (no further escalation)
- Category override: Hazardous/Medical always escalate to Layer 3 regardless of confidence

**Key questions**:
- Which calibration methodology fits the available eval infrastructure? (Platt scaling needs held-out data; empirical binning is simpler but needs more samples.)
- How do we handle per-category thresholds? (Plastic bottles may need lower thresholds than medical waste.)
- When should we prefer "low confidence result + clarification prompt to user" over "escalate to next layer"? (User clarification is cheaper than a cloud API call but worse UX.)
- How do we track threshold drift over time as provider model versions change?

**Deliverable**: `docs/exploration/CONFIDENCE_THRESHOLD_TUNING.md` — calibration methodology, starting threshold table, per-category overrides, drift monitoring approach.

**Related**: Eval Harness & Golden Sets (#5), Multi-Model AI Routing (#1), Classification Confidence (#2), G1 (Deterministic Classifier), On-Device Inference (#6).

---

### G4. Backend Classification Proxy 🔴

**Category**: AI & Vision / Data, Cost & Reliability

**Status**: Not implemented. `generateDisposal` Firebase Function (`functions/src/index.ts:207`) exists as a backend proxy for disposal reasoning (Layer 4). No equivalent `classifyImage` function exists — classification currently calls OpenAI/Gemini directly from the client. `ProductionSafetyConfig.guardClientAiCall` blocks this in release builds, but the right fix is a backend proxy, not just a guard.

**Overview**: A `classifyImage` Firebase HTTP Function that acts as the gateway between the Flutter client and cloud AI providers for Layers 2 and 3. All client-to-provider image classification traffic flows through this function.

**Why this is P0 before any other cloud classification change**:
1. **Cost integrity**: client-side `ai_cost_tracker.dart` is tamper-susceptible (the client reports costs to Firestore, but there is no server-side enforcement). A backend proxy records actual provider costs server-side.
2. **App Check enforcement**: `generateDisposal` already enforces App Check (`shouldEnforceHttpAppCheck()`). `classifyImage` should be identical. Without it, unauthenticated clients can drain AI budget.
3. **Provider swap without app release**: if we need to switch from OpenAI to Gemini or add a new provider, we update one Firebase Function, not release a new app.
4. **Key security**: API keys for OpenAI/Gemini do not need to be distributed in the app binary. They live only in Firebase environment config.

**Key questions**:
- Request body: pass raw image bytes (base64) or a Cloud Storage object URL? Firebase Functions have a 32MB request body limit — large images need Storage URL approach.
- Auth contract: require Firebase ID token (Bearer) and App Check token, same pattern as `generateDisposal`.
- Rate limiting: per-user classification rate limit, same pattern as the existing `enforceRateLimit` in `functions/src/index.ts`.
- Error contract: how does the proxy signal Layer 2 vs Layer 3 escalation to the client?

**Implementation path**: Add `classifyImage` to `functions/src/index.ts`. Follow the `generateDisposal` pattern for auth, App Check, rate limiting, and Firestore cost recording. Update `AiService._analyzeWithOpenAI()` and `._analyzeWithGemini()` to call the proxy in release builds.

**Deliverable**: `docs/exploration/BACKEND_CLASSIFICATION_PROXY.md`

**Related**: Multi-Model AI Routing (#1), AI Cost Telemetry & Guardrails (#10), Privacy / Photo PII (#32), App Check integration (`APPCHECK_RATE_LIMIT_IMPLEMENTATION_PACKET_2026-05-21.md`).

---

### G5. Batch Classification and Background Processing 🟢

**Category**: AI & Vision / Data, Cost & Reliability

**Status**: Batch mode concept exists in `VisionModelConfig.AnalysisMode.batch` and in `CostGuardrailService.isBatchModeEnforced`. No implementation of background classification or pre-warming cache exists.

**Overview**: Two complementary ideas:

1. **Batch classification**: classify multiple images in one API call (or queue them for off-peak processing). Relevant for users who scan many items quickly. OpenAI Batch API offers 50% cost reduction at the cost of up to 24h latency.

2. **Background processing**: when the device is charging and on Wi-Fi, process recently captured but unclassified images, pre-warm the disposal cache for likely follow-up queries, and download model updates for Layer 1.

**Key questions**:
- Which UX pattern for batch: explicit "analyze later" queue, or automatic background when conditions are met?
- OpenAI Batch API: 24h turnaround — acceptable for which use cases? (Historical review, impact stats — yes. Real-time scan — no.)
- Cache pre-warming: if the user recently classified "plastic bottle", pre-fetch `generateDisposal` for the top-N predicted next items. Does this reduce meaningful latency?
- Background task management: `WorkManager` on Android, `BackgroundFetch` on iOS — already in the project?

**Deliverable**: [`docs/exploration/BATCH_CLASSIFICATION_AND_BACKGROUND.md`](exploration/BATCH_CLASSIFICATION_AND_BACKGROUND.md) — exploration doc with batch API cost analysis, background processing triggers, UX pattern options.

**Related**: AI Cost Telemetry & Guardrails (#10), Token Economy (#27a), Offline Queue & Sync (#11), On-Device Inference (#6).

---

### G6. Offline Degradation UX ✅

**Category**: UX & Engagement / On-Device & Edge

**Status**: Complete — Tier 2 fully implemented. `OfflineDegradationTier` enum, `OfflineResultBanner` widget, `tryLocalWithHint()` pipeline method, `isOfflineHint` field on WasteClassification, result screen banner integration, hint reconciliation in offline queue processor. Plan archived at `docs/planning/G6_OFFLINE_DEGRADATION_UX_PLAN.md`.

**Overview**: There are three distinct offline states with different UX needs:

1. **Layer 0 + Layer 1 available (target state after Phase 3)**: full offline classification. User sees normal result. No special UX needed.

2. **Only Layer 0 available (model not downloaded yet)**: deterministic classification for clear items; complex items get queued. User sees a partial result with a note: "More detail available when connected."

3. **Neither Layer 0 nor Layer 1 available (first launch, no Wi-Fi)**: no local inference possible. User sees "Photo saved — will be analysed when connected." Option to queue.

The current app does not distinguish these states. An offline user who opens the app gets an error experience rather than a graceful degraded experience.

**Key questions**:
- When should the app proactively offer to download the Layer 1 model? (On Wi-Fi, on first launch, or only when the user explicitly requests it?)
- How do we handle items that are queued for later analysis when the user is in a hurry? (Show a cached "likely" result from similar items? Show nothing?)
- What's the UX for the "offline history" — items captured but not yet analysed? Should they have a distinct visual treatment in the history list?
- How do we communicate the privacy benefit of offline mode without making it sound like the app is broken?

**Deliverable**: `docs/exploration/OFFLINE_DEGRADATION_UX.md` — state machine for offline states, UX copy for each state, triggering conditions for model download prompts.

**Related**: Offline-First Flow (#9), On-Device Inference (#6), G1 (Deterministic Classifier), G2 (Local-First Privacy Architecture), Onboarding & Activation (#19).

---


## Exploration Docs Added (2026-05-23)

All NOW-phase and NEXT-phase exploration docs completed:

| Doc | Track | Status |
|-----|-------|--------|
| [AI Cost Telemetry & Guardrails](exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md) | N1 | Complete — cost model, gaps, per-tier caps |
| [Offline Queue & Sync Contract](exploration/OFFLINE_QUEUE_AND_SYNC.md) | N2 | Complete — contract, gaps, 6 acceptance tests |
| [Privacy / Photo PII](exploration/PRIVACY_PHOTO_PII.md) | N3 | Complete — gap analysis, remediation plan |
| [Data Retention & PII Strategy](exploration/DATA_RETENTION_AND_PII_STRATEGY.md) | N3 | Complete — retention policies, PII inventory |
| [Onboarding & Activation](exploration/ONBOARDING_AND_ACTIVATION.md) | N4 | Complete — funnel analysis, onboarding flow |
| [Moderation & Safety](exploration/MODERATION_AND_SAFETY.md) | N5 | Complete — 3-tier moderation, trust scoring |
| [Token Economy & Pricing Coherence](exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) | N6 | Complete — synthesis of 9 brainstorms, phased rollout |
| [Multi-Model AI Routing](exploration/MULTI_MODEL_AI_ROUTING.md) | X2 | Complete — 4-layer cascade, adaptive routing |
| [Gamification Depth](exploration/GAMIFICATION_DEPTH.md) | X4 | Complete — v2 quality-based points + [redesign spec](planning/gamification-redesign-spec.md) with adaptive engine, challenges, points sinks, achievement tiers, and phased rollout plan |
| [Habit Formation Loop](exploration/HABIT_FORMATION_LOOP.md) | X4 | Complete — Hook model, progressive disclosure |
| [Firestore Cost & Indexing](exploration/FIRESTORE_COST_AND_INDEXING.md) | X5 | Complete — per-MAU cost model, optimization |
| [Classification History Schema](exploration/CLASSIFICATION_HISTORY_SCHEMA.md) | X5 | Complete — v2 schema, indexes, dedup |
| [Local-First Privacy Architecture](exploration/LOCAL_FIRST_PRIVACY_ARCHITECTURE.md) | G2 | Complete — privacy by layer, consent flow |
| [Confidence Threshold Tuning](exploration/CONFIDENCE_THRESHOLD_TUNING.md) | G3 | Complete — calibration methodology, per-category overrides |
| [Motivation Archetypes](exploration/MOTIVATION_ARCHETYPES.md) | X4 (adaptive gamification) | Complete — 5-archetype model, detection signals, industry research, ethical guardrails |
| [Points Economy v2](exploration/POINTS_ECONOMY_V2.md) | X4 (adaptive gamification) | Complete — earn rates, dual-currency research, sink design, inflation modelling, monitoring |
| [Negative Mechanics A/B](exploration/NEGATIVE_MECHANICS_AB.md) | X4 (adaptive gamification) | Complete — industry evidence, ethical guardrails, experiment design, sample size, kill criteria |
| [AI Service Refactoring (motto_v2)](exploration/AI_SERVICE_REFACTORING_MOTTO_V2.md) | N1 (engineering foundations) | Complete — god-class decomposition, separation of concerns, clean architecture plan |
| [Post-MVP Roadmap (Points, Challenges, Community)](exploration/POST_MVP_ROADMAP_POINTS_CHALLENGES_COMMUNITY.md) | X4 (adaptive gamification) | Complete — Duolingo/Habitica/Strava sequencing analysis, dependency ordering, phase plan |
| [Onboarding Re-exploration](exploration/ONBOARDING_REEXPLORATION.md) | N4 | Complete — 2025-26 research, privacy-preserving flows, cold-start funnel, progressive onboarding vs immediate plunge |
| [Lint / Static Analysis / Type Safety](exploration/LINT_STATIC_ANALYSIS_TYPE_SAFETY.md) | P2 (platform) | Complete — lint rulesets, CI integration, type safety patterns, dead code detection, performance linting |

## Flywheel Foundation Link (2026-05-22)
- Added workflow docs: `docs/guides/ai_flywheel/annotation_review_workflow.md`, `docs/guides/ai_flywheel/router_comparison_workflow.md`

- Added foundation scaffold doc: [review/AI_LEARNING_FLYWHEEL_FOUNDATION_2026-05-21.md](review/AI_LEARNING_FLYWHEEL_FOUNDATION_2026-05-21.md)
- Includes eval harness, golden cases, consent-aware candidate gating, dataset exporter, and router metrics baseline.
- Expansion doc: [review/AI_LEARNING_FLYWHEEL_EXPANSION.md](review/AI_LEARNING_FLYWHEEL_EXPANSION.md)
- Runtime evidence: [review/AI_FLYWHEEL_RUNTIME_VERIFICATION.md](review/AI_FLYWHEEL_RUNTIME_VERIFICATION.md)
- Completion audit: [review/AI_LEARNING_FLYWHEEL_COMPLETION_AUDIT_2026-05-23.md](review/AI_LEARNING_FLYWHEEL_COMPLETION_AUDIT_2026-05-23.md)
- Goal handoff: `goal1.txt` superseded by `docs/planning/GOAL1_SUPERSEDED_BY_FLYWHEEL_DOCS.md`.

**Flywheel status**
- Implemented now: 110-case eval set with semantic family coverage checks, multi-provider recorded comparisons, router strategy recommendation generation, multi-item/local-rule scoring hooks, consent/privacy-gated dataset export with `excluded.jsonl`, and acceptance/evidence generation.
- Scaffolded (explicitly not production-wired): segmentation model inference path and runtime enforcement of router thresholds.
- Future: full admin dashboard UX for analytics/review operations (current operational path is CLI + JSONL + callable tools).

## Exploration Expansion Pass — Area List (2026-05-23)

**Purpose**: first-pass expansion map only. This section lists the areas we should explore next based on current code/docs, the recovered gamification interview, the AI flywheel completion assessment, and industry/product judgement. Each item should later get a dedicated deep-dive doc or be merged into an existing one.

### P0 — Truth, Safety, and Runtime Correctness

1. **Truthful AI eval gates and report semantics** 🔴 — split harness-smoke pass from provider/model safety readiness. Current reports can pass acceptance while offline synthetic scoring shows safety/must-not failures; this must be impossible to misread. Source: `docs/review/AI_FLYWHEEL_COMPLETION_ASSESSMENT_AND_NEXT_P0S_2026-05-23.md`.
2. **Canonical runtime router policy** 🔴 — one policy object shared by eval tooling and runtime routing, covering safety-critical escalation, local-rule freshness, local/on-device confidence gates, provider disagreement, and review enqueue. Extend the current routing path; do not create a parallel router.
3. **Backend classification proxy hardening** 🔴 — close the remaining client/cloud classification trust boundary with App Check, auth, rate limits, server cost accounting, provider-key isolation, and a release-safe migration path.
4. **Operator-grade annotation/review path** 🔴 — upgrade the developer/admin review scaffold into a reviewer-critical path: image/redaction state, model prediction, user correction, reviewer truth, approve/reject/delete, golden/training eligibility, audit trail, export preview.
5. **Safety-critical autonomy rules** 🔴 — batteries, sharps, medical waste, chemicals, e-waste, aerosol/pressurized items, and local-rule-critical cases should not be resolved by weak local inference until measured fail rates justify it.

### P1 — Adaptive Gamification and Behaviour Design

6. **Adaptive motivation profile** 🔴 — learn whether a user is solo-achievement, social, learning, impact, streak, or utility-driven from interaction frequency, completion patterns, time-of-day, feature visits, challenge choices, and explicit check-ins. Start balanced, then adapt. → [Exploration doc complete](exploration/MOTIVATION_ARCHETYPES.md) with research on HEXAD, Bartle, Octalysis, and the 5-archetype ReLoop model.
7. **Dynamic challenge weighting / counterbalance loop** 🔴 — use challenges to rebalance behaviour: if a user over-indexes on social competition, introduce solo mastery; if they only scan easy volume, introduce hazardous/e-waste or education; if they avoid community, introduce low-risk contribution tasks. (Design depends on archetype foundation #6.)
8. **Negative mechanics research** 🟡 — explore whether streak breaks, gentle decay, challenge failure, or recovery mechanics improve retention without anxiety. Default posture: points never decrease; any loss mechanic must be opt-in, explainable, recoverable, and tested. → [Exploration doc complete](exploration/NEGATIVE_MECHANICS_AB.md) with industry evidence, ethical guardrails, and experiment design.
9. **Points sinks and economy separation** 🟡 — define which sinks belong to points, tokens, civic reputation, or premium cosmetics: streak freezes, themes, custom challenges, eco-impact donations, family perks. Keep paid AI tokens separate unless a server-authoritative anti-farming path exists. → [Exploration doc complete](exploration/POINTS_ECONOMY_V2.md) with earn rates, sink types, inflation model, and monitoring dashboard.
10. **Gamification moment quality** 🟡 — reduce noisy popups, reserve celebration for meaningful milestones, coalesce reward events, add flow-friendly banners, and make rewards feel earned rather than spammy.
11. **Real-world impact personalization** 🟡 — learn which impact framing motivates each user: kg diverted, contamination prevented, local civic impact, family progress, carbon estimates, hazardous harm avoided, or learning mastery.

### P1 — Scan-Centric Product Experience

12. **Cold-launch-to-scan funnel** 🔴 — measure and minimize taps/time to first successful classification; evaluate persistent scan FAB vs tab, camera-first launch, and quick re-scan loops.
13. **Result screen decision architecture** 🔴 — make the result answer the real job: what is it, where does it go, how confident are we, why, what local rule applies, what should I do next, and what can I correct?
14. **Next-best-action orchestration** 🟡 — rank post-result actions across education, facility lookup, challenge, correction, share, batch mode, community contribution, and premium prompts without nagging.
15. **Home screen role split** 🟡 — decide whether Home is dashboard, launch pad, learning feed, habit hub, or hybrid; avoid making points/tokens/streaks dominate if they do not help the immediate disposal job.
16. **Offline/degraded result UX** 🟡 — distinguish local result, partial deterministic result, queued-for-cloud result, stale cached result, and failed result with clear copy and retry/cancel controls.

### P1 — Data Flywheel, Privacy, and Consent

17. **Unified consent ledger** 🔴 — consolidate analytics, ads, photo upload, training-data, crash, community, location, and notification consent into one versioned user-visible contract with revocation behaviour.
18. **Photo privacy pipeline** 🔴 — on-device face/address/license/prescription redaction, EXIF stripping, public-vs-private coordinate fidelity, and per-use retention before any training/community/civic use.
19. **Dataset versioning and provenance** 🟡 — every eval/training/export case should carry consent version, redaction version, model/prompt/ruleset versions, reviewer state, source lineage, and revocation/delete trace.
20. **Hard-example mining loop** 🟡 — mine corrections, low-confidence cases, provider disagreements, local-rule failures, and user-abandoned scans into review queues and eval set candidates. Live plumbing now exists in `result_pipeline`, `CorrectionDialog`, `TrainingDataService`, and the `attachTrainingLabelFeedback` Cloud Function; review-queue governance still needs deeper product decisions.
21. **User data portability and deletion drills** 🟡 — prove export/delete/revoke flows for history, photos, feedback, training candidates, gamification, tokens, family, community, and analytics references.

### P1 — Local Rules, Facilities, and Civic Intelligence

22. **Facility data trust and freshness** 🔴 — disposal directory needs sourcing, verification, freshness badges, stale-report flows, offline cache, and partner/crowd contribution rules.
23. **Society/apartment override lifecycle** 🟡 — create/update/verify/expire society-specific rules, conflict resolution against city rules, admin roles, and user trust UX.
24. **GPS/manual region selection** 🟡 — resolve travel, boundary ambiguity, unsupported regions, privacy-sensitive location use, offline city selection, and rule-pack fallback.
25. **Civic issue pilot design** 🟢 — if pursued, keep it pilot-scoped: missed pickup, overflow, illegal dumping, duplicate detection, Waze-style verification, takedown, moderation, and authority handoff.
26. **Informal recycler / pickup network** 🟢 — kabadiwala/e-waste/bulk/compost pickup directory with trust, payments, language, SLA, and safety constraints.

### P1 — Monetization, Growth, and Fairness

27. **Free/paid/premium fairness model** 🔴 — define what premium can improve without making waste safety paywalled: quality tiers, batch/offline packs, family/admin, cosmetics, export, advanced impact, and ad removal.
28. **Token-cost-value truth table** 🔴 — reconcile tokens, provider cost, failure refunds, race mode, batch mode, premium allowances, offline local classifications, and abuse caps.
29. **Referral and viral loops** 🟡 — shared classification cards, impact cards, family invites, referral rewards, install attribution, and anti-spam. Existing `Referral` and dynamic links need product rules.
30. **Ad strategy and kid/classroom safety** 🟡 — decide whether ads belong in a sustainability/education product, which surfaces are ad-free, and whether rewarded ads can ethically map to tokens.
31. **B2B/B2G wedge ranking** 🟡 — compare schools, apartments/RWAs, corporate ESG, hospitality, recycling partners, municipalities, and NGOs by buyer urgency, data needs, sales cycle, and minimum admin surface.

### P2 — Education, Knowledge, and Accessibility

32. **Adaptive education graph** 🟡 — personalize lessons/quizzes from scans, corrections, local rules, hazardous mistakes, language, age/persona, and demonstrated knowledge gaps.
33. **Quiz / knowledge verification loop** 🟡 — reward verified understanding more than passive reading; connect quizzes to safety-critical categories and school/classroom use.
34. **AI-generated content governance** 🟡 — hybrid generated/curated education with provenance, moderation, caching, multilingual review, source citations, and kill switch.
35. **Low-literacy and multilingual disposal UX** 🟡 — icon-first guidance, Kannada/Hindi/English parity, voice input/output, screen reader semantics, and clear hazardous instructions.
36. **Accessibility for camera/result flows** 🟡 — TalkBack/VoiceOver labels, haptics, large text, color-independent bin guidance, one-hand operation, and non-visual confidence/local-rule explanation.

### P2 — Platform, Release, and Observability

37. **Experiment and feature-flag governance** 🟡 — sample-size discipline, guardrail metrics, flag naming/lifecycle, cleanup, remote defaults, and auto-halt on crash/cost/safety regressions.
38. **Analytics schema governance** 🟡 — one event catalogue, consent-aware event firing, backward compatibility, activation/retention definitions, and auto-generated docs from code.
39. **Release/store compliance map** 🟡 — App Store/Play privacy disclosures, ATT/ad tracking, child/classroom implications, in-app purchase boundaries, data safety, and launch smoke gates.
40. **Cross-platform parity matrix** 🟡 — iOS/Android/Web feature availability for camera, on-device models, notifications, ads, purchases, App Check, offline queue, and local rules.
41. **Crash/performance/cost observability** 🟡 — one operator dashboard for AI spend, failures, provider latency, Firestore read/write cost, stuck queues, model download health, and top user-facing errors.

### P2 — Industry and Frontier Bets

42. **Digital Product Passport / barcode resolver path** 🟢 — prepare for EU DPP/battery passports, QR/NFC/barcode input, product material passports, and region-rule resolver integration.
43. **Segmentation and multi-object scenes** 🟢 — YOLO/SAM/MobileSAM/MiniCPM/Gemma-style path for cluttered kitchen/recycling photos; UX for reviewing N detected items before classification.
44. **Local model lifecycle** 🟢 — model download, signature verification, device-tier selection, rollback, battery/thermal budgets, and privacy positioning for local-only mode.
45. **Smart-bin / hardware partner layer** 🟢 — QR-bin first, then sensor/fullness/hardware integrations only if a pilot partner exists.
46. **MRF/brand/manufacturer closed-loop data** 🟢 — long-term data product: anonymized consumer-side confusion/correction trends for brands, recyclers, and sorting facilities, with strict consent/privacy boundaries.

### P2 — Circular Economy and Pre-Waste Intervention

47. **Personal waste lifecycle management** 🟢 — scan receipts/barcodes/order emails, predict item end-of-life, remind before disposal, and suggest better disposal/reuse paths. High privacy risk; only viable with explicit user value.
48. **Repair-before-dispose network** 🟢 — repair cafés, local technicians, maker spaces, spare-part sources, warranty routes, and “is this worth repairing?” triage before something becomes waste.
49. **Reuse/giveaway marketplace wedge** 🟢 — society/school/neighbourhood-scoped give-away, swap, sell, borrow, and donation flows; integrate after classification result when an item is still usable.
50. **Food waste prevention coach** 🟢 — expiry-date OCR, leftovers prompts, recipe suggestions, compost guidance, kitchen routine nudges, and impact tracking for avoided food waste.
51. **Packaging alternative recommendation** 🟢 — after repeated scans of hard-to-recycle packaging, suggest lower-waste alternatives, refill options, bulk-buy choices, or brand feedback.
52. **Deposit-return and refund systems** 🟡 — DRS lookup, refund value, nearest return point, QR proof, wallet reconciliation, and country/state-specific rules.

### P2 — Advanced Classification Modalities

53. **OCR, symbols, and hazard-label understanding** 🟡 — parse resin codes, WEEE icons, medicine labels, hazard diamonds, expiry dates, compostable marks, and misleading greenwashing claims.
54. **Contamination detection** 🟡 — detect grease, food residue, moisture, mixed-material contamination, broken glass risk, and whether cleaning/disassembly changes disposal advice.
55. **Disassembly guidance** 🟡 — identify multi-material objects and tell users how to separate cap/label/battery/blade/liner before disposal.
56. **Voice/text waste Q&A assistant** 🟡 — “How do I dispose of X?” without photo; grounded in local rules, not generic LLM answers.
57. **Multi-sensory classification** 🟢 — optional weight, sound, texture, user-guided manipulation, and future sensor add-ons for ambiguous materials.
58. **Bin-scan contamination scoring** 🟢 — scan a whole recycling/compost bin, score sorting quality, highlight contaminating items, and generate household/team improvement tasks.

### P2 — Trust, Explainability, and User Control

59. **Why-this-answer explanation panel** 🟡 — model evidence, local rule source, confidence, alternatives, must-not warnings, and what would change the answer.
60. **User dispute and appeal workflow** 🟡 — if the user disagrees with the app or a moderator, capture structured disputes, evidence, second opinions, and policy/ruleset correction proposals.
61. **Transparency log for models/prompts/rulesets** 🟡 — public-ish changelog of model versions, prompt versions, city ruleset updates, eval scores, and known limitations.
62. **Human expert escalation network** 🟢 — certified waste experts, municipal reviewers, recycler partners, or trained community moderators for high-risk/ambiguous cases.
63. **Trust score separation model** 🟡 — separate AI-training trust, civic-report trust, social/community trust, and gamification level so one can’t farm authority in another domain.

### P2 — Family, School, and Organization Modes

64. **Household role and permission model** 🟡 — parent/child/admin/member roles, shared history boundaries, child privacy, rewards visibility, and household goals.
65. **Classroom mode** 🟢 — teacher dashboard, assignments, safe dataset, printable certificates, quiz grading, age-tiered content, and COPPA/child-safety implications.
66. **Apartment/RWA admin mode** 🟢 — bin setup, local rules, collection schedule, society challenges, issue reports, exportable reports, and verified announcements.
67. **Corporate ESG/team mode** 🟢 — employee challenges, anonymized team metrics, CSR reporting, office waste audits, and procurement/packaging improvement loops.
68. **Kid-safe mode** 🟡 — no ads, no public community, limited sharing, safe content, guardian controls, and playful low-literacy UX.

### P2 — Content, Community, and Events

69. **Community event layer** 🟢 — cleanup drives, e-waste collection days, compost workshops, school campaigns, RSVP/check-in, verified participation, and post-event impact.
70. **UGC challenge builder** 🟢 — let trusted users/schools/societies create custom challenges with templates, moderation, anti-farming rules, and shareable results.
71. **Peer mentoring and expert Q&A** 🟢 — experienced users answer newcomer questions; incentives must reward accuracy and kindness, not volume.
72. **Eco Wrapped / annual impact story** 🟡 — Spotify-Wrapped-style yearly/monthly story cards: top materials, best streaks, local impact, learning gains, and next-year goals.
73. **Virtual garden/avatar/mascot system** 🟢 — progress embodiment that grows with verified eco-actions; must be optional and tasteful, not childish by default.

### P2 — Marketplace, Partners, and Incentives

74. **Eco-product affiliate marketplace** 🟢 — only if recommendation trust is protected; surface alternatives from repeated waste patterns, not random ads.
75. **Sponsor-funded rewards and donation matching** 🟢 — brands/NGOs sponsor verified actions, cleanups, school challenges, or point-to-donation conversions without compromising advice neutrality.
76. **Scrap-rate and recyclable-value engine** 🟢 — dynamic local rates for paper, metal, e-waste, bottles; supports pickup decisions and informal recycler economics.
77. **Pickup booking and logistics integrations** 🟢 — schedule e-waste, bulk waste, compost, recyclables pickup; track SLA, payment, proof, and partner quality.
78. **Open API / partner portal** 🟢 — allow city/NGO/recycler/brand partners to ingest rules, facility updates, schedules, campaigns, and anonymized analytics under governance.

### P3 — Deep Frontier / Watchlist

79. **Federated or privacy-preserving learning** 🟢 — improve on-device models from user corrections without centralizing raw photos; only after local model and consent foundations are mature. → [`docs/exploration/FEDERATED_PRIVACY_PRESERVING_LEARNING.md`](exploration/FEDERATED_PRIVACY_PRESERVING_LEARNING.md)
80. **AR decomposition / product lifecycle visualization** 🟢 — show decomposition timeline, material journey, facility path, or recycled product outcome in AR/3D for education. → [`docs/exploration/AR_DECOMPOSITION_LIFECYCLE_VISUALIZATION.md`](exploration/AR_DECOMPOSITION_LIFECYCLE_VISUALIZATION.md)
81. **Home smart-bin scale / compost / fridge integration** 🟢 — weight-based disposal tracking, compost health, expiry reminders, and smart-home routines. → [`docs/exploration/HOME_SMART_BIN_SCALE_FRIDGE_INTEGRATION.md`](exploration/HOME_SMART_BIN_SCALE_FRIDGE_INTEGRATION.md)
82. **Verified environmental impact ledger** 🟢 — proof-of-disposal/impact ledger, possibly non-blockchain first; web3 only if a paying partner requires it. → [`docs/exploration/VERIFIED_IMPACT_LEDGER.md`](exploration/VERIFIED_IMPACT_LEDGER.md)
83. **Waste forecasting and procurement feedback** 🟢 — predict household/organization waste patterns, recommend purchase changes, and feed aggregated “wish recycling” signals to brands. → [`docs/exploration/WASTE_FORECASTING_PROCUREMENT_FEEDBACK.md`](exploration/WASTE_FORECASTING_PROCUREMENT_FEEDBACK.md)
84. **Public-good open data layer** 🟢 — anonymized, privacy-safe municipal heatmaps, facility freshness, hard-to-recycle item trends, and policy gaps for civic benefit. → [`docs/exploration/PUBLIC_GOOD_OPEN_DATA_LAYER.md`](exploration/PUBLIC_GOOD_OPEN_DATA_LAYER.md)

### P1/P2 — Technical Architecture, MLOps, and Engineering Systems

85. **Model/prompt/ruleset registry** 🔴 — canonical registry for model versions, prompt versions, city rulesets, router policies, rollout state, owner, eval score, and rollback path.
86. **AI drift monitoring** 🔴 — detect provider model changes, prompt regressions, confidence drift, local-rule error spikes, cost anomalies, and category-specific failure movement over time.
87. **Eval leaderboard and model cards** 🟡 — model/prompt/provider comparison board with safety, local-rule, cost, latency, calibration, multi-item, and fairness slices; generate model cards for shipped AI paths.
88. **Label ontology governance** 🔴 — category/material/subcategory/risk/local-rule taxonomy ownership, deprecation policy, migration tooling, and cross-provider normalization.
89. **Synthetic data and augmentation strategy** 🟡 — generate or augment hard cases safely, but separate synthetic eval from real-world quality claims.
90. **Backend queue and job orchestration** 🟡 — durable jobs for live evals, batch classification, dataset export, review workflows, notification sends, partner sync, and retries.
91. **Cloud/storage cost ceiling architecture** 🔴 — caps and alerts for Firestore reads/writes, Storage egress, Function invocations, AI calls, image retention, and analytics volume.
92. **Disaster recovery and backup drills** 🟡 — Firestore export/restore, rules rollback, function rollback, dataset snapshot restore, deleted-user purge correctness, and incident runbooks.
93. **Secrets and environment governance** 🔴 — no client secrets, Firebase config hygiene, API key rotation, least privilege service accounts, release guardrails, and local/dev/prod separation.
94. **Test strategy by critical path** 🟡 — pyramid for unit/widget/golden/integration/emulator/runtime eval/manual QA, mapped to scan, result, token, privacy, training, payment, and city-rule paths.

### P1/P2 — Infrastructure & Operations (added 2026-05-25)

95. **CI/CD pipeline hardening** 🟡 — build time reduction, test flakiness remediation, deployment automation, staged rollouts, rollback automation, and artifact caching. Ensure CI/CD is safe for AI model/prompt updates and ruleset deployments. → [`docs/exploration/CI_CD_PIPELINE_HARDENING.md`](exploration/CI_CD_PIPELINE_HARDENING.md)

96. **Dependency supply chain security** 🟡 — package audit (`dart pub audit`), lockfile governance, vulnerability scanning in CI, transitive dependency pinning, SBOM generation, and alerting for disclosed CVEs across Flutter, Firebase, and Cloud Function dependencies. → [`docs/exploration/DEPENDENCY_SUPPLY_CHAIN_SECURITY.md`](exploration/DEPENDENCY_SUPPLY_CHAIN_SECURITY.md)

97. **Force-update / version deprecation strategy** 🟡 — minimum supported version gates, forced-update UX, graceful degradation for outdated clients, API versioning on Firebase Functions, sunset timeline policy, and App Store / Play Store coordination. → [`docs/exploration/FORCE_UPDATE_VERSION_DEPRECATION.md`](exploration/FORCE_UPDATE_VERSION_DEPRECATION.md)

### P1/P2 — App-Specific Product Surface Inventory

98. **Navigation and information architecture system** 🔴 — decide canonical placement for Scan, History, Social/Family, Achievements, Settings, Facilities, Tokens, Training Review, Premium, and Local Rules.
99. **History as personal knowledge base** 🟡 — turn classification history into search, filters, re-analysis, learning recap, correction status, export, and “what I commonly waste” insights.
100. **Token wallet UX and trust** 🔴 — make balances, spends, refunds, failed analysis, premium grants, race-mode costs, and offline/local free classifications understandable.
101. **Premium feature discoverability** 🟡 — premium toggles, locked states, trials, upgrade copy, fairness, refund routes, and no-dark-pattern constraints.
102. **Training review/admin surfaces** 🔴 — queue filters, reviewer workload, quality checks, escalation, admin roles, audit log, and “operator can use day 1” readiness.
103. **Settings architecture** 🟡 — consolidate privacy, region, notifications, model downloads, offline mode, tokens, account, family, accessibility, developer toggles, and consent into a coherent settings map.
104. **Widgetbook/design-lab governance** 🟡 — keep component stories, visual states, tokens, golden screenshots, accessibility variants, and result-card states in sync with production.
105. **Empty/error/loading state system** 🟡 — design all no-history, no-network, low-token, model-missing, unsupported-region, no-consent, failed-scan, stale-policy, and review-pending states.

### P1/P2 — Marketing, Positioning, Launch, and Distribution

106. **Positioning and category narrative** 🔴 — decide whether the app is “AI waste sorting,” “local disposal companion,” “zero-waste coach,” “family eco habit app,” or “civic waste platform”; messaging changes product priorities.
107. **App Store Optimization and screenshots** 🔴 — keywords, subtitle, preview video, screenshot story, privacy trust claims, local-language listings, and competitor comparison.
108. **SEO/content acquisition engine** 🟡 — city/category pages like “Bangalore battery disposal,” “pizza box recycling,” “e-waste pickup near me,” with source freshness and conversion to app install.
109. **WhatsApp-first distribution** 🟡 — shareable result cards, local-rule snippets, RWA notices, referral links, challenge invites, support flows, and low-friction install loops.
110. **Campus/school ambassador strategy** 🟢 — classroom kits, printable certificates, teacher onboarding, student challenges, science-fair angle, and child-safety governance.
111. **RWA/apartment launch playbook** 🟢 — one-building pilot package: bin labels, QR posters, local rules, challenges, reports, volunteer roles, and before/after metrics.
112. **NGO/municipal co-marketing** 🟢 — credibility partnerships, cleanup drives, official ruleset sponsorship, helpline integration, and public-good reports.
113. **Creator/influencer content loops** 🟢 — sustainability creators, local-language reels, myth-busting shorts, challenge templates, and measurable install attribution.
114. **Referral economics and fraud** 🟡 — reward amount, eligibility, abuse detection, family/self-referral prevention, inviter/invitee value, and CAC payback.
115. **Launch sequencing by geography** 🔴 — Bangalore-first vs India metros vs global generic; choose based on rule accuracy, facilities data, language, partner access, and marketing focus.

### P1/P2 — Industry-Specific Waste Domains

116. **Biomedical and sharps domain** 🔴 — household medical waste, syringes, masks, sanitary waste, expired medicines, pharmacies, clinics, liability, and safe “do not handle” copy.
117. **E-waste and battery domain** 🔴 — lithium fire risk, power banks, phones, chargers, cables, take-back programs, EPR, pickup partners, and data-wipe education.
118. **Food service and hospitality waste** 🟡 — restaurant packaging, bulk food waste, composting, grease contamination, hotel/event waste audits, and B2B wedge.
119. **Construction and demolition waste** 🟢 — paint, solvents, tiles, rubble, wood, glass, asbestos risk, contractor workflows, and municipal drop-off rules.
120. **Retail and packaging domain** 🟡 — brand/SKU packaging, DPP, deposit schemes, store take-back, refill programs, and packaging feedback to manufacturers.
121. **Events/festivals waste mode** 🟢 — temporary bins, volunteer sorting, QR posters, crowd education, event impact report, and sponsor dashboards.
122. **Office/corporate waste mode** 🟢 — printer cartridges, office e-waste, pantry waste, employee challenges, procurement feedback, and ESG reports.
123. **Informal economy and worker safety** 🟡 — kabadiwala/recycler workflows, fair pricing, language/literacy, dignity, safety guidance, and avoiding extractive data practices.

### P1/P2 — Regulatory, Legal, and Policy Landscape

124. **India DPDP and consent compliance** 🔴 — lawful basis, consent withdrawal, child data, grievance officer, retention, processors, and cross-border handling.
125. **India SWM/E-waste/biomedical/plastic waste rules** 🔴 — align advice with Solid Waste Management Rules, E-Waste Rules, Plastic Waste Rules, Biomedical Waste Rules, and city bylaws.
126. **GDPR/UK/EU expansion posture** 🟡 — DSRs, data minimization, DPIA, legitimate interest vs consent, DPP integration, and processor contracts.
127. **COPPA/kids/classroom compliance** 🟡 — age gates, guardian consent, school consent, ads off, public sharing off, and educational records boundaries.
128. **AI transparency and liability** 🟡 — explainability, disclaimers, hazardous advice liability, “not official municipal advice” wording, and escalation for dangerous items.
129. **Advertising, affiliate, and sponsorship ethics** 🟡 — advice neutrality, disclosures, ad targeting, kid-safe restrictions, and avoiding greenwashing.
130. **Data licensing and public-source use** 🟡 — municipal data reuse rights, scraped facility data, Open Food Facts/barcode data licenses, and attribution obligations.
131. **Partner contracts and SLA model** 🟢 — recycler/pickup/facility partner obligations, dispute handling, refunds, safety, and quality scoring.

### P1/P2 — Operations, Support, Moderation, and Field Work

132. **Customer support operating model** 🟡 — categories, macros, escalation, refund/token disputes, privacy requests, wrong disposal reports, and SLA.
133. **Moderation staffing and cost model** 🔴 — reviewer ratios, queue SLAs, expert escalation, abuse handling, trust tiers, and cost per 1k UGC/review items.
134. **City expansion operations playbook** 🔴 — source research, legal check, rule-pack authoring, local validator, pilot testing, freshness monitoring, and promotion gates.
135. **Facility verification operations** 🟡 — call/check schedule, user verification, partner verification, stale reports, closure handling, and confidence badges.
136. **Field research at bins** 🟡 — observe real disposal moments, photo-taking constraints, language needs, time pressure, social embarrassment, and failure modes.
137. **Incident response playbook** 🔴 — harmful advice, leaked image/PII, abusive community content, AI cost spike, wrong municipal rule, payment failure, and public complaint.
138. **Partner onboarding operations** 🟢 — recycler/facility/RWA/school onboarding, verification, training, support, reporting cadence, and churn prevention.
139. **Data quality review cadence** 🟡 — weekly hard-case review, monthly city-rule review, quarterly model benchmark, and stale-doc cleanup.

### P1/P2 — Gamification Full-Spectrum Expansion

140. **Player archetype framework** 🔴 — achiever, explorer, socializer, impact-seeker, collector, learner, helper, streaker, utility-only; map mechanics and anti-patterns per archetype.
141. **Progression pacing and inflation control** 🔴 — XP curves, level caps, reward rarity, seasonal resets, long-term goals, and preventing meaningless point inflation.
142. **Ethical gamification guardrails** 🔴 — no addiction dark patterns, anxiety caps, kid-safe mechanics, opt-outs, cooldowns, and transparency around personalization.
143. **Seasonal and cultural campaign calendar** 🟡 — Earth Day, Plastic-Free July, Diwali cleanup, local festivals, school terms, monsoon waste issues, and city-specific campaigns.
144. **Family/team cooperative mechanics** 🟡 — shared goals, role-based tasks, no-shame leaderboards, household streaks, parent-child missions, and conflict prevention.
145. **Anti-farming and reward abuse** 🔴 — repeat image, fake disposal, referral spam, civic report spam, challenge gaming, emulator abuse, and server-side detection.
146. **Reward redemption and liability** 🟡 — coupons, donations, perks, refund handling, sponsor fulfillment, tax/accounting implications, and abuse limits.
147. **Personalization controls for gamification** 🟡 — let users tune competition, social visibility, notifications, difficulty, negative mechanics, and impact framing.
148. **Motivation profile inference model** 🔴 — infer motivation from interaction frequency, completion patterns, time-of-day, feature visits, challenge choices, explicit check-ins, confidence, decay, and cold-start defaults.
149. **Adaptive challenge generator** 🔴 — generate safe personalized solo/social/learning/impact challenges from verified templates, local rules, user history, and available rewards without hallucinating disposal advice.
150. **Counterbalance vs amplification policy** 🔴 — decide when to broaden neglected behaviours versus amplify what already works; explicitly model the user’s “motivation diet.”
151. **Gamification ethics contract** 🔴 — define hard boundaries for streak pressure, loss aversion, kids, notifications, social comparison, personalization opacity, and manipulative loops.
152. **Reward economy inflation model** 🔴 — XP curves, level caps, rarity, seasonal resets, sinks, prestige tiers, long-term goals, and “points still mean something after year one.”
153. **Verified action hierarchy** 🔴 — rank actions by real-world value: scan, correct, learn, dispose, verify, teach, contribute, organize, reduce, repair, reuse, and prevent waste.
154. **Anti-gaming threat model for gamification** 🔴 — repeat scans, fake corrections, fake disposal, family collusion, civic spam, referral fraud, emulator/device abuse, and trust-ladder attacks.
155. **Social pressure safety design** 🟡 — cooperative defaults, no-shame leaderboards, private progress, opt-out visibility, kid/family boundaries, and comparison copy that motivates without humiliating.
156. **Impact narrative personalization** 🟡 — choose whether to frame progress as carbon, landfill diversion, contamination avoided, local cleanliness, family teaching, money/refunds, safety, or mastery.
157. **Seasonal campaign operating system** 🟡 — campaign templates, local calendars, sponsor slots, challenge bundles, notification cadence, metrics, and post-campaign reports.
158. **Reward sink catalog and rules** 🟡 — streak freezes, themes, avatars, donation matching, custom challenges, family perks, sponsor coupons, certificates, and what each currency can buy.
159. **Gamification-to-learning bridge** 🔴 — wrong scans, hazardous scans, low-confidence results, and local-rule mistakes should trigger micro-lessons/quizzes; reward mastery more than passive reading.
160. **Burnout and fatigue detection** 🟡 — detect avoidance, notification fatigue, challenge abandonment, streak anxiety, and social comparison stress; switch to gentler utility mode.
161. **Dynamic difficulty tuning** 🟡 — challenge difficulty based on history, confidence, category familiarity, correction quality, user bandwidth, household context, and recent success/failure.
162. **Household/team game modes** 🟡 — cooperative household goals, role-specific missions, kid-safe quests, RWA/team challenges, office competitions, and team anti-farming controls.
163. **Gamification analytics dashboard** 🟡 — mechanic-level retention, conversion, fatigue, abuse, challenge completion, correction quality, learning mastery, and long-term behaviour change.
164. **Identity and status system** 🟡 — titles like “Battery Safety Guardian” or “Compost Coach” earned through verified competence, not raw points.
165. **Real-world reward governance** 🟡 — define what sponsors can fund, what must remain neutral, how rewards avoid corrupting advice, and how fulfillment/fraud is handled.
166. **Personalization controls UI** 🟡 — user-facing controls for competitiveness, social visibility, notification pressure, challenge difficulty, negative mechanics, impact framing, and private mode.
167. **Mechanic-level kill criteria** 🔴 — every mechanic must justify itself by retention, correction quality, education completion, safe disposal, verified impact, partner value, or be removed.

### P1/P2 — Research, Measurement, and Strategy

168. **User interview tracks** 🔴 — consumers, parents, kids/teachers, RWA admins, recyclers, municipal workers, sustainability officers, and low-literacy users.
169. **Retention cohort research** 🔴 — day 0/1/7/21/30 retention, novelty cliff, habit loop impact, notification tolerance, and paid conversion triggers.
170. **Pricing willingness-to-pay research** 🟡 — India vs global PPP, family plans, school/RWA pricing, premium AI quality, offline packs, and token bundles.
171. **Competitive teardown program** 🟡 — Yuka, Google Lens, Recycle Coach, municipal apps, Too Good To Go, OLX/Freecycle, smart-bin players, ESG tools.
172. **Pilot design framework** 🔴 — define success metrics, kill criteria, sample size, ops burden, ethics, and before/after baselines for every school/RWA/civic pilot.
173. **North-star metrics and KPI tree** 🔴 — safe correct disposals, retained useful users, local-rule confidence, training data quality, CAC, cost per successful classification, and verified impact.
174. **Decision log and kill-criteria governance** 🟡 — every exploration topic needs owner, decision, evidence, next action, and kill/continue criteria to avoid idea sprawl.
175. **Portfolio prioritization model** 🔴 — score all topics by user value, safety, moat, revenue, effort, dependency, evidence, and risk so exploration turns into sane sequencing.

**Still intentionally not a build queue**: these additions are exploration candidates, not commitments. Promote only when a decision needs research, there is a plausible owner, and the topic has clear kill criteria.

**Recommended deep-dive order**: start with 1–5 (truth/router/operator safety), then 6–11 (adaptive gamification from the recovered interview), then 12–16 (scan/result UX). The frontier bets are attractive but should not outrank making the existing flywheel and habit loop truthful.

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
