# May End — Release Safety Guard

## Problem

Client-side AI API keys (OpenAI, Gemini) are embedded in release builds via
`String.fromEnvironment`.  Even though `.env` is gitignored, the keys end up in
the compiled APK/IPA where they can be extracted by anyone who unpacks the
binary.  This is a **P0 production blocker**.

## Solution

A compile-time flag gates all client-side direct HTTP calls to AI providers.
In release builds with the default configuration, these calls throw a
controlled `ProductionSafetyException` instead of reaching the provider.
The existing `WasteClassification.fallback` path handles the exception
gracefully — the user sees a fallback message rather than a crash or leak.

## Guard Mechanism

- `lib/utils/production_safety_config.dart` — `ProductionSafetyConfig` class
- Compile-time flag: `--dart-define=ALLOW_CLIENT_AI_IN_RELEASE=true`
  - Default: `false` (release builds block client AI)
  - Debug/Profile builds: always allowed (no behaviour change)
- `guardClientAiCall(providerLabel)` — throws `ProductionSafetyException`
  if the call is not permitted in the current build mode.

## Guarded Methods

| Method | Provider Label |
|---|---|
| `_analyzeWithOpenAI` | `OpenAI` |
| `_analyzeWithGemini` | `Gemini` |
| `_analyzeWithOpenAISegments` | (delegates to `_analyzeWithOpenAI`) |
| `handleUserCorrection` | `OpenAI (correction)` |

## Exception Handling

- `analyzeImage` and `analyzeWebImage` catch `ProductionSafetyException` in
  the OpenAI `on Exception` handler and **rethrow immediately** — no retry
  loop, no Gemini fallback attempt.
- The outer `catch (e, s)` returns `WasteClassification.fallback`.
- `handleUserCorrection` catches via its own `catch (e)` and returns the
  original classification with `clarificationNeeded: true`.

## Startup Logging

`AiService.initialize()` calls `_logAiConfigState()` which logs (suffix-only,
no full keys):
- Provider mode (`CLIENT-SIDE (allowed)` / `CLIENT-SIDE (BLOCKED in release)`)
- Last 4 characters of each API key
- Release guard status (`ACTIVE` / `disabled (debug)`)

## Future

- `useBackendAiInRelease` flag exists in `ProductionSafetyConfig` for forward
  compatibility with a backend proxy that would handle keys server-side.
- Backend migration is tracked separately (Batch 3 in the launch plan).
