# Exploration Topics — Master Index

**Purpose**: Living document tracking research areas for the Waste Segregation App
**Status**: Active — continuously updated as the project evolves
**Last Updated**: 2026-05-19
**Sibling docs**:
- [EXPLORATION_FRONTIER.md](EXPLORATION_FRONTIER.md) — high-ambition / "boil the ocean" frontier bets
- [EXPLORATION_ROADMAP_WHILE_BUILDING.md](EXPLORATION_ROADMAP_WHILE_BUILDING.md) — what to explore in parallel with shipping
- [exploration/](exploration/) — per-topic detailed exploration docs
- [exploration/backlog.md](exploration/backlog.md) — raw, append-only idea backlog

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
│  ├── Family / Group Mechanics     [🟡]        ├── Municipal APIs (BBMP) [🟡] │
│  ├── Local Reuse Marketplace      [🟢]        ├── Collector Network     [🟢] │
│  └── Moderation & Safety          [🔴]        └── Hardware Partners     [🟢] │
│                                                                               │
│  BUSINESS & GROWTH                            COMPLIANCE & TRUST              │
│  ├── Monetization & Pricing Tiers [🟡]        ├── Privacy / Photo PII   [🔴] │
│  ├── B2B / Enterprise Wedge       [🟢]        ├── Regional Regulations  [🟡] │
│  ├── Carbon / Impact Accounting   [🟡]        ├── Content Provenance    [🟢] │
│  └── Distribution & Partnerships  [🟢]        └── Audit / Telemetry     [🟡] │
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

### 12. Classification History Schema 🟡

**Status**: Stored via `classification_storage_service.dart`, `classification_migration_service.dart`. Schema evolution path under-documented.

**Overview**: Classification history is the single most valuable user-owned artefact. Today the schema is implicit. We need an explicit contract for migrations, exports, and downstream analytics.

**Key questions**:

- Versioned schema with explicit migration steps.
- User-export contract (CSV / JSON / open formats) — relevant to GDPR-style asks.
- Anonymisation strategy if records feed model training.

**Deliverable**: `docs/exploration/CLASSIFICATION_HISTORY_SCHEMA.md`.

**Related**: Data Retention & PII, Offline Queue & Sync.

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
