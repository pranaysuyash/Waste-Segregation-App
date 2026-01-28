# AI Race Fault Tolerance (analyzeWithRace)

**Purpose:**
Document the new opt-in `analyzeWithRace` method that runs OpenAI and Gemini in parallel and returns the first successful result. This is non-breaking and intended for A/B testing before making it the default path.

Status: ✅ Implemented (27 Jan 2026)

---

## Behavior

- Compresses the image before sending (uses existing `_compressImage`).
- Starts both OpenAI and Gemini requests in parallel with a configurable timeout (default: 15s).
- Returns the winning `WasteClassification` (first completed future).
- If both requests fail or time out, returns `WasteClassification.fallback(imageName)`.
- Records model usage success/failure for telemetry.

## API

- Method signature (in `EnhancedAiApiService`):

```dart
Future<WasteClassification> analyzeWithRace({
  required Uint8List imageBytes,
  required String imageName,
  String? region,
  String? language,
  String? preferredModel,
  bool enableSegmentation = false,
  Duration timeout = const Duration(seconds: 15),
})
```

- Opt-in A/B routing is supported via `setRacePercentage(double)` on the same service instance. Provide a value between `0.0` and `1.0` (e.g., `0.5` for 50/50 routing).

## Telemetry

- Logs:
  - `A/B routing: using race-based analysis` (when routing occurs)
  - `Race analysis completed` with `winner_model` and `image_name` context
  - `Race analysis: both services failed` on dual failure
- Model usage is recorded with `_recordModelUsage(model, success: true/false)` for post-hoc analysis.

## Notes & Caveats

- Running both services in parallel may increase total token consumption if both services still bill for in-flight requests; monitor cost if you raise test percentage above ~50% or enable it in production.
- Timeouts should be conservative (12–20s) until you gather realistic latency metrics in your region and infra.

---

## Quick Start

1. In staging, set `aiService.setRacePercentage(0.5);` to route ~50% traffic to the race method.
2. Run the `docs/smoke_tests/ai_race_ab_test.md` checklist.
3. Compare latency/success metrics and decide whether to increase percentage or make this the default.
