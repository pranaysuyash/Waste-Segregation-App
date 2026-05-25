# Object Detection & Multi-Object Scenes

**Purpose**: Explore how the app handles cluttered scenes (kitchen counter, recycling pile, garage clean-out) where multiple objects need separate classification.
**Status**: Exploration — `object_detection_service.dart` exists; dominant path assumes single-object
**Last Updated**: 2026-05-25
**Related**: [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md), [ON_DEVICE_INFERENCE.md](ON_DEVICE_INFERENCE.md), [MODEL_LIFECYCLE.md](MODEL_LIFECYCLE.md)

---

## Problem Statement

Today the app assumes single-object classification. But real-world waste is cluttered:

- A kitchen counter with milk carton, banana peel, and glass jar
- A recycling pile with mixed paper, cans, and plastic bottles
- A garage clean-out with e-waste, batteries, and packaging

Without object detection, the model either:
- Picks one dominant object and ignores the rest
- Returns a confusing multi-label result
- Forces the user to capture each item separately (friction)

---

## Detection vs Classification Flow

```
[Scene Image]
    ↓
[Object Detection] ← YOLO/MobileSAM/SAM
    ↓
Multiple Bounding Boxes
    ↓
[Per-Object Cropping]
    ↓
[Per-Crop Classification] ← current classification pipeline
    ↓
[Results: Item 1, Item 2, Item 3...]
```

---

## Detection Models

| Model | Size | Speed | Accuracy | On-Device Feasible |
|-------|------|-------|----------|-------------------|
| YOLOv8-nano | 5MB | Fast | Good | ✅ Yes |
| YOLOv8-small | 22MB | Fast | Better | ✅ Yes |
| MobileSAM | 10MB | Medium | Good | ✅ Yes |
| SAM (full) | 2GB | Slow | Best | ❌ Cloud only |
| MiniCPM-V | Variable | Slow | Varies | Depends on tier |

---

## UX for Multi-Object Results

| State | UX Treatment |
|-------|-------------|
| **Single item detected** | Standard result card (current flow) |
| **2-3 items detected** | Show results as a horizontally scrollable card carousel |
| **4+ items detected** | Grid view with thumbnail + label + confidence |
| **Detection failed** | Show "What's in this photo? Tap to identify" with tap-on-image callback |

Each item in multi-object mode should support:
- Individual classification confidence
- Individual disposal advice (per the user's region)
- Individual correction dialog
- Mark all as correct (batch confirm)

---

## Key Design Questions

1. **Classification cascade**: Should detection run on-device with cloud classifying each crop, or both in cloud?
2. **User interaction mode**: Tap-to-select vs auto-classify-all vs user-crops-each?
3. **Performance budget**: Detection + N classifications is expensive — what's the max N before UX degrades?
4. **Group disposal**: When 5 items all go to "recycle", can we group the disposal advice?

---

## Detection-Triggered Routing

| Detection Result | Routing |
|-----------------|---------|
| 0 objects detected | "Couldn't find items in this image" + suggest retake |
| 1 object | Standard single-object classification |
| 2-3 objects | Classify each, show grouped results |
| 4+ objects | Classify each, show grid, offer batch |
| Object size classification | Route small objects only if user can zoom |
| Blurry/low-light detection | Reject at detection stage, save user a classification call |

---

## Key Decisions Needed

1. **When does detection precede classification**: Always (for multi-object scenes) vs on-demand (user taps "add more items")?
2. **Detection model**: YOLOv8-nano (on-device) vs cloud-based detection?
3. **Batch efficiency**: Can we batch N crops into a single classification call?
4. **History storage**: How do we store multi-object results — as one entry with N items, or N separate entries?

---

## Open Questions

- Does detection improve classification accuracy even for single-object scenes (by isolating the object)?
- Should the app offer "scan this area" where user draws a bounding box?
- How do we handle overlapping objects where one occludes another?

---

## Next Steps

1. Evaluate YOLOv8-nano and MobileSAM for on-device detection performance
2. Design multi-object result UX (carousel vs grid vs tap-to-select)
3. Prototype detection → crop → classify pipeline
4. Performance test: max acceptable items per scene before UX degradation
