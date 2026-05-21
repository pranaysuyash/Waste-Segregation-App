# Provider Secret Paths + Release Guard Audit (Phase 3)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app

## Executive verdict
- Secret-path posture is mostly correct (env/dart-define based, placeholder defaults).
- One high-risk web bootstrap anti-pattern was fixed in this run (`web/index.html`).
- Functions still intentionally carry `functions.config()` fallback as migration bridge.

## Scope audited
- `lib/utils/constants.dart`
- `lib/utils/production_safety_config.dart`
- `lib/services/ai_service.dart`
- `lib/services/providers/openai_provider_client.dart`
- `lib/services/api_client_factory.dart`
- `lib/main.dart`
- `functions/src/index.ts`
- `functions/batch_processor.js`
- `docs/config/environment_variables.md`
- `web/index.html`

## Findings

### F1) Client keys are compile-time env with placeholder defaults
Evidence:
- `lib/utils/constants.dart:14-15` OPENAI key from `String.fromEnvironment` with placeholder default.
- `lib/utils/constants.dart:37-38` GEMINI key from `String.fromEnvironment` with placeholder default.

Assessment: GOOD.

### F2) Release guard exists and is wired
Evidence:
- `lib/utils/production_safety_config.dart:19-23` release-mode gating.
- `lib/utils/production_safety_config.dart:54-66` blocking guard call behavior.
- Call sites in `lib/services/ai_service.dart` and `lib/services/providers/openai_provider_client.dart`.

Assessment: GOOD.

### F3) Placeholder key hard-fail exists
Evidence:
- `lib/services/ai_service.dart:1230,1404,1645,1678`
- `lib/services/providers/openai_provider_client.dart:53-54`

Assessment: GOOD.

### F4) Functions key precedence
Evidence:
- `functions/src/index.ts:18-22`
- precedence: `OPENAI_API_KEY` -> `OPENAI_KEY` -> `functions.config().openai.*`

Assessment: ACCEPTABLE TEMPORARILY.
Risk: legacy fallback should be retired once env rollout is confirmed.

### F5) Web static Firebase config path removed
Evidence:
- `web/index.html` no longer contains manual Firebase JS initialization blocks.

Assessment: FIXED.

## Documentation correction applied
`docs/config/environment_variables.md` updated to:
- include required Firebase web dart-defines explicitly,
- align release guard wording with actual code behavior,
- state that `web/index.html` must not initialize Firebase manually.

## Residual risks
1. `functions.config()` bridge still present in functions code.
2. No automated guard test yet to prevent reintroducing static Firebase config in web HTML.
3. Ad consent path is still TODO and intersects with production privacy compliance.

## Recommended closure actions
1. Keep `test:key-resolution` passing and extend with fallback-removal transition test.
2. Add a lightweight CI grep check to fail on `firebase.initializeApp(` in `web/index.html`.
3. Complete consent automation before production ad rollout.
