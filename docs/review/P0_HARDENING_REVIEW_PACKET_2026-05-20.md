# P0 Hardening Review Packet (for review)

Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Date: 2026-05-20
Scope: firebase_task.md active list t1-t7 (executed under motto_v2 + AGENTS stack)

## 1) Executive conclusion
P0 hardening execution for t1-t7 is complete.
No blocking gap remains inside this scope.
Root `CLAUDE.md` was intentionally not handled per user direction.

## 2) What changed

### A) Security hardening
- Client-side AI call guards and placeholder-key blocking are enforced in:
  - lib/services/api_client_factory.dart
  - lib/services/providers/openai_provider_client.dart
  - lib/services/ai_service.dart

### B) Correct fallback semantics
- Fallback labeling standardized to:
  - `Unidentified Item - Fallback`
- File:
  - lib/services/ai_service.dart

### C) Quota race-window reduction
- Added second affordability preflight right before network analysis path.
- File:
  - lib/screens/image_capture_screen.dart

### D) Ads/premium consistency
- Ad premium state now synced using `hasActivePremiumPlan()`.
- Files:
  - lib/utils/service_sync.dart
  - lib/widgets/banner_ad_widget.dart

### E) Backend secret migration bridge
- Added env-first OpenAI key resolution helper + explicit missing-key guards.
- Files:
  - functions/src/index.ts
  - functions/batch_processor.js

### F) Documentation baselines
- Added/confirmed:
  - docs/config/environment_variables.md
  - AGENTS.md (repo root)

### G) Exploration backlog reconciliation
- Added P0 hardening follow-up lines in:
  - docs/exploration/backlog.md
- Cross-links to EXPLORATION_TOPICS:
  - #10 AI Cost Telemetry & Guardrails
  - #27a Token Economy & Pricing Coherence
  - #32 Privacy / Photo PII

## 3) Validation evidence

Executed commands:
1. `flutter test test/utils/constants_test.dart` -> PASS
2. `npm --prefix functions run test:http-guards` -> PASS
3. `flutter test test/services/ai_service_test.dart` -> PASS (after fixture update for new placeholder-block behavior)
4. `npm --prefix functions run test:http-guards:emulator` -> PASS
5. `flutter analyze <touched-files>` -> non-zero due pre-existing warnings/info; no new blocking error introduced by patch set

## 4) Required-file + keyword verification snapshot
- Required paths checked: 40
- Present: 38
- Missing:
  - storage.rules (optional in checklist)
  - CLAUDE.md (ignored per user direction)

Scoped keyword findings:
- `functions.config(` in functions code: 9
- Authorization Bearer pattern: 4 (test harness)
- local-model/on-device/tflite/offline-model in lib: 57
- addendum references: present in strategy docs

## 5) Review checklist (what reviewer should verify)
1. Guard behavior: direct provider calls should fail with placeholder keys in release-protected paths.
2. Fallback behavior: logs and returned fallback label are consistent.
3. Quota behavior: second preflight blocks late insufficient-balance attempts.
4. Ads behavior: premium users are consistently ad-suppressed via active plan check.
5. Backend behavior: OpenAI key resolution prefers env and fails explicitly when missing.
6. Tests: all four listed test commands pass in reviewer environment.
7. Analyzer output: only known pre-existing warnings remain; no introduced hard errors.

## 6) Recommended next implementation slice (post-review)
1. Implement App Check wiring (client + backend verification points).
2. Add explicit rate-limiting for paid AI endpoints.
3. Retire `functions.config()` fallback once env rollout is confirmed across environments.
4. Add dedicated unit test for key-resolution precedence in functions layer.

## 7) Canonical detailed report
For full step-by-step evidence and patch inventory:
- docs/review/P0_HARDENING_EXECUTION_REPORT_2026-05-20.md
