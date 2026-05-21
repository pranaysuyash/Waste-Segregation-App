# Environment Variables

Last updated: 2026-05-21 01:38 IST
Status: Active (P0 monetization hardening + release-safe backend routing)

## Purpose
Canonical env/config contract for AI, Firebase, and release safety behavior.
Do not hardcode secrets in Dart/JS/TS files.

## 1) Client app (Flutter, compile-time dart-defines)
Source: `--dart-define` / CI build config.

### Firebase Web (required for web builds)
These are consumed by `lib/config/firebase_options.dart`.
- FIREBASE_WEB_API_KEY
- FIREBASE_WEB_APP_ID
- FIREBASE_PROJECT_ID
- FIREBASE_AUTH_DOMAIN
- FIREBASE_STORAGE_BUCKET
- FIREBASE_MEASUREMENT_ID

App Check web attestation:
- APPCHECK_WEB_RECAPTCHA_SITE_KEY (required for web release builds that initialize App Check)

Important:
- `web/index.html` must not initialize Firebase with static/placeholder keys.
- Firebase initialization must come from Dart (`DefaultFirebaseOptions.currentPlatform`).
- If you run web locally without a real App Check site key, keep the build in debug/profile and use the Firebase App Check debug-provider flow documented by Firebase.

### AI keys (required only for direct client-AI paths)
- OPENAI_API_KEY
- GEMINI_API_KEY

Release safety behavior (`lib/utils/production_safety_config.dart` + `lib/services/ai_service.dart`):
- Release build routes classification through backend callable path (fail-closed).
- Direct client provider calls are blocked by default in release.
- To allow direct client provider calls in release (private/internal testing only):
  - ALLOW_CLIENT_AI_IN_RELEASE=true
- Optional explicit backend routing define (debug/profile opt-in and release documentation alignment):
  - USE_BACKEND_AI_IN_RELEASE=true

Model selection overrides (optional):
- OPENAI_API_MODEL_PRIMARY (default: gpt-4.1-nano)
- OPENAI_API_MODEL_SECONDARY (default: gpt-4o-mini)
- OPENAI_API_MODEL_TERTIARY (default: gpt-4.1-mini)
- GEMINI_API_MODEL (default: gemini-2.0-flash)

Token-economy toggles (optional):
- ENABLE_TOKEN_ENFORCEMENT
- ENABLE_SERVER_SIDE_VALIDATION

## 2) Firebase Functions / Backend runtime env
Preferred source: process.env only

Required:
- OPENAI_API_KEY
- GEMINI_API_KEY
- TRAINING_DATA_HMAC_SECRET

Optional alias kept for backward compatibility:
- OPENAI_KEY

Diagnostics/safety toggles:
- ENABLE_DIAGNOSTIC_ENDPOINTS=true (controlled env only)
- CLEAR_ALL_DATA_ENABLED=true (controlled env only, admin-gated)
- REQUIRE_APPCHECK_CALLABLE=true (required in production)
- ENFORCE_APPCHECK_IN_EMULATOR=false (optional local override)

Operational reconciliation toggles:
- CLASSIFY_RESERVATION_STALE_MINUTES=30 (default; stale-reservation alert threshold for `classify_token_reservations`)

Classification monetization controls:
- CLASSIFY_ENFORCE_TOKEN_SPEND=true (default true; fail-closed)
- CLASSIFY_IMAGE_TOKEN_COST=5
- CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT=50
- CLASSIFY_IMAGE_MAX_REQUESTS=10
- CLASSIFY_IMAGE_WINDOW_SECONDS=60
- CLASSIFY_CACHE_TTL_SECONDS=86400

## 3) Backend migration policy
The backend now resolves secrets from environment variables only.

Required closure steps:
1. Provision `OPENAI_API_KEY`, `GEMINI_API_KEY`, and `TRAINING_DATA_HMAC_SECRET` across all environments.
2. Keep diagnostics and destructive operations env-gated.
3. Avoid reintroducing `functions.config()` for secret resolution.

## 4) Security rules
- Never commit real keys/tokens in source.
- Never print full secrets in logs.
- If a secret is exposed in source, rotate and migrate immediately.
- Keep production values in secure secret stores / CI environment config.

## 5) Validation checklist
- Flutter release build without ALLOW_CLIENT_AI_IN_RELEASE blocks direct client AI calls.
- Web Firebase initialization succeeds via Dart-defined options (not manual HTML config).
- Backend resolves secret values from process.env.
- `npm --prefix functions run test:key-resolution` passes.
- No hardcoded provider keys remain in repo source.
