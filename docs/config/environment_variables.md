# Environment Variables

Last updated: 2026-05-20 22:50 IST
Status: Active (P0 hardening baseline)

## Purpose
This document is the canonical env/config contract for AI, billing, and Firebase behavior.
Do not hardcode secrets in Dart/JS/TS files.

## 1) Client (Flutter, compile-time dart-defines)
Set via --dart-define or CI build config.

Required:
- OPENAI_API_KEY
  - Default must stay placeholder in code.
  - Client-side direct OpenAI calls are blocked in release unless explicitly allowed.
- GEMINI_API_KEY
  - Default must stay placeholder in code.
  - Client-side direct Gemini calls are blocked in release unless explicitly allowed.

Optional model selection:
- OPENAI_API_MODEL_PRIMARY (default: gpt-4.1-nano)
- OPENAI_API_MODEL_SECONDARY (default: gpt-4o-mini)
- OPENAI_API_MODEL_TERTIARY (default: gpt-4.1-mini)
- GEMINI_API_MODEL (default: gemini-2.0-flash)

Safety toggles:
- ALLOW_CLIENT_AI_IN_RELEASE
  - false/omitted: blocks direct provider calls in release builds.
  - true: allows direct provider calls (private/internal testing only).
- USE_BACKEND_AI_IN_RELEASE
  - Forward-compat toggle for backend-only classification flow.

Token economy / quota toggles:
- ENABLE_TOKEN_ENFORCEMENT
- ENABLE_SERVER_SIDE_VALIDATION

## 2) Firebase Functions / Backend (runtime env)
Preferred source: process.env
Legacy fallback: functions.config() (temporary migration bridge only)

Required:
- OPENAI_API_KEY

Optional aliases supported by current bridge:
- OPENAI_KEY

Diagnostics / safety:
- ENABLE_DIAGNOSTIC_ENDPOINTS=true  (only in controlled environments)
- CLEAR_ALL_DATA_ENABLED=true       (only in controlled environments, admin-gated)

## 3) Migration policy: functions.config() -> process.env
Current backend code keeps a low-risk compatibility bridge:
- First read process.env (OPENAI_API_KEY / OPENAI_KEY)
- Then fallback to functions.config().openai.key/api_key

Action required:
1. Provision OPENAI_API_KEY in all environments.
2. Verify deployments run without dependency on functions.config().
3. Remove legacy fallback after rollout stability window.

## 4) Security rules
- Never commit real keys/tokens in source.
- Never print secrets in logs.
- If a secret is observed in code, rotate it and replace with placeholder.
- Keep all production values in secure secret stores / CI env config.

## 5) Quick validation checklist
- Flutter release build without ALLOW_CLIENT_AI_IN_RELEASE blocks direct AI provider calls.
- Backend endpoints can access OPENAI_API_KEY via process.env.
- testOpenAI reflects configured status without leaking key values.
- No hardcoded API keys in repo.
