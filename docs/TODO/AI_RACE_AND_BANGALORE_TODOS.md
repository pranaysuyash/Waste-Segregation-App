# TODOs — AI Race A/B + Bangalore Rules & Feedback Loop

**Created:** 2026-01-27
**Updated:** 2026-01-27 (Track 1 & 2 implemented)
**Purpose:** Capture the two prioritized tasks as actionable todos with clear owners, acceptance criteria and smoke tests.

---

## ✅ IMPLEMENTED: Image Quality Gate & Offline Queue

**Status:** Ready for integration testing  
**Files Added:**
- `lib/services/image_quality_gate.dart` — Pre-flight quality checks (resolution, blur, brightness)
- `lib/services/offline_queue_service.dart` — Hive-backed offline classification queue
- `test/services/image_quality_gate_test.dart` — Unit tests for quality gate
- `test/services/offline_queue_service_test.dart` — Unit tests for offline queue

**Improvements Made:**
- Configurable thresholds for all quality checks
- Fail-open design (allow image if check crashes)
- Sampling optimization (checks every 4th/8th pixel for performance)
- Multiple image format support (JPG, PNG, generic fallback)
- Comprehensive logging and analytics integration
- Stream-based queue count updates for real-time UI
- Retry logic with max 3 attempts
- User-initiated force retry and queue clearing

**Next Steps:**
- [ ] Integrate quality gate into capture flow (see integration example below)
- [ ] Add offline queue UI (badge + dialog)
- [ ] Test on device with real images
- [ ] Monitor analytics for quality rejection rates

---

## TODO-001: Enable A/B 50% routing to `analyzeWithRace` in staging
Priority: High ✅
Owner: @dev (replace with actual assignee)
ETA: Today (staging deploy) / 72 hours + 3 days of sampling

Checklist:
- [ ] Set `aiService.setRacePercentage(0.5)` in staging configuration (or via a debug/dev flag)
- [ ] Deploy staging build with telemetry enabled
- [ ] Run the smoke test harness using `docs/smoke_tests/ai_race_ab_test.md` (500–1000 requests across image sizes)
- [ ] Collect logs and metrics (latency p50/p90/p99, success rate, winner model distribution, approximate cost delta)
- [ ] Review metrics after 72 hours and decide: keep sequential, promote race to higher percentage, or revert
- [ ] If metrics are good, plan progressive rollout: 0.5 → 0.8 → 1.0 (with cost sign-off)

Acceptance criteria:
- Race method median latency < sequential median latency OR success rate significantly improved during partial outages
- No increase in parse failures or unexpected error rates
- Cost delta acceptable at 50% traffic

Notes & artifacts:
- See: `docs/AI_API_RACE_FAULT_TOLERANCE.md` (usage) and `docs/smoke_tests/ai_race_ab_test.md` (smoke checklist)

---

## TODO-002: Implement Bangalore rules + Thumbs up/down feedback UI (capture corrections)
Priority: High ✅
Owner: @product / @frontend / @backend (split work between UI and backend)
ETA: 2–4 days (small incremental rollout)

Checklist:
- [ ] Add `lib/services/bangalore_waste_service.dart` (rules engine) with a small set of verified rules (pizza, styrofoam, batteries, e-waste, plastic bag)
- [ ] Add `BbmpRule` definitions with `verified` flag and `source` placeholder for research steps
- [ ] Wire `BangaloreWasteService.applyRules(...)` in the classification flow (one-line injection before navigating to ResultScreen)
- [ ] Add thumbs up / thumbs down UI to `ResultScreen` (or use `classification_feedback_widget.dart`), immediate local UI update and lightweight Firestore persistence (collection: `classification_feedback`) — see snippet in `docs/notes/Bangalore_and_Feedback.md` (if exists) or use provided example
- [ ] Award gamification points: +5 confirm, +10 correction (use `GamificationService`)
- [ ] Save feedback with compressed image URL, image hash, AI prediction, user correction, user id, timestamp
- [ ] Add firestore security rule allowing authenticated users to create feedback docs only (read restricted to owner)
- [ ] Add in-app indicator for BBMP rule application (small badge) and a subtle "Unverified" banner if rule lacks a verified source
- [ ] Add a small analytics event `classification.feedback` including `is_correct`, `corrected_to`, `bbmp_rule_applied`

Acceptance criteria:
- Users can submit corrections and corrections appear in `classification_feedback` Firestore collection
- BBMP overrides apply for pizza boxes, batteries, styrofoam and produce correct UI badge
- Feedback UI awards points and does not block core flow if Firestore fails (fail silently)
- Corrections include image hash or compressed image URL for future offline model training

Research & verification tasks (must be done before shipping widely):
- [ ] Verify BBMP rules against official BBMP sources for any rule that claims fines or helplines
- [ ] Mark unverified rules with UI disclaimer until verified

Notes & artifacts:
- Example service and UI snippets were provided in earlier proposal (use these as implementation source)

---

## Reporting & Follow-up
- Create a small dashboard (Grafana/Datadog/Console) to compare race vs sequential metrics (latency, success rate, cost) after A/B run
- Export corrections (Firestore `classification_feedback`) weekly and tag for manual review; this forms the training dataset

---

If you want, I can: (A) enable 50% routing in staging and add the smoke-test job that runs the 500 requests and collects metrics automatically, and (B) scaffold `lib/services/bangalore_waste_service.dart` + ResultScreen feedback UI boilerplate in the next PR.

Which part should I start coding first? (I recommend enabling 50% staging routing now to collect benchmarks.)
