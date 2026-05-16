# TODOs — AI Race A/B + Bangalore Rules & Feedback Loop

**Created:** 2026-01-27
**Updated:** 2026-05-15 (Result screen consolidation + feedback pipeline completed)
**Purpose:** Capture the two prioritized tasks as actionable todos with clear owners, acceptance criteria and smoke tests.

---

## ✅ INTEGRATED: Image Quality Gate & Offline Queue → Capture Flow

**Status:** ✅ DONE (verified working)
**Integration Complete:** See [TRACK_1_2_CAPTURE_FLOW_INTEGRATION.md](../TRACK_1_2_CAPTURE_FLOW_INTEGRATION.md)

**What Was Integrated:**
- Quality gate check before API analysis
- Offline queue fallback when connectivity drops
- AppBar indicators for real-time connectivity/queue status
- Quality check dialog for user feedback
- Automatic queue processing when connectivity returns

---

## ✅ DONE: A/B 50% routing infrastructure (code exists)

**Status:** ✅ Code complete — `EnhancedAiApiService.setRacePercentage()` exists at `lib/services/enhanced_ai_api_service.dart:38-40`.  
**Routing currently at 0.0%.** `_racePercentage` must be set to 0.5 in staging config to activate.  
**Note:** Doc referenced `AiService` — the method lives on `EnhancedAiApiService`.

Checklist:
- [x] `setRacePercentage()` method implemented
- [x] Smoke test plan: `docs/smoke_tests/ai_race_ab_test.md`
- [x] Fault tolerance design: `docs/AI_API_RACE_FAULT_TOLERANCE.md`
- [ ] Set `aiService.setRacePercentage(0.5)` in staging configuration
- [ ] Deploy staging build with telemetry enabled
- [ ] Run smoke test harness (500–1000 requests across image sizes)
- [ ] Review metrics after 72 hours and decide

---

## ✅ DONE: Bangalore rules + Feedback UI (canonical pipeline)

**Status:** ✅ All integrated into the canonical `ResultScreen` via `ResultPipeline`.

The following is now **live in the canonical result screen** (`lib/screens/result_screen.dart`, Riverpod-based):

- **Feedback pipeline**: `CorrectionDialog` (`lib/widgets/correction_dialog.dart`) with thumbs up/down, category chips, custom correction, notes
- **ResultPipeline.submitFeedback()**: saves classification + `ClassificationFeedback` record → local storage → (if enabled) Firestore sync → awards points → tracks `classification.feedback` analytics event
- **GamificationService._pointValues**: `feedback_provided: 5`, `correction_provided: 10` added
- **Firestore rules**: `classification_feedback` collection now has create-by-auth-user, read-owner-only security rules
- **BBMP/Bangalore plugin**: Already existed as `BBMPBangalorePlugin` in `lib/services/local_guidelines_plugin.dart` (not `bangalore_waste_service.dart` as doc originally said)
- **Classification tags**: Extracted to `lib/utils/classification_tags.dart` — includes environmental impact, local information (BBMP schedules), urgency, and educational tips

**Files affected:**
- `lib/screens/result_screen.dart` — canonical screen, Riverpod-based, ~1579 lines
- `lib/widgets/correction_dialog.dart` — new Riverpod-native correction dialog
- `lib/services/result_pipeline.dart` — added `submitFeedback()` method
- `lib/services/gamification_service.dart` — added `feedback_provided`, `correction_provided` entries + public `pointValues` accessor
- `lib/utils/classification_tags.dart` — extracted tag-building functions
- `lib/screens/result_screen_wrapper.dart` — simplified pass-through (v1 deleted, v2 renamed to canonical)
- `firestore.rules` — added security rule for `classification_feedback`
- Deleted: `lib/viewmodels/result_screen_viewmodel.dart`, `lib/widgets/classification_feedback_widget.dart`

---

## Reporting & Follow-up

- Create a small dashboard (Grafana/Datadog/Console) to compare race vs sequential metrics after A/B run
- Export corrections (Firestore `classification_feedback`) weekly and tag for manual review; this forms the training dataset
