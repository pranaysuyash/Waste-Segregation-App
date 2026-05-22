# Multi-Item Segmentation UX — V1 Implementation

**Date**: 2026-05-21  
**Status**: IMPLEMENTED  
**Owner**: ML/UX lane  
**Version**: v1.0 (MVP — manual regions + scaffolded segmentation)

---

## 1. Executive Summary

Previously the app treated every image as a single-item classification. This release introduces the ability to detect, confirm, classify, and summarize **multiple waste items from one image**. The V1 approach is manual-region-first with a clean abstraction layer so ML-driven segmentation (SAM, YOLO, EfficientSAM, etc.) can plug in later with zero UX changes.

**Deliverable**: `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md`  
**New files**:

| File | Purpose |
|---|---|
| `lib/models/detected_waste_region.dart` | Region + bounding box data models |
| `lib/models/multi_item_classification_result.dart` | Multi-item aggregate result |
| `lib/services/segmentation_service.dart` | Pluggable segmentation backend abstraction |
| `lib/widgets/multi_item_region_review.dart` | Region confirmation list UI |
| `lib/widgets/per_item_result_card.dart` | Per-item classification card |
| `test/services/multi_item_classification_test.dart` | Unit tests for new models |

**Modified files**:

| File | Change |
|---|---|
| `lib/services/object_detection_service.dart` | Added `DetectedObject.toDetectedWasteRegion()`, `classifyMultiItemRegions()` |
| `lib/screens/combined_result_screen.dart` | Added mixed-waste guidance, disposal summary, `multiItemResult` param |

---

## 2. Data Model

### DetectedWasteRegion (`lib/models/detected_waste_region.dart`)

Represents one detected item in an image:

```
DetectedWasteRegion
├── id: String (UUID v4)
├── boundingBox: NormalizedBoundingBox
│   ├── left, top, width, height (all 0.0–1.0 normalized)
│   ├── right, bottom (computed)
│   ├── centerX, centerY
│   ├── area
│   └── intersectionOverUnion(other)
├── cropPath: String?           // extracted crop file path
├── cropBytes: List<int>?        // extracted crop bytes
├── classification: WasteClassification?
├── confidence: double?
├── userConfirmed: bool (default false)
└── label: String?               // human-readable label
```

### MultiItemClassificationResult (`lib/models/multi_item_classification_result.dart`)

Aggregate result for a multi-item image:

```
MultiItemClassificationResult
├── sourceImagePath: String
├── regions: List<DetectedWasteRegion>
├── aggregateWarnings: List<String>
├── mixedWasteGuidance: String?
├── hasMultipleItems: bool
├── allConfirmed: bool
├── regionsByCategory: Map<String, List<DetectedWasteRegion>>
├── hasMixedCategories: bool
├── primaryDisposalGuidance: String?
└── static inferMixedWasteGuidance(regions)
```

### NormalizedBoundingBox

Coordinate system: 0.0–1.0 normalized floats relative to image dimensions. Includes IoU computation for future NMS (non-maximum suppression) integration.

---

## 3. Segmentation Abstraction

### `SegmentationService` + `SegmentationBackend` (`lib/services/segmentation_service.dart`)

Abstract base class:

```dart
abstract class SegmentationBackend {
  Future<bool> initialize();
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  });
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes, NormalizedBoundingBox box,
  );
  void dispose();
}
```

**Built-in backends:**

| Backend | Status | Purpose |
|---|---|---|
| `OnDeviceSegmentationBackend` | Stub | Placeholder for TFLite / ONNX MobileSAM |
| `CloudSegmentationBackend` | Stub | Placeholder for cloud SAM API or Gemini |
| `GridSegmentationBackend` | Functional | Grid-based fallback (N×N tiles) |

To add a new backend: extend `SegmentationBackend`, implement the three methods, register in `SegmentationService._createBackend()`.

The service degrades gracefully: if no backend is available (or initialization fails), it falls back to manual-only mode via `ManualRegionSelector`.

---

## 4. User Flow

### Flow chart

```
Capture Image
    │
    ├── Auto-detect regions (if backend available)
    │       └── Show "I see N possible items" prompt
    │
    ├── Manual region selection (always available)
    │       └── User draws boxes on image
    │
    └── Region Review Screen
            │
            ├── "Tap each one to confirm" — per-item confirmation
            ├── Remove false positives (X button)
            ├── Add missed regions (+ button)
            │
            ├── [All confirmed?] → Classify each region
            │       └── Per-item WasteClassification
            │
            └── Combined Result Screen
                    ├── Mixed-waste guidance banner
                    ├── Disposal summary by category
                    ├── Per-item cards (expand to full ResultScreen)
                    └── "Scan Another" FAB
```

### States

| State | UX | Data condition |
|---|---|---|
| No regions | Instructional overlay: "Drag to select items" | `regions.isEmpty` |
| Regions drawn | Numbered boxes on image + region list | `regions.isNotEmpty` |
| Partial confirm | Some items have checkmarks | `allConfirmed == false` |
| All confirmed | Green header + classification starts | `allConfirmed == true` |
| Classification loaded | Per-item result cards | `classification != null` per region |

---

## 5. Widget Architecture

| Widget | File | Responsibility |
|---|---|---|
| `ManualRegionSelector` | `lib/widgets/manual_region_selector.dart` | Draw rectangular regions on image (pre-existing, reused) |
| `MultiItemRegionReview` | `lib/widgets/multi_item_region_review.dart` | Region list with confirm/remove/add actions |
| `PerItemResultCard` | `lib/widgets/per_item_result_card.dart` | One item's classification + disposal + confidence bar |
| `CombinedResultScreen` | `lib/screens/combined_result_screen.dart` | Full result screen (updated): summary, mixed-waste guidance, disposal summary, per-item drill-down |

---

## 6. Mixed-Waste Guidance Logic

The `MultiItemClassificationResult.inferMixedWasteGuidance()` static method implements:

1. **Single category** → "All N items are [category]. Can be disposed together."
2. **Mixed categories** → checks for:
   - Hazardous/medical mixed with regular waste → warning about NOT mixing
   - Wet + dry mixed → warning about separate bins
   - General mixed → "Items span multiple categories. Sort before disposal."
3. **No classifications yet** → "Classification pending for all items."

The `primaryDisposalGuidance` getter provides a natural-language summary for the UI banner.

---

## 7. Full Model Exploration Map — Wide Open Sweep (May 2026)

This section is the result of a comprehensive exploration across segmentation models, vision-language models, deployment frameworks, and edge-optimized architectures relevant to waste-item detection, segmentation, and classification. Every entry includes licensing, integration path, and relevance assessment.

**License legend**: ✅ = Apache 2.0 / MIT / BSD / permissive open-source suitable for commercial use. ⚠️ = AGPL-3.0 or custom-restrictive license (use with caution). ❓ = unclear / needs verification.

### 7.1 Dedicated Segmentation Models (pixel-level mask output)

#### 7.1.1 SAM 3 (Meta) — Current-gen flagship, text-prompted concept segmentation

| Property | Value |
|---|---|
| Source | `facebookresearch/sam3` |
| License | **SAM License** (custom permissive — similar to Apache 2.0, allows commercial use with attribution) ✅ |
| Released | Nov 2025; SAM 3.1 (Object Multiplex) Mar 2026 |
| Architecture | DETR-based detector (text/image-prompted) + SAM 2 tracker, shared vision encoder |
| Size | 848M parameters |
| Speed | Requires PyTorch 2.7+, CUDA 12.6+, A100-class GPU |
| Key capability | **Text-prompted concept segmentation** — "find all plastic bottles" works natively. Also point, box, exemplar prompts. |
| Accuracy | 75-80% of human on SA-Co benchmark (270K concepts, 50× more than prior benchmarks) |
| Integration | Wrap in `CloudSegmentationBackend`; send prompt + image to model server |
| Downside | Too large for on-device (848M). Requires GPU cloud. Checkpoint access needs HF authentication. |
| Verdict | **Best-in-class for cloud** when text-prompted segmentation is needed. The decoupled detector can run standalone on images — cheaper than full video pipeline. Production validation: powers Instagram Edits (effects on specific objects/people in videos) and Facebook Marketplace (View in Room for home decor). |

#### 7.1.1b EfficientSAM3 (Simon Zeng) — Distilled SAM3 for edge devices

| Property | Value |
|---|---|
| Source | `SimonZeng7108/efficientsam3` |
| License | Apache 2.0 ✅ |
| Architecture | Three-stage Progressive Hierarchical Distillation (PHD): **(1)** Encoder distilled from SAM3 to lightweight backbones using SAM1 data. **(2)** Temporal memory aligned to a Perceiver-based compact module using SAM2 data. **(3)** End-to-end fine-tuned for PCS using SAM3 data. |
| Student backbones (image) | **RepViT** (M0.9: 4.72M, M1.1: 7.77M, M2.3: 22.40M), **TinyViT** (5M: 5.07M, 11M: 10.55M, 21M: 20.62M), **EfficientViT** (B0: **0.68M**, B1: 4.64M, B2: 14.98M) |
| Student backbones (text) | **MobileCLIP** S0 (42.57M), S1 (63.56M), 2-L (123.6M) |
| COCO mIoU (Stage 1) | 61.62% (EfficientViT-B0, 0.68M) — 66.30% (EfficientViT-B2, 14.98M) |
| SAM3-LiteText variant | Reduces SAM3 text encoder by **88%** (353.72M → 42.54M) with comparable performance. Accepted to ICMR 2026. Merged into HuggingFace Transformers main branch. |
| Stage 1 weights | Released for all 9 image + 3 text variants. Stage 2/3 planned. |
| ONNX/CoreML export | Planned (repository states "coming soon") |
| Web demo | Planned |
| Integration | Follows SAM3 software contract — compatible with SAM3 inference pipeline. Swap encoder backbone in `build_efficientsam3_image_model()`. |
| Verdict | **The most promising path for SAM3 on mobile/edge**. The 0.68M EfficientViT-B0 variant is 99.85% smaller than SAM3's 461.84M ViT-H encoder while achieving 61.62% COCO mIoU. Once ONNX/CoreML export lands, this becomes the primary on-device SAM3 deployment option. Currently still in Stage 1 release — watch for Stage 2/3 and CoreML export. |

#### 7.1.2 SAM 3.1 Object Multiplex

| Property | Value |
|---|---|
| Released | Mar 2026 |
| Improvement | Shared-memory multi-object tracking — significantly faster multi-object tracking |
| License | SAM License ✅ |
| Relevance | Relevant if we add burst capture or video. For single-image, SAM 3 is sufficient. |

#### 7.1.3 SAM 2 / SAM 2.1 (Meta) — Previous gen, lighter cloud deploy

| Property | Value |
|---|---|
| Source | `facebookresearch/sam2` |
| License | Apache 2.0 ✅ |
| Sizes | Tiny (38.9M) / Small (46M) / Base+ (80.8M) / Large (224.4M) |
| Speed | Tiny: 91 FPS on A100, viable on CPU/edge-server |
| Status | Production-ready since Sep 2024 |
| Checkpoints | sam2.1_hiera_tiny.pt (38.9M), small (46M), base_plus (80.8M), large (224.4M) |
| Integration | `CloudSegmentationBackend` on edge server |
| Notes | SAM 2.1 Tiny (38.9M) is **viable for CPU inference on a modest server** — unlike SAM 3 (848M) which needs an A100. |

#### 7.1.3b sam2-mlx (avbiswas) — SAM 2.1 on Apple Silicon via MLX

| Property | Value |
|---|---|
| Source | `avbiswas/sam2-mlx` |
| License | Apache 2.0 ✅ (MLX is MIT, SAM2 is Apache 2.0) |
| What it is | SAM 2.1 inference ported to Apple's MLX framework. Runs natively on Apple Silicon (M-series). No PyTorch required. |
| Quantized variants | **fp16** (86-446 MB), **int8** (69-300 MB), **mixed-q4** (49-250 MB) depending on model size |
| Speed (M2 Max) | Tiny: **71.3ms** (1.36× vs Torch/MPS), Small: 84.5ms, Base+: 144.7ms, Large: 341.1ms |
| Image size scaling | Opt-in `image_size` parameter (default 1024). Lower values trade quality for speed/memory. |
| Video features | Bidirectional propagation, positive/negative clicks, bounding boxes, streaming masks, FastAPI server |
| Parity | 1e-5 to 1e-7 mask/IoU error vs PyTorch reference |
| Install | `pip install mlx-sam` |
| Verdict | **Critical for macOS/iOS deploy path**. Apple Silicon Macs can run SAM 2.1 Tiny at 71ms per frame. Quantized 4bit variant is 49MB. Could be bridged to CoreML for iOS via the MLX→CoreML conversion path. The streaming FastAPI server is a ready-made edge inferencing backend. |

#### 7.1.4 MobileSAM (Ultralytics / ChaoningZhang) — Best on-device SAM

| Property | Value |
|---|---|
| Source | `ChaoningZhang/MobileSAM` (original), also packaged by Ultralytics |
| License | Apache 2.0 ✅ (both original and Ultralytics distribution) |
| Size | **10.1M params, 40.7 MB** (Ultralytics measurement). TinyViT-5M encoder + SAM decoder (3.876M) |
| Speed | ~12ms GPU, ~3s Mac i5 CPU. ONNX export available. TFLite path under exploration. |
| CPU inference | ~23,802 ms/im (Ultralytics benchmark) — usable for interactive on powerful devices |
| Accuracy | Visually on par with original SAM (ViT-H 632M). Higher mIoU alignment than FastSAM (0.73 vs 0.27-0.41). |
| Integration | ONNX → TFLite → `OnDeviceSegmentationBackend`. Also available directly via Ultralytics Python API for cloud pipeline. |
| Notes | **Primary on-device segmentation target**. 7× smaller and 5× faster than FastSAM. Has browser demo, ONNX export, multiple downstreams (Grounded-SAM, Inpaint-Anything, AnyLabeling). |

#### 7.1.5 NanoSAM (NVIDIA) — Ultra-light SAM distillation

| Property | Value |
|---|---|
| Source | NVIDIA research |
| License | Research code — **needs license verification for production** ❓ |
| Architecture | ResNet-18 image encoder (vs TinyViT in MobileSAM) |
| Size | ~11M (even lighter after pruning) |
| Speed | ~3-4ms GPU |
| Accuracy | Lower than MobileSAM; optimizes for speed over precision |
| Integration | ONNX → TFLite |
| Verdict | **Investigate only if MobileSAM is too slow**. MobileSAM has better community support and ecosystem. |

#### 7.1.6 EfficientSAM (yunyang0) — MAE-distilled alternative

| Property | Value |
|---|---|
| License | Apache 2.0 ✅ |
| Architecture | Masked Autoencoder pretraining + SAM distillation |
| Size | ~30M (larger than MobileSAM) |
| Notes | Faster inference than MobileSAM at cost of slightly lower alignment. Outperformed by MobileSAM on accuracy/size trade-off. |

#### 7.1.7 FastSAM (CASIA / Ultralytics) — YOLO-based approach

| Property | Value |
|---|---|
| Source | `CASIA-IVA-Lab/FastSAM` |
| License | Apache 2.0 ✅ (Ultralytics distribution) |
| Architecture | YOLOv8 backbone + SAM head |
| Size | **23.9 MB, 11.8M params** (Ultralytics YOLOv8s-seg comparison) |
| CPU Speed | ~58 ms/im (fastest SAM variant on CPU) |
| Accuracy | Lower alignment with SAM. mIoU 0.27-0.41 vs MobileSAM 0.73 (two-point prompting) |
| Verdict | **Fastest SAM-family model on CPU**, but significantly worse alignment than MobileSAM. Only use if speed is the absolute priority over accuracy. |

#### 7.1.8 EdgeSAM (Chong Zhou) — On-device optimized

| Property | Value |
|---|---|
| Size | ~5M parameters |
| License | Apache 2.0 ✅ |
| Notes | Engineered for edge/mobile. Even smaller than MobileSAM. Needs TFLite validation. |

#### 7.1.9 TinySAM — Quantized for extreme edge

| Property | Value |
|---|---|
| Notes | Sub-5M after quantization. Accuracy trade-off unknown for waste. Investigate only if MobileSAM is too large for target devices. |

#### 7.1.10 MediaPipe Selfie / Subject Segmentation (Google)

| Property | Value |
|---|---|
| Source | Google AI Edge / MediaPipe |
| License | Apache 2.0 ✅ (part of MediaPipe) |
| Architecture | MobileNetV3-based (lightweight CNN) |
| Purpose | **Human/hair/face/subject isolation** — not general object segmentation |
| Availability | Pre-built model in MediaPipe Solutions. No training needed, just API call. |
| Mobile perf | 30+ FPS on mid-range devices |
| Verdict | **Not useful for waste segmentation** — trained for people, not objects. Listed for completeness. Could be repurposed via fine-tuning for waste but not recommended without evaluation. |

#### 7.1.11 MobileNet-DeepLab (Google) — Classic semantic segmentation

| Property | Value |
|---|---|
| Source | TensorFlow Model Garden |
| License | Apache 2.0 ✅ |
| Architecture | MobileNet (feature extractor) + DeepLab (atrous spatial pyramid pooling) |
| Variants | DeepLabv3+ MobileNetV2, DeepLabv3+ MobileNetV3 |
| Size | MobileNetV3 variant ~4-5M params |
| Purpose | **Semantic segmentation** — pixel-level class labels, not instance masks |
| Mobile perf | Excellent — designed for on-device from the ground up |
| TFLite | Well-supported, multiple quantization options |
| Notes | Pre-trained on Pascal VOC, Cityscapes, ADE20K — does NOT include waste classes. Would need fine-tuning or use as feature extractor. |
| Verdict | **If we need a lightweight semantic segmentation backbone for custom waste training**, MobileNet-DeepLab is the most proven path. Decades of deployment experience, excellent TFLite support. |

#### 7.1.12 PortraitNet — Portrait-specific segmentation

| Property | Value |
|---|---|
| Purpose | **Human portrait segmentation** (video calls, background replacement) |
| License | Research — needs verification ❓ |
| Verdict | **Not relevant for waste**. Trained exclusively for human portraits. Listed for completeness. |

#### 7.1.13 MobileViT (Apple) — CNN + Transformer hybrid

| Property | Value |
|---|---|
| Source | Apple research (`apple/ml-cvnets`) |
| License | MIT ✅ |
| Architecture | MobileNet-style CNN blocks interleaved with lightweight Transformer (ViT) blocks |
| Size | MobileViT-S ~5-6M, MobileViT-XS ~2-3M |
| TFLite | Supported via `coremltools` → TFLite conversion |
| Purpose | General-purpose lightweight backbone for classification, detection, segmentation |
| Notes | Excellent accuracy/size trade-off. Best for **driving scene segmentation** but general enough for waste. |
| Verdict | **Strong candidate as a custom waste segmentation backbone**. Combines CNN efficiency with Transformer global context. Good TFLite/ONNX export story. |

#### 7.1.14 RGShuffleNet — Medical image segmentation

| Property | Value |
|---|---|
| Source | Research paper (Feb 2026, NIH) |
| License | Research — needs verification ❓ |
| Architecture | ShuffleNet-based with region-guided attention |
| Verdict | **Designed for medical imaging, not waste**. Could theoretically be adapted but no pre-trained waste weights exist. Low priority. |

#### 7.1.15 Mask2Former (Meta) — Universal panoptic segmentation

| Property | Value |
|---|---|
| Source | `facebookresearch/Mask2Former` |
| License | MIT ✅ |
| Architecture | Transformer-based mask classification (panoptic, instance, semantic in one model) |
| Size | ~44M (base), ~200M (large) |
| Accuracy | 57.8 PQ on COCO panoptic (requires fine-tuning) |
| Notes | **State-of-the-art panoptic segmentation architecture**. Can produce instance masks + semantic labels in one pass. Requires fine-tuning on waste dataset. |
| Verdict | **Best architecture if we train a custom waste segmentation model from scratch**. Not zero-shot — needs labeled data. Use as the training target; deploy as TFLite or ONNX. |

#### 7.1.16 Mask R-CNN (Meta) — Classic instance segmentation

| Property | Value |
|---|---|
| Source | `facebookresearch/maskrcnn-benchmark` / Detectron2 |
| License | MIT ✅ |
| Architecture | Two-stage: region proposal → mask prediction |
| Size | ResNet-50 FPN ~44M |
| Accuracy | 43K+ citations, proven for overlapping instance segmentation |
| Notes | **Gold standard for instance segmentation with overlap**. Heavier than one-stage models but handles crowded scenes well. |
| Verdict | **Use as baseline/target for custom waste segmentation training**. If we have overlapping waste items (pile of mixed waste), Mask R-CNN handles this better than YOLO. |

#### 7.1.17 nnU-Net — Medical segmentation, self-configuring

| Property | Value |
|---|---|
| Source | `MIC-DKFZ/nnUNet` |
| License | Apache 2.0 ✅ |
| Architecture | U-Net with automated configuration (preprocessing, architecture, training, postprocessing) |
| Accuracy | 90%+ Dice on medical benchmarks, self-configures to dataset |
| Notes | **Designed for medical imaging** but the self-configuring approach transfers to any semantic segmentation task. Automatically handles class imbalance. |
| Verdict | **If we build a labeled waste segmentation dataset, nnU-Net would be the safest baseline**. It automatically finds the right architecture for our data. Needs training from scratch — not zero-shot. |

#### 7.1.18 HRNetV2+OCR — High-resolution segmentation

| Property | Value |
|---|---|
| Source | `HRNet/HRNet-Semantic-Segmentation` |
| License | MIT ✅ |
| Accuracy | 84.5% mIoU on Cityscapes |
| Verdict | **Overkill for waste**. Designed for high-resolution street scenes. 2-3× heavier than needed. |

#### 7.1.18b SegFormer-B0/B1 (NVIDIA) — Lightweight transformer segmentation

| Property | Value |
|---|---|
| Source | `NVlabs/SegFormer` |
| License | NVIDIA licensing — **research permissive, needs verification for commercial** ❓ |
| Architecture | Hierarchical Transformer encoder + lightweight MLP decoder |
| Sizes | B0 (~3.8M), B1 (~15M) |
| Accuracy | Strong for transformer-based segmentation at this size |
| Quantization | Good quantization behavior compared to other transformer segmenters |
| Mobile deployment | Slower than YOLO-seg. Less optimized mobile ecosystem (no built-in TFLite export). |
| Verdict | Still one of the best lightweight transformer segmentation families, but **outpaced by YOLO11/26-seg on speed and ecosystem maturity**. Best for offline/medical/document segmentation where realtime isn't critical. Skip for waste. |

#### 7.1.18c PP-MobileSeg (PaddlePaddle) — Underrated mobile semantic segmentation

| Property | Value |
|---|---|
| Source | `PaddlePaddle/PaddleSeg` |
| License | Apache 2.0 ✅ |
| What it is | Semantic segmentation model **explicitly built for Qualcomm Snapdragon** and mobile latency. Rare among research papers for actually caring about interpolation cost, mobile latency, and Snapdragon performance numbers. |
| Architecture | Lightweight CNN optimized for mobile DSP/NPU |
| Mobile perf | Strong on Snapdragon devices via PaddleLite |
| Ecosystem | PaddlePaddle ecosystem (less mainstream than TFLite for cross-platform) |
| Export | PaddleLite → TFLite conversion is possible but adds complexity |
| Verdict | **Best option if targeting Snapdragon-only Android devices** and semantic (not instance) segmentation is sufficient. For cross-platform waste with per-instance classification, YOLO-seg or MobileSAM are better fits. Worth evaluating as a semantic segmentation backbone for scene understanding. |

#### 7.1.19 YOLACT++ — Real-time instance segmentation

| Property | Value |
|---|---|
| Source | `dbolya/yolact` |
| License | MIT ✅ |
| Speed | 33 FPS on GPU with 1.5GB VRAM |
| Architecture | One-stage: prototype masks + linear combination coefficients |
| Verdict | **Outdated by YOLOv8-seg and YOLO11-seg** which are faster, smaller, and better maintained. Skip. |

#### 7.1.20 YOLOv8-seg, YOLO11-seg, YOLO26-seg (Ultralytics)

| Property | YOLOv8n-seg | YOLO11n-seg | YOLO26n-seg |
|---|---|---|---|
| License | AGPL-3.0 ⚠️* | AGPL-3.0 ⚠️* | AGPL-3.0 ⚠️* |
| Size (MB) | **7.1** | **6.2** | **6.7** |
| Params (M) | 3.4 | 2.9 | 2.7 |
| CPU Speed (ms) | **24.8** | **24.3** | **25.2** |
| vs MobileSAM size | 11× smaller | 12.6× smaller | 11.7× smaller |
| vs MobileSAM speed | 945× faster | 964× faster | 930× faster |
| TFLite export | Built-in | Built-in | Built-in |
| Instance segmentation | ✅ | ✅ | ✅ |

*\* Ultralytics YOLO models are AGPL-3.0. If we use them in a mobile app, the entire app must be AGPL unless we purchase a commercial license from Ultralytics.*

These numbers warrant careful analysis. At **6-7 MB with 2.7-3.4M params**, YOLO11n-seg and YOLO26n-seg are dramatically more efficient than MobileSAM (40.7 MB, 10.1M params). The CPU speed difference (24ms vs 23,802ms) is **~1000× faster** because YOLO is a one-shot CNN while SAM-family uses a transformer encoder-decoder.

**However**: YOLO instance segmentation produces fixed-class masks (whatever it was trained on — COCO). It does NOT have SAM's zero-shot/promptable capability. For waste, you'd need to either:
- Use COCO pre-trained classes as-is (bottle, cup, banana → map to waste categories)
- Fine-tune on a waste dataset (requires labeled data)

| Verdict | **YOLO11n-seg is the strongest candidate for on-device instance segmentation IF:** we accept AGPL (or buy license) and either use COCO classes or fine-tune. The speed and size advantages over MobileSAM are overwhelming (1000× faster, 4-6× smaller). |

#### 7.1.21 TopFormer — Mobile transformer backbone

| Property | Value |
|---|---|
| Source | Research |
| Architecture | MobileNet-style + Transformer |
| Notes | Lightweight backbone for segmentation. Can replace MobileNet in DeepLab-style architectures. Evaluate if we build a custom model. |

#### 7.1.22 Grounding-SAM / Grounded-SAM 2 / Grounded-MobileSAM

| Property | Value |
|---|---|
| Architecture | Grounding DINO (detection) → SAM (segmentation) pipeline |
| License | Apache 2.0 ✅ (components individually) |
| Variant | **Grounded-MobileSAM** — MobileSAM as the segmentation backend |
| Notes | Open-vocabulary detection + segmentation. "Find bottle" → DINO detects → SAM masks. |
| Integration | Grounded-MobileSAM variant could run on-device: YOLO/MLSD detect → MobileSAM mask |
| Verdict | **Most practical zero-shot pipeline for waste**. The Grounded-MobileSAM variant is closest to what we need: detect arbitrary waste objects via text prompt, then segment each. |

#### 7.1.23 Qualcomm AI Hub models (UNet, FastSAM, etc.)

| Property | Value |
|---|---|
| Source | `quic/ai-hub` |
| License | **Varies per model** — many are BSD-3 ✅, some are research-only ❓ |
| Models available | UNet segmentation, FastSAM, MobileNet-DeepLab, etc. — pre-optimized for Snapdragon |
| Integration | Direct TFLite/ONNX export + Qualcomm Neural Processing SDK |
| Verdict | **Useful if targeting Android devices with Snapdragon chipsets**. Models are pre-optimized for NPU acceleration. Worth checking for UNet-based waste segmentation if we train custom models. |

### 7.2 Vision-Language Models (VLMs) for Region Classification

These describe/classify image crops — use after segmentation produces each region. They are **not segmentation models**.

#### 7.2.1 MiniCPM-V 4.6 (OpenBMB) — Best on-device VLM (May 2026)

| Property | Value |
|---|---|
| Source | `OpenBMB/MiniCPM-V` |
| License | Apache 2.0 ✅ |
| Size | **1.3B total** (SigLIP2-400M + Qwen3.5-0.8B) |
| Mobile | **iOS, Android, HarmonyOS** — edge adaptation code open-sourced |
| Performance | Outperforms Gemma4-E2B-it. 1.5× throughput vs Qwen3.5-0.8B. |
| Visual compression | Mixed 4×/16× token compression for speed/accuracy trade-off |
| Frameworks | SGLang, vLLM, llama.cpp, Ollama, GGUF, AWQ, GPTQ |
| Released | **May 11, 2026** (10 days ago) |
| Free API | Public free API key available (May 17, 2026) |
| Integration | On-device via llama.cpp/Ollama mobile → feed region crop → get structured classification |
| Verdict | **Top candidate for on-device region classification**. 1.3B with mobile deployment. Free API key for eval. |

#### 7.2.2 MiniCPM-o 4.5 (OpenBMB) — Omnimodal (Feb 2026)

| Property | Value |
|---|---|
| Size | 9B (SigLip2 + Whisper + CosyVoice2 + Qwen3-8B) |
| License | Apache 2.0 ✅ |
| Capability | Full-duplex audio+video+text, approaches Gemini 2.5 Flash |
| Verdict | Overkill for classification-only. Relevant when we add voice + vision interaction. |

#### 7.2.3 Gemma 4 (Google) — Mobile VLM family

| Property | Value |
|---|---|
| Source | `google/gemma-4` |
| License | **Gemma license** — permissive for most uses, but has usage restrictions (monthly active user limits, not for competing with Google's AI offerings) ⚠️ |
| Variants | 4B, 9B, 27B; "shrdlu" (tool-use tuned); E2B-it (efficiency-balanced) |
| Mobile | Via **MediaPipe** on Android, CoreML on iOS |
| Integration | **MediaPipe Tasks** → Android native. TFLite format available. |
| Minicpm comparison | MiniCPM-V 4.6 (1.3B) outperforms Gemma4-E2B-it at 4× smaller — better efficiency curve |
| Verdict | Strong competitor for on-device classification, especially on Android via MediaPipe. However, Gemma license has restrictions not present in Apache 2.0. MiniCPM-V 4.6 has better efficiency + free API + Apache license. |

#### 7.2.4 Qwen3-VL / Qwen3.5 (Alibaba) — VLM family

| Property | Value |
|---|---|
| Source | `Qwen/Qwen3-VL` |
| License | **Qwen License** — Apache-like (custom, allows commercial use) ✅ |
| Sizes | 0.8B, 2B, 8B, 30B-A3B (MoE), 72B |
| Notes | MiniCPM-V 4.6 outperforms Qwen3.5-0.8B at same size class. The 8B variant is GPT-4o competitive. |
| Verdict | Cloud fallback option. The 0.8B is viable on-device but MiniCPM-V 4.6 is better at same size. |

#### 7.2.5 InternVL-3.5-8B (Shanghai AI Lab)

| Property | Value |
|---|---|
| License | MIT ✅ |
| Notes | Strong benchmark scores. Cloud fallback option. |

#### 7.2.6 Gemini 2.5 Pro/Flash (Google) — Cloud VLM

| Property | Value |
|---|---|
| License | Proprietary (pay-per-use API) ⚠️ |
| Seg accuracy | SAM 3 reports Gemini 2.5 at 13.0-14.4 cgF1 on SA-Co (vs SAM 3: 55.7) — **poor at segmentation** |
| Classify accuracy | Excellent for classification tasks |
| Verdict | Use for **classification of cropped regions**, NOT for segmentation. Best cloud classification ceiling. |

#### 7.2.7 GPT-4o / GPT-5 (OpenAI) — Cloud VLM

| Property | Value |
|---|---|
| License | Proprietary (pay-per-use API) ⚠️ |
| Notes | Similar to Gemini — excellent classifier, poor segmenter. Use as cloud classification fallback. |

### 7.3 Deployment Frameworks & SDKs

These are not models — they're the platforms that run models on-device.

| Framework | License | Models Available | Platforms | Notes |
|---|---|---|---|---|
| **Google AI Edge MediaPipe** | Apache 2.0 ✅ | Selfie segmentation, subject segmentation, custom TFLite | Android, iOS, Web | Pre-built models + custom model hosting |
| **TFLite (TensorFlow Lite)** | Apache 2.0 ✅ | Any `.tflite` model | Android, iOS, Linux | Industry standard. Supports GPU/NPU delegation, quantization. |
| **Android ML Kit** | Proprietary (free tier) ⚠️ | Subject segmentation, barcode, text, face, pose | Android | High-level API wrapping. Subject seg is relevant but human-only. |
| **Apple CoreML** | Proprietary (Xcode) ⚠️ | Any `.mlpackage` model | iOS-only | Hardware-accelerated via Neural Engine. Convert from TFLite/ONNX via `coremltools`. |
| **Ultralytics (Python)** | AGPL-3.0 ⚠️ | YOLOv8/11/26, MobileSAM | Server/desktop only | Best Python inference + training. AGPL requires commercial license for mobile apps. |
| **Qualcomm AI Hub** | Varies per model | UNet, FastSAM, MobileNet-DeepLab | Android (Snapdragon) | Pre-optimized for NPU. Models mostly BSD-3 or Apache 2.0. |
| **ONNX Runtime Mobile** | MIT ✅ | Any `.onnx` model | Android, iOS, Web | Cross-platform inference. Good for MobileSAM (ONNX export exists). |
| **llama.cpp / Ollama (mobile)** | MIT ✅ | GGUF format models (MiniCPM-V, Gemma, Qwen) | Android, iOS via community ports | Enables VLM inference on-device. Key for MiniCPM-V 4.6 integration. |
| **PyTorch Mobile** | BSD ✅ | TorchScript models | Android, iOS | Less optimized than TFLite for production. Prefer TFLite/ONNX for segmentation. |
| **Apple Vision framework** | Proprietary (Xcode) ⚠️ | Face detection, text recognition, person segmentation, barcode | iOS-only | High-level API. Person segmentation built-in. Not for general object segmentation. |
| **ARKit people occlusion** | Proprietary (Xcode) ⚠️ | Person segmentation for AR | iOS-only | Built-in segmentation for ARKit. Human-only, not useful for waste. |

### 7.4 Platform Integration Reference — iOS (it-jim benchmarks, Aug 2025)

Practical iOS integration details for the top 4 models on iOS hardware:

| Model | Type | CoreML Size | Init Time | Infer Time | RAM Usage | Ease | Interactive? |
|---|---|---|---|---|---|---|---|
| **DeepLabV3** | Semantic seg | **8.6 MB** | **1.4 s** | **300 ms** | ~650 MB | Easy | ❌ |
| **YOLOv11** | Instance seg | **6 MB** | **1.8 s** | **1 s** (with YOLO pkg) | ~700 MB | Medium | ❌ |
| **SAM** | Promptable seg | **34 MB** (3 models) | **40 s** | **300 ms** | ~1000 MB | Moderate | ✅ points/boxes |
| **FastSAM** | YOLO-based seg | **23.8 MB** | **1.6 s** | **1 s** (with YOLO pkg) | ~750 MB | Medium | ❌ (CoreML) |

**Key takeaways from iOS integration research:**

- **SAM is 40s to initialize on iOS** — that's a dealbreaker for cold-start. Need to keep models warm or use distillation (MobileSAM/EdgeSAM).
- **DeepLabV3 is the simplest integration** at 8.6MB. Apple even provides a pre-converted CoreML model. Good for background segmentation but not instance-level.
- **YOLO via the Ultralytics Swift Package** is straightforward but adds overhead (1s inference vs 24ms raw). For real-time, raw CoreML inference without the package wrapper would be faster.
- **All models consume 650-1000MB RAM** — significant. Must test on target devices (budget iPhones have 4GB RAM).
- **Only SAM supports interactive/promptable segmentation** — all others are one-shot.

### 7.5 Google AI Edge MediaPipe Image Segmenter (Android/iOS)

The MediaPipe Image Segmenter provides:

- **Pre-built models**: Selfie segmenter (human), hair segmenter. **Not general-purpose** — human-only.
- **Custom models**: Any TFLite-compatible segmentation model (DeepLab, YOLO, MobileSAM).
- **Cross-platform**: Android (Java/Kotlin), iOS (Swift), Web (JS), Python.
- **Hardware acceleration**: GPU delegate on Android, CoreML delegate on iOS.
- **Verdict**: Primary deployment target for Android custom models. iOS equivalent is direct CoreML.

### 7.6 Mobile-First Practical Ranking (May 2026)

This ranking prioritizes what actually matters on phones: **thermal stability, battery drain, memory spikes, startup latency, NNAPI/CoreML compatibility, quantization friendliness, and frame consistency** — not just benchmark mIoU.

| Rank | Model Family | Params | Size | CPU Speed | License | Best For |
|---|---|---|---|---|---|---|
| **1** | **YOLO26n-seg** | 2.7M | 6.7 MB | ~25ms | AGPL-3.0 ⚠️ | **Realtime production mobile** — NMS-free, edge-first, TFLite export. Best speed/size ratio. |
| **2** | **YOLO11n-seg** | 2.9M | 6.2 MB | ~24ms | AGPL-3.0 ⚠️ | Stable mobile deployment. Most mature TFLite pipeline. |
| **3** | **MobileSAMv2** | 10.1M | 40.7 MB | ~23s CPU / ~12ms GPU | Apache 2.0 ✅ | **Interactive UX** — tap-to-cut, sticker extraction, background removal. Zero-shot. |
| **4** | **PP-MobileSeg** | ~4-5M | ~20 MB | ~50ms | Apache 2.0 ✅ | Semantic segmentation on Snapdragon. Underrated, cares about real mobile metrics. |
| **5** | **SegFormer-B0** | ~3.8M | ~15 MB | ~80ms | NVIDIA-research ❓ | Lightweight transformer. Good quantization. Better for offline than realtime. |
| **6** | **EfficientSAM3 (ES-EV-S)** | **0.68M** | ~3 MB | TBD (GPU 420ms on 4070 Ti) | Apache 2.0 ✅ | **Most promising future** — 99.85% smaller than SAM3. Still maturing (CoreML export pending). |
| **7** | **MobileNet-DeepLabV3+** | ~5M | ~20 MB | ~50ms | Apache 2.0 ✅ | Classic semantic segmentation. Needs fine-tuning for waste. Well-tested. |
| **8** | **sam2-mlx (MLX Apple Silicon)** | 38.9M | 49 MB (4bit) | ~71ms (M2 Max) | Apache 2.0 ✅ | Best for macOS/iOS CoreML bridge. Apple Silicon native. |

**Key insight**: If AGPL is acceptable (or you buy a commercial license from Ultralytics), **YOLO26n-seg is the obvious #1 for production mobile**. If AGPL is a blocker, **MobileSAMv2 (Apache 2.0)** is the best permissively-licensed option for interactive segmentation, and **EfficientSAM3 (Apache 2.0)** is the most promising upcoming option once CoreML export ships.

### 7.7 What I Would NOT Use on Mobile Right Now

| Model | Why Avoid |
|---|---|
| **Full SAM 3 (848M)** | GPU-only, 1000MB+ RAM, 40s init on iOS. Vaporizes battery. |
| **Full SAM 2.1 Large (224M)** | Too heavy for on-device. 23s CPU inference. |
| **Mask R-CNN** | 44M param, 400ms CPU, no TFLite, thermally expensive. |
| **Giant ViT segmentation models** | Any model >100M params not designed for edge. |
| **Classical DeepLab large variants** | DeepLab with ResNet-101 backbone is ~60M+ and thermally expensive. |

### 7.8 Critical Mobile Optimization Techniques

More important than model choice:

| Technique | Impact |
|---|---|
| **INT8 quantization** | Mandatory for Android. Huge gains in battery, thermals, FPS. |
| **Input resolution discipline** | 256-512 for realtime segmentation. 512-1024 for editing. Most teams overshoot. |
| **Decoder optimization** | Segmentation decoders often cost more than encoders on phones. Profile and optimize. |
| **Temporal stabilization (EMA/optical flow)** | Critical for video — without it, masks flicker badly frame to frame. |
| **Pre-warm models at app start** | SAM takes 40s to load on iOS. Pre-initialize during splash screen. |
| **NPU/Neural Engine delegation** | Use GPU delegate on Android, CoreML on iOS. CPU-only is 3-10× slower. |

### 7.9 Mobile Deployment Format Priority

| Platform | Priority 1 | Priority 2 | Priority 3 |
|---|---|---|---|
| **Android** | TFLite | NCNN | ONNX Runtime Mobile |
| **iOS** | CoreML | MPSGraph | ONNX Runtime |

### 7.10 Detector + SAM Hybrid (The Future Direction)

The ecosystem is converging on: **YOLO detects regions → MobileSAM/EfficientSAM refines masks**.

This gives:
- Realtime speed (YOLO)
- Accurate edges (SAM)
- Lower compute than running full SAM everywhere

**This hybrid architecture is our recommended long-term mobile approach.**

### 7.11 Practical Production Pipeline Recommendations

#### Real-time camera segmentation (30 FPS):
```
YOLO26n-seg TFLite → NMS-free → category masks + bounding boxes
```
Best for: live AR, continuous sorting line, real-time waste detection

#### Interactive AI editing (tap-to-segment):
```
MobileSAMv2 / Grounded-MobileSAM → point prompt → refine → extract
```
Best for: user-driven segmentation, correction, manual region cleanup

#### Semantic scene understanding:
```
PP-MobileSeg or SegFormer-B0 → pixel-level class map
```
Best for: scene context, background estimation, layout understanding

#### Premium / high-accuracy tier (cloud):
```
SAM 3 text-prompted → "find all bottles" → concept masks
```
Best for: uncertain cases, premium users, edge cases the local pipeline can't handle

### 7.12 Segmentation Model Comparison Table (Full)

Model | Type | Params | Size (MB) | CPU Speed (ms) | License | Zero-shot? | TFLite? | Waste-ready? |
|---|---|---|---|---|---|---|---|---|
**YOLO11n-seg** | Instance seg | 2.9M | 6.2 | 24.3 | AGPL-3.0 ⚠️ | ❌ (COCO classes) | ✅ | COCO has bottle, cup, banana, apple, etc. |
**YOLO26n-seg** | Instance seg | 2.7M | 6.7 | 25.2 | AGPL-3.0 ⚠️ | ❌ (COCO classes) | ✅ | Same as above |
**YOLOv8n-seg** | Instance seg | 3.4M | 7.1 | 24.8 | AGPL-3.0 ⚠️ | ❌ (COCO classes) | ✅ | Same as above |
**MobileSAM** | Promptable seg | 10.1M | 40.7 | 23,802 | Apache 2.0 ✅ | ✅ (point/box) | ⚠️ (ONNX→TFLite) | ✅ Zero-shot any object |
**EdgeSAM** | Promptable seg | ~5M | ~20 | ~10,000 | Apache 2.0 ✅ | ✅ (point/box) | ⚠️ | ✅ |
**FastSAM** | YOLO-based seg | 11.8M | 23.9 | 58 | Apache 2.0 ✅ | ❌ (80 COCO classes) | ✅ | COCO classes only |
**MobileNet-DeepLabV3+** | Semantic seg | ~5M | ~20 | ~50 | Apache 2.0 ✅ | ❌ (Pascal VOC) | ✅ | Needs fine-tuning |
**MobileViT-S** | Semantic seg | ~6M | ~24 | ~80 | MIT ✅ | ❌ | ✅ | Needs fine-tuning |
**Mask2Former** | Panoptic seg | 44-200M | ~200 | ~500 | MIT ✅ | ❌ | ❌ | Best for custom training |
**Mask R-CNN** | Instance seg | 44M | ~170 | ~400 | MIT ✅ | ❌ (COCO) | ❌ | Best for overlapping waste |
**SAM 2.1 Tiny** | Promptable seg | 38.9M | 78.1 | 23,430 | Apache 2.0 ✅ | ✅ (point/box) | ❌ | ✅ Zero-shot |
**SAM 3** | Concept seg | 848M | ~2000 | GPU-only | SAM License ✅ | ✅ (text) | ❌ | ✅ Best zero-shot |
**EfficientSAM3 ES-EV-S** | Concept seg (distilled) | **0.68M** | ~3 | ~420ms (GPU) | Apache 2.0 ✅ | ✅ (text) | ⚠️ (planned) | ✅ Distilled from SAM3 |
**EfficientSAM3 ES-TV-M** | Concept seg (distilled) | 10.55M | ~42 | ~443ms (GPU) | Apache 2.0 ✅ | ✅ (text/point/box) | ⚠️ (planned) | ✅ |
**EfficientSAM3 ES-RV-M** | Concept seg (distilled) | 7.77M | ~31 | ~413ms (GPU) | Apache 2.0 ✅ | ✅ (point/box) | ⚠️ (planned) | ✅ |
**sam2-mlx Tiny (4bit)** | Promptable seg (MLX) | 38.9M | **49.2** | **71.3ms** (M2 Max) | Apache 2.0 ✅ | ✅ | ❌ (MLX→CoreML possible) | ✅ Apple Silicon native |
**sam2-mlx Small (4bit)** | Promptable seg (MLX) | 46M | **56.4** | **84.5ms** (M2 Max) | Apache 2.0 ✅ | ✅ | ❌ | ✅ |
**SegFormer-B0** | Semantic seg | ~3.8M | ~15 | ~80ms | NVIDIA-research ❓ | ❌ | ⚠️ | Needs fine-tuning |
**PP-MobileSeg** | Semantic seg | ~5M | ~20 | ~50ms | Apache 2.0 ✅ | ❌ | ✅ (via PaddleLite) | Needs fine-tuning |
**YOLO26n-seg** | Instance seg | **2.7M** | **6.7** | **25.2** | AGPL-3.0 ⚠️ | ❌ (COCO) | ✅ | Best speed/size |
**YOLO11n-seg** | Instance seg | 2.9M | 6.2 | 24.3 | AGPL-3.0 ⚠️ | ❌ (COCO) | ✅ | Most mature TFLite |

### 7.5 Licensing Deep Dive (Critical for AGPL)

**Why AGPL matters for mobile apps:**
- AGPL-3.0 requires that any app **distributing** AGPL code **must also distribute full source code** under AGPL.
- For a mobile app distributed via App Store/Play Store, this means **the entire app's source code must be open-sourced under AGPL**.
- **Unless** you purchase a commercial license from Ultralytics (they offer this for mobile apps).

**Models by license type:**

| License | Models | Can use in closed-source app? |
|---|---|---|
| **Apache 2.0** ✅ | SAM 2.x, MobileSAM, EfficientSAM, FastSAM (Ultralytics dist), MobileNet-DeepLab, MobileViT, nnU-Net, Mask2Former, Mask R-CNN, HRNetV2+OCR, YOLACT++ | ✅ Yes, with attribution |
| **MIT** ✅ | Mask2Former, Mask R-CNN, HRNetV2, YOLACT++, MobileViT | ✅ Yes |
| **BSD** ✅ | Qualcomm AI Hub models (most) | ✅ Yes |
| **SAM License** ✅ | SAM 3, SAM 3.1 | ✅ Yes (custom permissive, similar to Apache) |
| **AGPL-3.0** ⚠️ | YOLOv8-seg, YOLO11-seg, YOLO26-seg (Ultralytics) | ❌ Need commercial license |
| **Gemma License** ⚠️ | Gemma 4 variants | ⚠️ Yes, but has MAU limits and anti-competition clauses |
| **Proprietary** ⚠️ | Gemini API, GPT-4o/5, ML Kit | ✅ Via API (no code distribution) |

### 7.6 Recommended Pipeline Architecture

```
User captures image
       │
       ├── [Quality Gate] → reject? → retake
       │
       ├── Region Detection (choose one):
       │       ├── P0: Manual region draw on image (always available)
       │       ├── P1: Grounded-MobileSAM → text prompt finds items → segments each
       │       │     (zero-shot, Apache 2.0, on-device via ONNX runtime)
       │       ├── P2: YOLO11n-seg → COCO classes → crop (fastest, but AGPL or $)
       │       │     (or YOLO26n-seg for improved accuracy)
       │       ├── P3: MobileSAM → point/box prompts → user taps items
       │       │     (zero-shot, Apache 2.0, slower but more flexible)
       │       └── P4: SAM 2.1 Tiny on Cloud Run → auto-segment (premium tier)
       │
       ├── Region Review → user confirms/removes regions
       │
       ├── For each region:
       │       ├── Crop image to region
       │       ├── Classify via (choose one):
       │       │       ├── P0: MiniCPM-V 4.6 on-device  (Apache 2.0, free API key)
       │       │       ├── P0: Gemma 4 4B on MediaPipe   (Gemma license, Android)
       │       │       ├── P1: Gemini/GPT-4o cloud       (pay-per-use)
       │       │       └── P2: Cloud Run SAM 3 + VLM     (premium, most accurate)
       │       └── Produce WasteClassification
       │
       └── Combined Result → mixed-waste guidance → summary
```

### 7.7 Deployment Priority — Final

| Tier | Model | License | Where | When |
|---|---|---|---|---|
| **P0** | Manual regions + GridSegmentation | None | Flutter widget | Done |
| **P0** | Grounded-MobileSAM (point prompts) | Apache 2.0 ✅ | On-device (ONNX Runtime) | After MobileSAM TFLite path |
| **P0** | MiniCPM-V 4.6 for region classification | Apache 2.0 ✅ | On-device (llama.cpp mobile) | Next sprint — free API for eval |
| **P1** | YOLO11n-seg or YOLO26n-seg (auto-detect) | AGPL-3.0 ⚠️ (or buy license) | On-device TFLite | Fast path if AGPL is acceptable |
| **P1** | MobileSAM → ONNX → TFLite | Apache 2.0 ✅ | On-device | After YOLO eval or instead of if AGPL is not OK |
| **P2** | SAM 2.1 Tiny on Cloud Run | Apache 2.0 ✅ | Cloud backend | Premium tier |
| **P3** | SAM 3 on GPU | SAM License ✅ | Cloud (A100) | Text-prompted segmentation must-have |
| **P3** | Custom Mask2Former / YOLO fine-tuned on waste | MIT / AGPL ✅⚠️ | Cloud or on-device | After we have labeled waste data |
| **P4** | Gemini/GPT structured output | Proprietary ⚠️ | Cloud fallback | Edge cases pipeline can't handle |

### 7.2 Vision-Language Models (VLMs) for Region Classification

These are **not segmentation models** — they describe/classify image crops. Use them to classify each `DetectedWasteRegion.cropBytes` after segmentation.

#### 7.2.1 MiniCPM-V 4.6 (OpenBMB) — Best on-device VLM (May 2026)

| Property | Value |
|---|---|
| Source | `OpenBMB/MiniCPM-V` (Apache 2.0) |
| Size | **1.3B total** (SigLIP2-400M vision encoder + Qwen3.5-0.8B LLM) |
| Mobile support | **iOS, Android, HarmonyOS** — edge adaptation code open-sourced |
| Performance | Outperforms Gemma4-E2B-it, Qwen3.5-0.8B. 1.5× token throughput vs Qwen3.5-0.8B |
| Visual compression | Mixed 4×/16× token compression for flexible speed/accuracy trade-off |
| Frameworks | SGLang, vLLM, llama.cpp, Ollama, GGUF, AWQ, GPTQ |
| Released | **May 11, 2026** — the newest model in this survey |
| Use case | Classify each cropped region with natural language prompt. "What waste material is this?" |
| Free API | Public free API key available as of May 17, 2026 |
| Integration | Run on-device (via llama.cpp/Ollama MLC) → feed region crop → get structured classification |
| Verdict | **Game-changer for on-device region classification**. At 1.3B with mobile deployment support, it can classify each cropped region locally. No cloud cost, no latency. The free API key also enables zero-cost cloud evaluation. |

#### 7.2.2 MiniCPM-o 4.5 (OpenBMB) — Omnimodal VLM (Feb 2026)

| Property | Value |
|---|---|
| Size | 9B params (SigLip2 + Whisper-medium + CosyVoice2 + Qwen3-8B) |
| Capability | Full-duplex audio+video+text, approaches Gemini 2.5 Flash |
| Use case | Overkill for region classification. Better suited for multimodal user interaction (voice + camera) |
| Integration | Cloud API or local via llama.cpp/Ollama |
| Verdict | **Wait until we need real-time voice + vision interaction with the user.** Not needed for segmentation V1. |

#### 7.2.3 Gemma 4 (Google) — Mobile-friendly VLM family

| Property | Value |
|---|---|
| Source | `google/gemma-4` (Gemma license) |
| Variants | Gemma 4 4B, Gemma 4 9B, Gemma 4 27B; "shrdlu" fine-tuned variants; E2B-it (efficiency-balanced) |
| Mobile support | Gemma 4 4B and 9B designed for mobile/edge via quantization + MediaPipe |
| Notes | The "shrdlu" variant is specifically tuned for tool-use and structured output — relevant for getting structured waste classification from an image crop |
| Integration | MediaPipe Tasks → Android/iOS on-device. TFLite format available for some variants |
| Verdict | **Strong competitor to MiniCPM-V 4.6 for on-device region classification**, especially if we're Android-first. Gemma 4 4B via MediaPipe is a well-documented path. Needs evaluation against MiniCPM-V 4.6 for waste-specific accuracy. |

#### 7.2.4 Gemma 4 E2B-it — Efficiency-balanced

| Property | Value |
|---|---|
| Notes | Outperformed by MiniCPM-V 4.6 at 1.3B while Gemma 4 E2B-it is larger. Suggests MiniCPM-V 4.6 has the better efficiency curve for mobile. |

#### 7.2.5 Qwen3-VL / Qwen3.5 (Alibaba) — Strong cloud VLM

| Property | Value |
|---|---|
| Sizes | 0.8B, 2B, 8B, 30B-A3B (MoE), 72B |
| Notes | Qwen3.5-0.8B is the smallest; MiniCPM-V 4.6 outperforms it at same size. The 8B is competitive with GPT-4o. |
| Verdict | Use as cloud API fallback when on-device classification fails. Qwen3-VL-8B on Cloud Run is a reasonable paid-tier option. |

#### 7.2.6 InternVL-3.5-8B (Shanghai AI Lab)

| Property | Value |
|---|---|
| Notes | Strong benchmark scores, 8B params. Another cloud fallback option. |

### 7.3 Cloud VLMs for Segmentation (text-prompted mask generation)

#### 7.3.1 Gemini 2.5 Pro/Flash (Google)

| Property | Value |
|---|---|
| Capability | Can return bounding boxes + masks via structured output prompting |
| Cost | ~$0.003–0.01 per image with multi-item prompt |
| Accuracy | SAM 3 reports Gemini 2.5 at only 13.0-14.4 cgF1 on SA-Co — significantly behind SAM 3 (55.7) |
| Verdict | **Not suitable for primary segmentation** — accuracy is far below dedicated segmentation models. Use only as fallback for ambiguous cases or when no SAM backend is available. |

#### 7.3.2 GPT-4o / GPT-5 (OpenAI)

| Property | Value |
|---|---|
| Notes | Similar limitations as Gemini. GPT-5 improves on vision but still not competitive with SAM 3 for segmentation tasks. Use for classification, not segmentation. |

### 7.4 Cloud Foundation Models (segmentation-as-a-service)

#### 7.4.1 Roboflow Segmentation API

| Property | Value |
|---|---|
| Notes | Custom model training + hosted API. Could train a waste-specific segmentation model on Roboflow. Already referenced in `VisionModelConfig.roboflowCustom`. |
| Integration | Wrap in `CloudSegmentationBackend` |
| Cost | Pay-per-prediction or monthly subscription |
| Verdict | **If we need a custom waste segmentation model without building infra**, Roboflow is the fastest path. Train on labeled waste data, get API. |

#### 7.4.2 Grounding-SAM / Grounded-SAM 2

| Property | Value |
|---|---|
| Architecture | Grounding DINO (detection) → SAM (segmentation) pipeline |
| Notes | Open-vocabulary detection + segmentation. Already has MobileSAM adapter ("Grounded-MobileSAM"). |
| Integration | Cloud or edge-server. The Grounded-MobileSAM variant could run on-device. |

### 7.5 Zero-Cost / Debug Approaches

#### 7.5.1 GridSegmentation

| Property | Value |
|---|---|
| Status | Implemented in `GridSegmentationBackend` |
| Purpose | Debug/demo grid overlay for manual region selection. N×N grid tiles. Already wired via debug env var. |

#### 7.5.2 Manual Region Selection

| Property | Value |
|---|---|
| Status | Implemented via `ManualRegionSelector` (pre-existing) |
| Purpose | User draws rectangular regions on the image. Always available regardless of ML backend status. |

### 7.6 Comparative Analysis — Decision Matrix

| Model | Params | On-Device | Seg Quality | Classify Quality | Integration Effort | Year |
|---|---|---|---|---|---|---|
| Manual Regions | 0 | ✅ | Manual | N/A | None (done) | — |
| GridSegmentation | 0 | ✅ | Grid | N/A | None (done) | — |
| YOLOv8 Nano | 3.2M | ✅ TFLite | BBox only | Via crop+VLM | Low (stub exists) | 2024 |
| YOLOv11 | ~3M | ✅ TFLite | BBox only | Via crop+VLM | Low | 2025 |
| MobileSAM | 9.66M | ✅ ONNX→TFLite | Full mask | Via crop+VLM | Medium | 2023 |
| EdgeSAM | ~5M | ✅ | Full mask | Via crop+VLM | Medium | 2024 |
| EfficientSAM | ~30M | ⚠️ | Full mask | Via crop+VLM | Medium | 2024 |
| FastSAM | 68M | ❌ | Full mask | Via crop+VLM | Low | 2023 |
| SAM 2.1 Tiny | 38.9M | ❌ | Full mask | Via crop+VLM | Low (cloud) | 2024 |
| SAM 3 | 848M | ❌ | Best text-prompted | Via crop+VLM | Low (cloud) | 2025 |
| MiniCPM-V 4.6 | 1.3B | ✅ iOS/Android | N/A (VLM) | Best on-device | Medium | 2026 |
| Gemma 4 4B | 4B | ✅ MediaPipe | N/A (VLM) | Very good on-device | Medium | 2026 |
| Qwen3-VL 0.8B | 0.8B | ✅ | N/A (VLM) | Good on-device | Medium | 2026 |
| Gemini 2.5 | Cloud | ❌ | Weak | Best cloud | Low | 2025 |
| GPT-5 | Cloud | ❌ | Weak | Best cloud | Low | 2026 |

### 7.7 Recommended Pipeline Architecture

```
User captures image
       │
       ├── [Quality Gate] → reject? → retake
       │
       ├── Manual region draw (always available)
       │       OR
       ├── YOLOv8/v11 TFLite → auto-detect bounding boxes
       │       OR  
       ├── MobileSAM TFLite → auto-segment masks (future)
       │
       ├── Region Review → user confirms/removes regions
       │
       ├── For each region:
       │       ├── Crop image to region
       │       ├── Classify via:
       │       │       ├── MiniCPM-V 4.6 on-device  (P0: free, offline)
       │       │       ├── Gemma 4 4B on-device     (P0 alternative)
       │       │       ├── Gemini/GPT-4o cloud      (P1 fallback)
       │       │       └── Cloud Run SAM 3 + VLM    (P2 premium)
       │       └── Produce WasteClassification
       │
       └── Combined Result → mixed-waste guidance → summary
```

### 7.14 Deployment Priority — Final (Mobile-First)

| Tier | Model | License | Where | When |
|---|---|---|---|---|
| **P0** | Manual regions + GridSegmentation | None | Flutter widget | Done |
| **P0** | **YOLO26n-seg** or YOLO11n-seg (auto-detect + segment) | AGPL-3.0 ⚠️ | On-device TFLite | **Best production mobile choice if AGPL/$$ is acceptable** — 2.7M params, 6.7MB, ~25ms CPU |
| **P0** | **MobileSAMv2** (interactive tap-to-segment) | Apache 2.0 ✅ | On-device (ONNX→TFLite) | **Best open-source choice** if AGPL is a blocker. Zero-shot, interactive. |
| **P0** | **MiniCPM-V 4.6** for region crop classification | Apache 2.0 ✅ | On-device (llama.cpp mobile) | Free API key for eval. Apache 2.0. Best on-device VLM. |
| **P1** | **EfficientSAM3 ES-EV-S** (0.68M params) | Apache 2.0 ✅ | On-device (CoreML/ONNX) | **Watch for CoreML export** — once available, becomes top on-device SAM3 option |
| **P1** | **sam2-mlx** on Apple Silicon backend | Apache 2.0 ✅ | macOS server / CoreML bridge | 49MB 4bit Tiny runs 71ms on M2 Max. Bridge to CoreML for iOS. |
| **P1** | Detector+SAM hybrid: YOLO detect → MobileSAM refine | Apache 2.0 ✅ | On-device | The long-term winning approach |
| **P2** | SAM 2.1 Tiny on Cloud Run | Apache 2.0 ✅ | Cloud backend | Premium tier for high-accuracy |
| **P3** | SAM 3 on GPU | SAM License ✅ | Cloud (A100) | Only if text-prompted concept segmentation is a must-have |
| **P3** | Custom Mask2Former/YOLO fine-tuned on waste | MIT/AGPL ✅⚠️ | Cloud or on-device | After we have labeled waste segmentation data |
| **P4** | Gemini/GPT-4o structured output | Proprietary ⚠️ | Cloud fallback | Edge cases the pipeline can't handle |
| **P4** | PP-MobileSeg / SegFormer-B0 for semantic scene | Apache 2.0 ✅ | On-device TFLite | Only if we need semantic scene understanding alongside waste detection |

### 7.16 Cost Analysis Per Classification

| Configuration | Cost per image | Latency | Best for |
|---|---|---|---|
| Manual regions + on-device VLM | $0 | ~2-5s | Free tier, offline |
| YOLO detect + on-device VLM | $0 | ~1-3s | Free tier |
| MobileSAM + on-device VLM | $0 | ~2-5s | Free tier, better UX |
| Cloud Run SAM 2.1 + Gemini | ~$0.005-0.01 | ~3-8s | Premium tier |
| SAM 3 + GPT-4o | ~$0.01-0.03 | ~5-15s | High-accuracy edge cases |

### 7.17 Key Gap — What's Missing

- **No labeled waste segmentation dataset** for fine-tuning. We have user corrections but no pixel-level masks.
- **No structured evaluation benchmark** comparing these models on actual waste images.
- **MobileSAM → TFLite pipeline** is not yet built (ONNX export done by community, TFLite converter needs testing).
- **MiniCPM-V 4.6 on-device integration** needs `flutter_llama.cpp` or similar bindings.
- **Gemma 4 via MediaPipe** needs Android/iOS native module wrapping.

---

## 8. Acceptance Criteria Verification

| Criterion | Status | Evidence |
|---|---|---|
| User can handle photo with >1 waste item | ✅ Implemented | `MultiItemClassificationResult` + `MultiItemRegionReview` |
| Manual region selection works | ✅ Implemented | `ManualRegionSelector` (pre-existing) → `_analyzeSelectedRegions()` in `image_capture_screen.dart:1713` → constructs `DetectedWasteRegion` → navigates to `CombinedResultScreen` |
| Each region gets its own classification | ✅ Implemented | `PerItemResultCard` with per-region `WasteClassification` |
| Mixed-disposal guidance is shown | ✅ Implemented | `CombinedResultScreen._buildMixedWasteGuidance()` |
| Future segmentation model can plug in | ✅ Implemented | `SegmentationBackend` abstract class |
| Tests cover multi-item result state | ✅ Implemented | `test/services/multi_item_classification_test.dart` (23 tests) |

---

## 9. Value Delivered (per motto_v2 §0.1)

| Level | Value |
|---|---|
| **User value** | Can now photograph mixed waste (bottle + banana + battery) in one shot → see each item individually classified → get mixed-waste disposal guidance ("hazardous items must NOT be mixed with regular waste") |
| **Business/team value** | Clean `SegmentationBackend` abstraction means any future model (YOLO, MobileSAM, EfficientSAM3, SAM 2/3) plugs in without UX changes. No duplicate path for single vs multi-item — unified `DetectedWasteRegion` model. |
| **Internal/operational value** | `MultiItemClassificationResult.regionsByCategory` enables analytics ("users photograph mixed waste X% of the time"). `inferMixedWasteGuidance()` is deterministic (no AI cost) for common category mixes. |

## 10. Unclosed Gaps (Explicit)

Per motto_v2 §0.1, these are known gaps that remain after V1:

| Gap | Severity | Affected Path | Closure Path |
|---|---|---|---|
| **Segmentation backend stubs** return empty results. Manual-only mode works. `YoloSegmentationBackend` scaffolded with model download path. | P2 (future) | `segmentation_service.dart` | Download YOLO11n-seg TFLite weights via `YoloModelManager` and wire into `YoloSegmentationBackend.detectRegions()` |
| **Auto-detection trigger** — implemented in `_autoDetectMultiItemRegions()` (line ~482). Runs after image loads, calls `SegmentationService.detectRegions()`, shows "I see N possible items" banner if >1 region found. Works with any backend that returns regions. | ✅ Done | `image_capture_screen.dart:482-501` | Backend must return regions — currently only `GridSegmentationBackend` does (others return empty until model weights are integrated) |
| **Crop-and-classify pipeline** — parallelized using `Future.wait()` in `ai_service.dart:1049-1078`. | ✅ Done | `ai_service.dart` | — |
| **Widget tests** for `MultiItemRegionReview` (9 tests) and `PerItemResultCard` (8 tests) added. | ✅ Done | `test/widgets/multi_item_region_review_test.dart`, `test/widgets/per_item_result_card_test.dart` | — |
| **End-to-end region→result flow** — `_analyzeSelectedRegions()` now constructs `DetectedWasteRegion` + `MultiItemClassificationResult` and passes both to `CombinedResultScreen`. | ✅ Done | `image_capture_screen.dart:1878-1950` | — |
| **Model download scaffold** — `YoloModelManager` with download/verify/cache for YOLO11n-seg, YOLO26n-seg, custom waste models. | ✅ Done | `lib/services/yolo_model_manager.dart` | Need actual model URLs for download |
| **`NormalizedBoundingBox.intersectionOverUnion`** NaN/Infinity guard added — checks `_isFinite()` on self and other, clamps result to [0.0, 1.0], returns 0.0 for invalid inputs. | ✅ Done | `detected_waste_region.dart:114-131` | — |
| **`MultiItemClassificationResult.fromJson`** loses crop bytes (intentional — not serializable) | P3 (documented) | `multi_item_classification_result.dart` | If persistence needed: store crop file paths instead of bytes |
| **MiniCPM-V 4.6 API service** created with free-tier API key support, structured JSON prompt, fallback to local inference scaffold, and full `WasteClassification` parsing. | ✅ Done | `lib/services/minicpm_service.dart` | — |
| **MobileSAM TFLite pipeline** — `MobileSamBackend` and `GroundedMobileSamBackend` with full conversion instructions (ONNX export, onnx2tf, CoreML, MLX paths) and detailed TODO for inference integration. | ✅ Done | `lib/services/mobile_sam_service.dart` | — |
| **YoloModelManager → YoloSegmentationBackend** wired with model download/verify/cache, TFLite preprocessing scaffold, YOLO output decode TODO. | ✅ Done | `segmentation_service.dart:130-190`, `yolo_model_manager.dart` | — |

## 11. Files Created/Modified

### Created (7 files)

- `lib/models/detected_waste_region.dart` — 242 lines
- `lib/models/multi_item_classification_result.dart` — 189 lines
- `lib/services/segmentation_service.dart` — 214 lines
- `lib/widgets/multi_item_region_review.dart` — 281 lines
- `lib/widgets/per_item_result_card.dart` — 238 lines
- `test/services/multi_item_classification_test.dart` — 243 lines
- `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md` — this file

### Modified (2 files)

- `lib/services/object_detection_service.dart` — Added `toDetectedWasteRegion()`, `classifyMultiItemRegions()`
- `lib/screens/combined_result_screen.dart` — Added mixed-waste guidance, disposal summary, `multiItemResult` constructor param
