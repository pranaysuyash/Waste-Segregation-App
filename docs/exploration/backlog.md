# Exploration Backlog — Waste Segregation App

**Last Updated**: 2026-05-21

A living, append-only document of areas to explore, ideas to investigate, and potential improvements. **Add items freely** — this is a capture space, not a commitment queue. Items get promoted into [../EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) or a dedicated `docs/exploration/*.md` doc when they're mature enough to act on.

Format per item:

- `[ ]` open / `[x]` promoted / `[~]` killed (with one-line rationale)
- Short title, then optional context
- Cross-link to existing planning / research docs when known

Sources already mined for this initial list:

- [../planning/ideas_to_explore.md](../planning/ideas_to_explore.md)
- [../planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md](../planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md)
- [../planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md](../planning/CONSOLIDATED_FUNCTIONAL_IMPROVEMENTS_ROADMAP.md)
- [../planning/REMAINING_ROADMAP_ITEMS.md](../planning/REMAINING_ROADMAP_ITEMS.md)
- [../TODO/](../TODO/)
- [../TOKEN_ECONOMY_TODO.md](../../TOKEN_ECONOMY_TODO.md)

---

## AI & Vision

- [ ] Calibrated confidence + "ambiguous" UX state (vs forcing a single answer)
- [ ] Per-provider response normaliser so model swaps don't ripple into UI
- [ ] Prompt versioning + per-prompt eval scores (no prompt change without an eval pass)
- [ ] Hard-example mining from user corrections — weekly cycle
- [x] Multi-Model AI Stack Roadmap (quality gate + detection/segmentation + classifier + routing + privacy + active learning + eval/data quality loop) for post-classifier growth. Promoted as `EXPLORATION_TOPICS.md#1a`.
- [x] **MULTI_ITEM_SEGMENTATION_UX_V1** — Manual region + scaffolded segmentation with `DetectedWasteRegion`/`MultiItemClassificationResult` abstractions. Delivered `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md`. Backlog items below remain for ML model integration.
- [ ] Multi-frame / burst-capture mode for cluttered or hard scenes
- [ ] Audio cues (crunching plastic, paper rustle) as supplementary signal
- [ ] Brand / SKU recognition with explicit privacy & accuracy boundaries
- [ ] Distinguish "model unsure" from "image bad" (blur, framing, glare)
- [ ] Active-clarification: when uncertain, ask the user a structured question rather than guessing

## On-Device & Edge

- [x] Evaluate MiniCPM-V 4.6, Gemma 4 4B/shrdlu, MobileSAM, Qwen3-VL for on-device waste classification. Full survey in `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md#7.2-vision-language-models-vlms-for-region-classification`.
- [ ] Benchmark MiniCPM-V 4.6 vs Gemma 4 4B on actual waste crop classification accuracy
- [ ] Build MobileSAM → ONNX → TFLite pipeline and test on mid-tier Android device
- [ ] Build MiniCPM-V 4.6 on-device integration (flutter_llama.cpp or similar) for region classification
- [x] **Full segmentation model exploration (May 2026)** — Wide-open sweep covering SAM 3 (848M, text-prompted concept seg), SAM 2.1 (38.9M-224M), MobileSAM (9.66M), EdgeSAM (~5M), EfficientSAM (30M), FastSAM (68M), YOLOv8/v11 (3M+), GridSegmentation, MiniCPM-V 4.6 (1.3B, on-device VLM), MiniCPM-o 4.5 (9B, omnimodal), Gemma 4 4B/9B/shrdlu/E2B-it (MediaPipe), Qwen3-VL, InternVL-3.5, Gemini 2.5, GPT-5, Grounding-SAM, Roboflow API. Pipeline recommendation: YOLOv11 detect → crop → MiniCPM-V 4.6 on-device classify, with SAM 2.1/Gemini as premium fallback. See `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md#7-full-model-exploration-map`.
- [ ] Bundle-vs-lazy-download strategy for model weights (APK size guardrail)
- [ ] iOS vs Android parity matrix for on-device inference
- [ ] Battery / thermal / memory budget benchmark on representative mid-tier devices
- [ ] On-device pre-filter (is this even a waste item?) before cloud classify
- [x] **Local ML first-pass classifier scaffold** — `LocalClassifier` abstract interface, `LocalClassificationResult` with escalation logic, `LocalClassifierThresholds` policy, `FakeLocalClassifier` for tests. Delivered `docs/review/LOCAL_ML_FIRST_PASS_CLASSIFIER_PLAN_2026-05-21.md` + `lib/services/local_classifier_service.dart` + `test/services/local_classifier_service_test.dart`.
- [x] **Local ML Phase B — ClassificationPipeline wiring** — `ClassificationPipeline` orchestrating L0→L1→Cloud, Riverpod providers, `classificationLayer` field on `WasteClassification`, pipeline wired into capture screen, offline queue reordered to try local first. 36 total tests. Delivered `lib/services/classification_pipeline.dart` + `lib/providers/classification_pipeline_providers.dart` + `test/services/classification_pipeline_test.dart`.
- [ ] Cascade escalation policy — features that drive escalation, audit trail per escalation
- [ ] Graceful degradation tiers on low-end devices (skip on-device entirely, force cloud, throttle)

## Data, Cost & Reliability

- [ ] Per-user daily / monthly soft + hard caps on AI spend
- [ ] Provider downgrade ladder when budget exhausted (small model → on-device → queue)
- [ ] Anonymous-user abuse mitigations (rate limits, device fingerprinting tradeoffs)
- [ ] Firestore read/write hotspot audit and per-MAU cost projection
- [ ] Index audit — find load-bearing vs dead composite indexes
- [ ] Classification history schema migration framework (versioned migrations)
- [ ] User export of classification history (JSON / CSV, with photo links)
- [ ] Photo storage lifecycle: hot → cold → delete with explicit windows
- [ ] Offline queue: idempotency keys, conflict resolution policy per record type
- [ ] "Pending sync" UI surface with retry / cancel
- [ ] Telemetry for stuck or repeatedly-failing queue items

## User Experience & Engagement

- [ ] Time-to-first-successful-scan instrumentation + funnel dashboard
- [ ] Skip-onboarding-and-recover path for impatient users
- [ ] Re-onboarding when a returning user has been away N weeks
- [ ] Notification policy — what reliably drives return without becoming nagging
- [ ] Educational content sequencing based on user competence (scaffolded learning)
- [ ] Persona-specific surfaces — household, parent, kid, teacher, RWA admin, sustainability officer
- [ ] Accessibility audit — VoiceOver / TalkBack coverage of the classify flow
- [ ] Voice-first capture path for accessibility
- [ ] Language priority order beyond English / Hindi
- [ ] Low-literacy iconography pass on disposal advice

## Gamification & Behaviour

- [ ] Reward correct disposal, not just scan volume — needs verification primitive
- [ ] Anti-cheating: detect repeat-scan farming
- [ ] Cooperative family / group challenges vs purely competitive
- [ ] Streak design that survives travel / sick days without punishing
- [ ] Habit loop measurement — cue → routine → reward, with retention cliffs
- [ ] Week-3 retention cliff investigation (where does novelty wear off?)
- [ ] Long-term motivation beyond points (impact narrative, identity, belonging)

## Community & Social

- [ ] Trust tiers — anonymous / email-verified / identity-verified, and what each can do
- [ ] Image moderation pipeline (NSFW, faces, license plates, addresses)
- [ ] Comment / reaction abuse handling
- [ ] Misinformation handling when a community "correct" answer is wrong
- [ ] Role model for families / classrooms / societies (parent / kid / admin / member / observer)
- [ ] Privacy boundaries within a group (what does an admin see vs a parent vs a kid?)
- [ ] Cross-group movement (kid graduates from family group to school group)
- [ ] Local reuse marketplace pilot — society or building scoped
- [ ] Integration with existing local channels (society apps, WhatsApp groups)

## IoT, Smart City & Partners

- [ ] QR-bin layer as the cheapest possible "smart bin" — pilot with one RWA / school
- [ ] Smart-bin hardware partner landscape scan
- [ ] BBMP / municipal partner outreach — what data, what SLA, what credibility win
- [ ] Apartment-chute / weighing-scale integrations as future surfaces
- [ ] Informal collector (kabadiwala) onboarding model — literacy, devices, payments
- [ ] Verified-disposal primitive (what counts? user attestation? bin scan? collector confirmation?)
- [ ] Drop-off point directory with user ratings + verified status

## Business & Growth

- [ ] Premium tier value justification (cloud quality? family seats? offline pack? education?)
- [ ] Anchor pricing across regions (India vs US PPP)
- [ ] Family / group plans vs per-seat pricing
- [ ] Free-tier limits that drive conversion without breaking the core promise
- [ ] B2B wedge ranking — school vs corporate ESG vs hospitality vs municipal
- [ ] Minimum admin surface for each B2B wedge (dashboard, exports, SSO)
- [ ] White-label vs first-party rules of the road
- [ ] Carbon / impact accounting framework choice (EPA / IPCC / regional)
- [ ] Uncertainty UI for impact numbers without killing motivation
- [ ] Brand / manufacturer closed-loop data — privacy posture + sales motion
- [ ] Distribution channels: schools, RWAs, brand partners, sustainability NGOs

## Compliance & Trust

- [ ] On-device face / PII redaction before any upload
- [ ] Explicit consent UI for any photo reuse beyond classification
- [ ] Cross-border data flow constraints (India ↔ US ↔ EU)
- [ ] DPDP Act (India) checklist
- [ ] GDPR checklist for any EU exposure
- [ ] COPPA / age-gating for kid users
- [ ] Global municipal policy engine rollout plan: authority pack lifecycle, promotion gates, and provenance contract (not local-only)
- [ ] Multi-city rule-pack expansion: BMC Mumbai + MCD Delhi first-class packs, then tier-2 India and international jurisdictions
- [ ] Provenance metadata per classification (model, prompt version, ruleset version, timestamp)
- [ ] "Why did the app say that?" explainability surface for advanced users / partners
- [ ] Audit trail spec: one place to answer "what did the app do for this user, when, and why?"

## Pipeline & Capture Surfaces

- [ ] Share-from-other-app intent (share an image from gallery / WhatsApp to classify)
- [ ] Batch capture mode — classify many items in one session (kitchen clean-out)
- [ ] Continuous video classification for conveyor / chute scenarios (frontier)
- [ ] Auto-detect "this is a waste-item scan, not a random photo" so user doesn't have to choose
- [ ] Re-classification flow — open an old scan, re-run with a newer model

## Locality & Civic Waste Intelligence

Track promoted 2026-05-20. Canonical doc: [../review/EXPLORATION_AND_RESEARCH_BACKLOG_2026-05-20.md](../review/EXPLORATION_AND_RESEARCH_BACKLOG_2026-05-20.md). Map index entries: [F. LOCALITY & CIVIC WASTE INTELLIGENCE → L1–L6](../EXPLORATION_TOPICS.md). Research lane only — not P0. Items below are capture-only; do not commit before the agent tasks (Civic-A…F) in the canonical doc resolve them.

- [x] Locality collection schedule + route + ward / zone data (promoted as L1; agent Civic-A)
- [x] Map-based civic issue reporting (pilot scope) (promoted as L2; agent Civic-B)
- [x] Waze-style "is this still here?" verification loop (promoted as L3; agent Civic-C)
- [x] Civic reputation/points ledger, **separate** from AI tokens (promoted as L4; agent Civic-C separation contract)
- [x] Authority / NGO / apartment sharing (WhatsApp / email / PDF / CSV / dashboard) (promoted as L5; agents Civic-D + Civic-F)
- [x] Civic privacy, safety & moderation foundation — gates everything public (promoted as L6; agent Civic-E)
- [ ] Public bin inventory + fullness + damage reports (L7 candidate)
- [ ] Collection route reliability score from crowdsourced "truck came at..." signals (L7 candidate)
- [ ] Apartment / school / NGO modes with role separation (L7 candidate; cross-link #29)
- [ ] Local marketplace — kabadiwala / compost / e-waste pickup partners (L7 candidate; extends #26)
- [ ] WhatsApp-first civic flow with local-language complaint generation (L7 candidate)
- [ ] Local-language layer (Kannada / Hindi / English) + voice notes + low-literacy icons (L7 candidate; cross-link #18)
- [ ] Open civic API / anonymised public feed (L7 moonshot)
- [ ] Disposal facility status freshness badge ("last verified") on existing directory (launch-adjacent, low-risk; cross-link A20)
- [ ] Hyperlocal SEO pages for "<area> e-waste / bulk pickup" — no UGC moderation cost (launch-adjacent)

## Engineering Health

- [ ] Code TODO sweep — see `code_todos_grep_results.txt`, `todo_grep_results.txt`, `todos_consolidated_raw_2025-06-14.txt`
- [ ] Service-level Riverpod migration audit — anything still on legacy state
- [ ] Test coverage map vs critical-path matrix
- [ ] Crash / ANR baseline + budget
- [ ] Build-time + release-pipeline health audit
- [ ] Documentation lint — broken cross-doc links, stale dates, drift vs `APP_KNOWLEDGE_BASE.md`
- [ ] P0 backend hardening closeout audit (client secret blocking, fallback labeling, quota preflight, ads/premium guard, functions.config bridge removal plan) — align with `EXPLORATION_TOPICS.md` #10 (AI Cost Telemetry & Guardrails), #27a (Token Economy & Pricing Coherence), and #32 (Privacy / Photo PII)
- [ ] Token economy integrity hardening track (global, not local-limited): anti-tamper `tokenWallet` rules, server-authoritative spend enforcement policy, offline queue charge semantics parity, premium-token contract reconciliation (aligns with `EXPLORATION_TOPICS.md#27a`)
- [ ] App Check + rate-limiting implementation plan with emulator test matrix — link hardening report before execution
- [ ] Android security posture truth-map lane: reconcile legacy security-fix docs with executable manifest/network policy, pinning decision, and release-stage security checklist ownership (see `docs/reports/audits/RANDOM_DOCUMENT_AUDIT_SECURITY_AUDIT_FIXES_2026-05-21.md`)

---

## Promotion Log

When an item moves from this backlog into a real exploration doc or into `EXPLORATION_TOPICS.md`, log it here:

| Date | Item | Promoted to | Notes |
|------|------|-------------|-------|
| 2026-05-19 | Multi-Model AI Routing | `EXPLORATION_TOPICS.md#1` | Topic seeded in master index. Full doc still to write. |
| 2026-05-19 | Eval Harness & Golden Sets | `EXPLORATION_TOPICS.md#5` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Region-Aware Rulesets | `EXPLORATION_TOPICS.md#4` | Topic seeded. Full doc still to write. |
| 2026-05-19 | AI Cost Telemetry & Guardrails | `EXPLORATION_TOPICS.md#10` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Onboarding & Activation | `EXPLORATION_TOPICS.md#19` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Privacy / Photo PII | `EXPLORATION_TOPICS.md#32` | Topic seeded. Full doc still to write. |
| 2026-05-19 | Token Economy & Pricing Coherence | `EXPLORATION_TOPICS.md#27a` | Added after wide-open-brainstorm pressure test (see `../brainstorm_exploration_map_2026-05-19.md`). Active work in flight; references the 9 brainstorm files + `TOKEN_ECONOMY_TODO.md`. |
| 2026-05-19 | "The dataset is the moat" reframing | `EXPLORATION_TOPICS.md#12` | Reframed Classification History Schema as an asset/moat, not a data-eng cost. Surfaced by Future Self + Strategist roles in the brainstorm. |
| 2026-05-19 | Dependency view + Archive policy | `EXPLORATION_TOPICS.md` + `exploration/ARCHIVE.md` | Added dependency-view ASCII (sequencing) and created `ARCHIVE.md` for `[KILLED]` / `[✓]` topics so the active index stays the cursor. |
| 2026-05-19 | **Code + industry scan pass** — 25 new topics (A1–A25) | `EXPLORATION_TOPICS.md` "Additional Topics" section | Directed scan of `lib/` (73 services / 42 screens / 33 models / 14 providers) + docs/ subfolders + 2025–26 industry literature. Surfaced: Image Capture & Quality Gate (A1), AI Race / Multi-Provider Concurrency (A2), AI Failure Taxonomy (A3), Model Lifecycle (A4), Object Detection / Multi-Object (A5), Smart Suggestions (A6), Knowledge Verification / Quiz (A7), AI-Generated Educational Content (A8), Personal Impact Dashboard UX (A9), Cross-Platform Parity (A10), Notification Strategy (A11), A/B Testing & Feature Flags (A12), Remote Config & Kill Switches (A13), Launch & Store Compliance (A14), Account / Identity Lifecycle (A15), Deep Links & Viral Loops (A16), Ads / Revenue Diversification (A17), Analytics Schema Governance (A18), Consent Architecture (A19), Disposal Facilities Directory (A20), User Contribution UGC Pipeline (A21), Recycling Code Taxonomy (A22), EU DPP / ESPR signal (A23), VLM-for-Waste research signal (A24), MRF-side Competitors signal (A25). Three new categories: Platform & Release Engineering, Growth & Distribution Surfaces, Disposal Facilities & Local Knowledge. |

| 2026-05-20 | **Locality & Civic Waste Intelligence track** (L1–L6) | `EXPLORATION_TOPICS.md` new section F + `../review/EXPLORATION_AND_RESEARCH_BACKLOG_2026-05-20.md` (canonical) | Long-horizon civic moat: collection schedules, map-based reporting, Waze-style verification, civic reputation (separate from AI tokens), authority/B2B/B2G sharing, privacy/moderation foundation. Reconciles with A20, A21, #20, #23, #24, #25, #26, #27a, #29, #32 and `planning/local_recycling_directory.md`. Research lane — NOT P0. Six agent-ready tasks (Civic-A…F) defined with deliverables, acceptance criteria, out-of-scope, validation. Seven kill criteria defined. Inherits existing map stack (`flutter_map`, `flutter_map_marker_cluster`, `flutter_map_heatmap`, `geoflutterfire_plus`, `flutter_map_tile_caching`) — no new vendor decision needed for MVP. |
| 2026-05-21 | Token economy integrity track refresh (post-audit reclassification) | `EXPLORATION_TOPICS.md#27a` | Re-ranked after rigorous re-check + wide-open-brainstorm roles. Earlier "instant token bypass" finding is now closed in code; active frontier moved to anti-tamper rules, server-authoritative spend semantics, offline queue parity, and premium/token contract coherence. |
| 2026-05-21 | Multi-Model AI Stack (full model-fleet roadmap) | `EXPLORATION_TOPICS.md#1a` | Added deferred stack exploration for phased model rollout, router, quality/PII gate, eval dataset, and on-device progression. |
| 2026-05-21 | Android security posture truth-map (legacy fix doc audit) | `docs/reports/audits/RANDOM_DOCUMENT_AUDIT_SECURITY_AUDIT_FIXES_2026-05-21.md` | Random-doc audit selected `docs/archive/fixes/security_audit_fixes.md`; produced evidence-backed mismatch register (HTTPS exception wording, pinning checklist drift, status over-closure) and next work unit for policy alignment. |
| 2026-05-21 | **Local ML Phase A — Scaffold** (interface + result + fake) | `docs/review/LOCAL_ML_FIRST_PASS_CLASSIFIER_PLAN_2026-05-21.md` | `LocalClassifier` interface, `LocalClassificationResult` with escalation, `FakeLocalClassifier`. Delivered: `lib/services/local_classifier_service.dart` + `test/services/local_classifier_service_test.dart` (23 tests). |
| 2026-05-21 | **Local ML Phase B — Pipeline + Wiring** | `docs/review/LOCAL_ML_FIRST_PASS_CLASSIFIER_PLAN_2026-05-21.md` | `ClassificationPipeline` (L0→L1→Cloud), Riverpod providers, `classificationLayer` on `WasteClassification`, wired into capture screen, offline queue reordered. Delivered: `lib/services/classification_pipeline.dart` + `lib/providers/classification_pipeline_providers.dart` + `test/services/classification_pipeline_test.dart` (13 tests). 36 total tests across Phase A+B. |
| 2026-05-22 | **CityPolicyData helper + 7 city plugins** | `lib/services/city_policy_data.dart` + `lib/services/local_guidelines_plugin.dart` | Implemented `CityPolicyData` data-driven helper with pre-built instances for BBMP, BMC, MCD, PMC, GHMC, GCC, KMC. Refactored BBMP retains custom compliance. All other cities use `CityDataPluginMixin` for zero-boilerplate. Region aliases for all 7 cities including historical names. |
| 2026-05-22 | **safetyOverrideAlways + confidence gating** | `lib/services/local_policy_engine.dart` | Added `safetyOverrideAlways` check type for deterministic safety floor. Confidence gating: full enforcement ≥0.90, full at 0.70–0.89, all demoted to warning 0.50–0.69, all demoted <0.50. `confidenceGated` flag on `LocalPolicyDecision`. |
| 2026-05-22 | **Rule packs for 7 cities with safety rules** | `lib/services/local_policy_rule_packs.dart` | All 7 city packs now include hazardous + medical safety override rules. PMC, GHMC, GCC, KMC added as new packs (5 rules each). BBMP, BMC, MCD packs extended with safety overrides. |
| 2026-05-22 | **SocietyPolicyOverride model** | `lib/models/society_policy_override.dart` | Society-level policy delta model with Firestore serialization, typed `RuleOverride` (binColor, collectionFrequency, disposalMethod, bannedItem, customInstruction), `SocietyAwareDecision`. |
| 2026-05-22 | **City research playbook** | `docs/playbooks/CITY_RULES_RESEARCH.md` | Standardised new-city research process: source hierarchy, field template, code mapping, governance rules, PR checklist. Enables contributor-driven city expansion. |
| 2026-05-22 | **Source freshness + GPS UX designs** | `docs/exploration/SOURCE_FRESHNESS_MONITORING.md` + `docs/exploration/GPS_REGION_SELECTION_UX.md` | Source freshness: manual calendar (≤15 cities), automated HTTP ETag Action (15+). GPS UX: hybrid GPS+manual picker, edge case coverage (boundary, travel, offline, unsupported). |
| 2026-05-22 | **Test suite: 32 tests across 3 files** | `test/services/local_policy_engine_test.dart` + `local_guidelines_manager_routing_test.dart` + `local_policy_rule_packs_test.dart` | 32 passing: 7-city routing, safetyOverride, confidence gating thresholds, provenance, confidenceGated flag, unsupported fallback. BBMP custom compliance preserved. |

(Append new rows here; never delete — the trail is the value.)
