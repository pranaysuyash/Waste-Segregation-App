# Local Model Readiness + Local-vs-Cloud Usage Split (Phase 6)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app

## Executive verdict
- Local model architecture exists.
- Production-grade local inference does not.
- Current practical split is cloud-primary, local-placeholder.

## Evidence

### On-device service status
`lib/services/on_device_vision_service.dart`
- Placeholder markers and TODOs:
  - line 141: placeholder implementation note
  - line 160: TODO actual TFLite inference
  - lines 237-239: explicit placeholder result message
  - line 264: `modelVersion: '1.0.0-placeholder'`

### Object detection service status
`lib/services/object_detection_service.dart`
- Placeholder markers and TODOs:
  - line 116: TODO actual model loading
  - line 152: TODO actual YOLO inference
  - line 171: placeholder mode log
  - line 245: `modelVersion: '1.0.0-placeholder'`

### Selection policy intent
`lib/services/model_selection_service.dart`
- Policy comments indicate local-first/hybrid intent:
  - line 12: always prefer on-device
  - line 15: fallback to cloud
- But readiness of local implementation does not yet satisfy this intent.

## Readiness classification

| Layer | State | Notes |
|---|---|---|
| Local model download/cache plumbing | PARTIAL | `model_download_service.dart` supports downloads and file management.
| Local inference runtime | NOT READY | Placeholder inference paths return synthetic results.
| Local object detection runtime | NOT READY | Placeholder YOLO path.
| Cloud AI runtime | READY | Existing provider/backend paths active.

## Current effective usage split (as-is)
- Cloud AI path: primary real inference source.
- Local path: development scaffold / fallback architecture, not production-quality classifier.

## Recommended split for launch
1. Treat cloud as authoritative classifier for launch.
2. Keep local path behind explicit experimental flag until real model quality and performance are proven.
3. Add telemetry fields to classify each request source as:
   - `cloud_primary`
   - `local_experimental`
   - `local_failed_fallback_cloud`
4. Only graduate local mode after:
   - accuracy benchmark thresholds hit,
   - latency/power profile accepted on mid-tier devices,
   - model update/versioning path validated.

## Next concrete tasks
- Implement real TFLite inference path in `OnDeviceVisionService`.
- Implement real YOLO path in `ObjectDetectionService`.
- Add golden-image benchmark suite comparing local vs cloud outputs.
- Add model-quality gate before enabling local-first in release.
