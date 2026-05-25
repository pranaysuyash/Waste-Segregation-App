# Deterministic Pre-processing Classifier

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (G1)
**Related**: [BACKEND_CLASSIFICATION_PROXY.md](BACKEND_CLASSIFICATION_PROXY.md), [CONFIDENCE_THRESHOLD_TUNING.md](CONFIDENCE_THRESHOLD_TUNING.md), [LOCAL_FIRST_PRIVACY_ARCHITECTURE.md](LOCAL_FIRST_PRIVACY_ARCHITECTURE.md), [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md)

---

## Why This Matters

Layer 0 of the 4-layer cascade handles items **without any AI inference**. Two sub-paths:

1. **Barcode scan → product DB lookup**: zero-cost, zero-latency classification for labelled consumer products
2. **Color histogram → broad category**: instant material classification for visually unambiguous items

**Expected coverage**: ~30-40% of real-world single-item scans handled at this layer before any model is invoked. Zero AI cost, zero latency to cloud, zero privacy concern (no image transmission).

Barcode scanner (`mobile_scanner`) is already in `pubspec.yaml` but disabled (dependency conflict). Color histogram path doesn't exist yet.

---

## Research Summary

### Barcode + Product DB Pattern

Open Food Facts is the primary candidate for product database lookup:

| Database | Products | Cost | Coverage | Offline |
|----------|----------|------|----------|---------|
| Open Food Facts | ~3M products | Free | Best for food/beverage/packaged goods | Requires cache |
| Custom local DB | As curated | Dev cost | Limited but controlled | Full offline |
| EU DPP resolver | Emerging (2026+) | Unknown | Future — ESPR mandate | Unknown |

**Open Food Facts API**: `GET https://world.openfoodfacts.org/api/v2/product/{barcode}` returns product name, categories, packaging materials. For waste classification, the `packaging` field tells us material composition.

**Coverage estimate**: In developed markets, ~60-70% of packaged consumer goods have barcodes. Not all of these will be in Open Food Facts. Realistic hit rate: 40-50% for packaged items. For all waste (including non-packaged): ~20-30%.

### Color Histogram Methodology

HSV histogram classification works for items with unambiguous color-to-material mappings:

| Material | Typical HSV Range | Ambiguity Risk |
|----------|------------------|----------------|
| Clear PET (plastic bottle) | Near-white, low saturation | Low — unique translucence |
| Green glass | Green hue, moderate saturation | Medium — green plastic looks similar |
| Brown glass | Brown hue, moderate saturation | Low — plastic rarely brown |
| Newspaper/newsprint | Yellow-gray, low saturation | Medium — aged paper vs cardboard |
| Cardboard | Brown, low-moderate saturation | Medium — brown plastic confusion |
| Organic (banana peel) | Yellow-green-brown, moderate sat | Low — distinct from synthetics |
| Aluminum can | Silver/metallic reflection | Medium — reflective surfaces vary |

**Key challenge**: Mixed-material items (cap + bottle, label + container) confound histogram approaches. Resolution: classify only when >90% of pixels fit one material profile.

### Barcode Detection for Partially Visible Codes

Mobile barcode scanners (`mobile_scanner`, `google_mlkit_barcode_scanning`) handle:
- Damaged/creased barcodes (error correction codes)
- Partially visible codes
- Multi-barcode scenes (scan all visible)
- QR codes (for future DPP integration)

**Current blocker**: `mobile_scanner` dependency conflict prevents integration. Need to resolve version compatibility or switch to `google_mlkit_barcode_scanning`.

### Expected Coverage by Setting

| Setting | Barcode Coverage | Histogram Coverage | Total L0 Coverage |
|---------|-----------------|-------------------|-------------------|
| Kitchen (packaged goods) | 40-50% | 10-15% | 50-65% |
| Recycling pile | 10-20% | 30-40% | 40-60% |
| Household cleanout | 20-30% | 20-25% | 40-55% |
| Electronics/e-waste | 5-10% | 5-10% | 10-20% |
| Outdoor/street | 5-10% | 15-25% | 20-35% |

---

## Implementation Design

### Layer 0 Router

```
[Image Capture]
    ↓
[Barcode Detection] ──→ [Product DB Lookup] ──→ [Classification + Confidence]
    ↓ (no barcode or no match)
[Color Histogram] ──→ [Material Match] ──→ [Classification + Confidence]
    ↓ (ambiguous)
[Escalate to Layer 1+]
```

### Proposed Confidence Thresholds

| Sub-path | Pass Threshold | Notes |
|----------|---------------|-------|
| Barcode → exact product match | 0.95+ | DB result + material mapping gives near-certainty |
| Barcode → category-only match | 0.85 | Product found but material mapping ambiguous |
| Histogram → clear material | 0.90 | High confidence for unambiguous colors |
| Histogram → ambiguous | <0.90 | Escalate to Layer 1 (on-device VLM) |

### Barcode Integration

1. Resolve `mobile_scanner` dependency conflict or migrate to `google_mlkit_barcode_scanning`
2. Create `BarcodeClassifier` service:
   - Detect barcode from camera frame
   - Look up in Open Food Facts API (with local cache)
   - Map product categories to waste classification
   - Cache results for offline repeat scans
3. Open Food Facts caching: LRU cache (1000 entries), 24h TTL

### Color Histogram Integration

1. Create `HistogramClassifier` service:
   - Compute HSV histogram from captured image
   - Compare against pre-defined material profiles
   - Calculate confidence from histogram overlap
   - Scale to ~200x200 for performance
2. Material profiles defined in `histogram_profiles.json` (build-time asset)
3. Initial 6-8 material profiles, expandable as data accumulates

---

## Open Questions

1. What's the correct fallback UX when L0 partially matches? (E.g., "This looks like a plastic bottle, but I'm not sure. Check with AI?")
2. Should L0 results be labelled differently in the result UI (e.g., "Estimated" vs "AI-verified")?
3. How does L0 interact with offline queue — are L0 matches always immediate, or do they still require sync?
4. Should barcode lookup include retail inventory data (weighted by local market popularity) for better coverage?
5. How do we handle products where barcode lookup returns "unknown" but user has scanned it before (user-created product entries)?

---

## What Could Kill This

- Dependency conflict cannot be resolved → barcode path blocked indefinitely
- Real-world barcode coverage <10% → not worth the engineering investment
- Color histograms produce too many false positives → undermines trust in L0
- Users find barcode scan flow slower than just taking a photo

---

## Related Code Anchors

- `pubspec.yaml:58` — `mobile_scanner` dependency (currently disabled)
- `lib/services/local_classifier_service.dart` — existing local classifier (soon to be Layer 1)
- `lib/services/classification_pipeline.dart` — cascade orchestrator (add L0 step)

---

## Next Steps

1. Resolve `mobile_scanner` dependency conflict
2. Prototype barcode → Open Food Facts lookup pipeline
3. Build Open Food Facts caching layer (local Hive store)
4. Create initial histogram material profiles from labelled waste image dataset
5. Test L0 coverage against real-world waste photo corpus
6. Wire L0 into `ClassificationPipeline` before Layer 1 call
7. A/B test L0 skip rate (how often does L0 prevent a cloud call?)
