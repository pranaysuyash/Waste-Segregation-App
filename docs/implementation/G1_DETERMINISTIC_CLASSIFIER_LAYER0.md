# G1: Deterministic Pre-processing Classifier (Layer 0)

## Context

Layer 0 is a zero-AI classification layer that intercepts the image analysis flow before any cloud AI call. It handles ~30-40% of real-world single-item scans with zero AI cost and zero privacy exposure (nothing leaves the device).

Two sub-paths:
1. **Color histogram analysis** — HSV histogram on the captured image maps to waste categories
2. **Barcode → product DB lookup** — Open Food Facts API maps product packaging to waste categories

The existing codebase already has the extension points: `LocalClassifier` abstract class, `localClassifying` state machine state, and a gap in `_analyzeImage()` between quality gate and cloud classification.

## New Files

### 1. `lib/services/color_histogram_classifier.dart`
- Implements `LocalClassifier` from `local_classifier_service.dart`
- `modelId = 'color_histogram_v1'`, always loaded (no model file)
- `classify()`: decodes image → downsamples to 256px max → computes HSV histogram (12 hue bins × 4 saturation bins × 4 value bins) → maps dominant bin to category
- Runs in isolate via `compute()` (top-level function `_computeHistogramInIsolate`)
- Color mapping: green/brown → Wet Waste (0.75-0.85 confidence), high saturation → Dry Waste/packaging (0.65), clear glass → Dry Waste (0.55), mixed/ambiguous → reject (< 0.40)
- Confidence based on peak dominance: top bin > 60% of pixels = high, 40-60% = medium, < 40% = reject

### 2. `lib/services/barcode_lookup_service.dart`
- Standalone service (NOT a `LocalClassifier` — takes barcode string, not image bytes)
- `lookup(String barcode, {String region})` → `BarcodeLookupResult`
- Open Food Facts API: `GET https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
- 3-second timeout, fast-fail on network error
- In-memory LRU cache (500 entries, 7-day TTL)
- Maps `packaging_tags` → waste category (plastic-bottle → Dry Waste, cardboard → Dry Waste)
- Maps `categories_tags` → waste category for food items (beverages → Wet Waste, fruits → Wet Waste)

### 3. `lib/services/layer0_disposal_mapping.dart`
- Hardcoded disposal instructions for ~20 common waste subcategories
- Allows Layer 0 accepted results to produce a full `WasteClassification` without AI
- Covers: plastic bottle, glass bottle, cardboard, paper, food scraps, organic, metal can, etc.

### 4. `lib/services/layer0_router.dart`
- `Layer0Router` orchestrates both sub-paths
- `classify({imageBytes, barcode, region})` → `Layer0Result`
- `Layer0Decision` enum: `accept`, `hint`, `escalate`, `reject`
- Logic: barcode first (if provided) → color histogram → decide
- Accept at confidence >= 0.90 (non-safety), escalate safety categories always
- When `accept`, builds full `WasteClassification` using `layer0_disposal_mapping.dart`
- Sets `modelSource = 'layer0_deterministic'` on results

### 5. `lib/providers/layer0_providers.dart`
- Riverpod providers: `colorHistogramClassifierProvider`, `barcodeLookupServiceProvider`, `layer0RouterProvider`
- `layer0EnabledProvider` reads from remote config

### 6. Test files
- `test/services/color_histogram_classifier_test.dart` — synthetic images (solid green, brown, white, multi-color)
- `test/services/barcode_lookup_service_test.dart` — mapping logic, caching, error handling
- `test/services/layer0_router_test.dart` — accept/hint/escalate/reject decisions
- `test/services/layer0_disposal_mapping_test.dart` — mapping completeness

## Existing Files to Modify

### 7. `lib/models/classification_state.dart`
- Add `cloudClassifying` as legal transition from `localClassifying` (for Layer 0 fallback to AI)
- One line addition in `kClassificationTransitions`

### 8. `lib/services/remote_config_service.dart`
- Add `layer0_enabled: true`, `layer0_color_histogram_enabled: true`, `layer0_barcode_lookup_enabled: true` to `setDefaults()`

### 9. `lib/screens/image_capture_screen.dart`
- Insert Layer 0 check between offline queue handling (~line 765) and quota re-check (~line 770)
- Transition to `localClassifying` state
- If `Layer0Decision.accept` → skip AI, show result immediately
- If reject/escalate → fall through to existing cloud classification
- ~30 lines of new code

## Implementation Order

1. Color histogram classifier + tests
2. Barcode lookup service + tests
3. Disposal mapping + tests
4. Layer 0 router + tests
5. Providers + remote config
6. State machine transition
7. Image capture screen integration
8. Full test suite run

## Key Decisions

- **No tokens deducted when Layer 0 accepts** — control flow returns early before cloud call, skipping token deduction naturally
- **Feature flag defaults to `true`** — conservative thresholds + remote kill switch
- **Safety categories always escalate** — even barcode-identified batteries/pharmaceuticals go through AI
- **`compute()` for color histogram** — guarantees no UI jank even on slow devices
- **`http` package for barcode lookup** — simpler than Dio for a single GET request
- **Barcode service is standalone** — not shoehorned into `LocalClassifier` interface (different input type)

## Verification

1. `flutter analyze` — zero new errors
2. `flutter test` — all existing tests pass + new tests pass
3. Manual test: capture image → verify Layer 0 runs before cloud classification
4. Check logs for `Layer 0 accepted classification` or `Layer 0 error, falling back to AI`
5. Verify token balance unchanged when Layer 0 accepts
