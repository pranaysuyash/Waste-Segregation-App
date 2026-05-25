# AR Decomposition & Product Lifecycle Visualization — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #80](../EXPLORATION_TOPICS.md#80-ar-decomposition--product-lifecycle-visualization-)
**Sibling topics**: Disposal Reasoning Stage (#3), Educational Content (A8), Personal Impact Dashboard (A9), Gamification Depth (#16)

---

## Decision This Unblocks

Whether to invest in AR-based visualization as an educational and engagement surface — showing users the decomposition timeline, material journey, or recycled-product outcome of a classified item in 3D space.

---

## Overview

After classification, the app could show the user:

1. **Decomposition timeline**: "This plastic bottle takes 450 years to break down. Here's what it looks like in years 1, 10, 100, 450."
2. **Material journey**: "This carton goes from your bin → MRF → pulper → recycled paper. Watch the journey."
3. **Recycled product outcome**: "Your bottle becomes a fleece jacket. Here it is."
4. **Disassembly guide (AR overlay)**: "Point your phone at this electronics item. I'll show you how to remove the battery."

---

## Technical Feasibility Assessment

### ARKit / ARCore Compatibility

| Capability | iOS (ARKit) | Android (ARCore) | Web (WebXR / model-viewer) |
|-----------|-------------|-------------------|---------------------------|
| Plane detection | ✅ Mature | ✅ Mature | ❌ Limited |
| Object anchoring | ✅ | ✅ | ❌ |
| Face tracking | ✅ | ✅ | ❌ |
| Model rendering | ✅ 60fps | ✅ 60fps (high-end) | ✅ Limited (30fps) |
| Scene persistence | ✅ World Map | ✅ Cloud Anchors | ❌ |
| Mid-range device support | ✅ iPhone 8+ | 🔴 Fragmented | ✅ Any browser |

### Feasibility on Mid-Range Devices

| Aspect | Assessment |
|--------|-----------|
| ARKit performance | ✅ 60fps on iPhone 11+ (mid-range iOS). iPhone 8/X borderline. |
| ARCore performance | 🟡 Good on Pixel/OnePlus mid-range; poor on Samsung A-series (heating, dropped frames) |
| Thermal budget | 🔴 AR is one of the highest-thermal phone activities. Even 2-3 minutes causes throttling on mid-range. |
| Battery drain | 📉 Estimated 15-20% per 10 minutes of AR. |
| Model complexity | 3D models must be < 5MB for acceptable load time. Complex decomposition scenes (decaying bottle) need > 50MB. |
| First-load delay | ARKit/ARCore require 0.5-2s for plane detection. User patience in a utility app is ~2s. |

### Verdict

**AR for a utility/tool app is high-risk.** Users open the app to dispose of waste, not for a 3D experience. The thermal/battery cost makes AR appropriate only for deep educational or celebration moments, not routine classification.

---

## Viable Approaches (Ranked)

### Approach 1: Web-Based AR (model-viewer) — Recommended First Step

- Use Google's `<model-viewer>` web component embedded in the app.
- Render a single 3D model (e.g., a bottle with a degradation slider) after classification.
- Works cross-platform without native ARCore/ARKit integration.
- Can be a web-view or a deep-link to a hosted micro-site.

| Pros | Cons |
|------|------|
| Zero native SDK complexity | Less immersive (not anchored in real space) |
| Works on all devices | Requires network |
| Can A/B with static infographic | 3D model loading adds latency |
| 10MB page budget vs 100MB+ native AR | |

### Approach 2: Static Side-By-Side Comparison (Cheapest Viable)

Instead of real AR, show:

- A static 3D render (pre-baked, server-rendered) of the item's degradation at key milestones.
- A scrollable timeline with visual transitions.
- A "journey map" infographic.

**This is the minimum viable approach** and should be the default. Real AR adds marginal educational value over a high-quality 3D render with scrollable timeline.

### Approach 3: Real AR Overlay (Deferred)

Reserve for:

- Celebration moments (1000th classification — show a 3D tree growing from the user's bin).
- Premium-tier education feature.
- Classroom mode (teacher-supervised AR session).

---

## AR Content Types and Complexity

| Content Type | 3D Model Size | Production Cost | Educational Value |
|-------------|---------------|-----------------|-------------------|
| Decomposition slider (bottle, can, paper) | 3-10MB per model | $200-500/in-house Blender | High |
| Material journey animation | 5-15MB per animation | $500-2000/animation | Medium |
| Recycled product visualization | 2-8MB per item | $200-500/item | Medium |
| Disassembly guide overlay | 10-30MB per guide | $1000-3000/guide | High (but niche) |
| Interactive 3D quiz | 5-20MB | $500-1000 | High |

**Recommendation**: Start with 2 decomposition models (plastic bottle, paper) as a pilot. Measure engagement (click rate, sharing, time-on-content). Scale only if metrics justify.

---

## UX Design

### Trigger Points

1. **After classification result**: A subtle "See what happens to this item over time" link below the disposal instructions.
2. **Impact page**: "Your items decomposed this year" — aggregate visualization.
3. **Education module**: In the learning path, after completing "Why recycling matters."
4. **Learning corner**: Animated infographic
5. **Eco Wrapped**: In the annual impact story, show sum of items and their aggregate environmental impact.

### Design Principles

- **AR must be optional and non-blocking**. Never force the user into AR to get standard disposal instructions.
- **Static fallback always works**. If AR fails to load or device doesn't support it, show the scrollable infographic.
- **One interaction per session**. Don't chain AR experiences.
- **Thermal warning on mid-range**. If device battery < 20%, skip AR and show static version.

---

## Kill Criteria

1. After 4 weeks, click-through on AR/3D content is < 3% of classifications.
2. Static infographic version shows equal or better retention (users don't miss AR).
3. Thermal complaints from mid-range devices exceed 1% of AR sessions.
4. 3D model production cost exceeds educational value (measured via quiz scores before/after).

---

## Concrete Next Steps

1. ✅ Do not build AR integration yet.
2. Create 2 static 3D renders (plastic bottle, paper) rendered server-side as animated GIF/webp.
3. A/B test: animated 3D render vs static infographic vs no extra content.
4. Measure: time-on-content, sharing rate, quiz completion, classification retention (do users come back more?).
5. Only if A/B shows clear engagement lift, prototype web-based `<model-viewer>` for a single item.
6. Re-evaluate native AR (ARKit/ARCore) when and if the classroom B2B wedge (#29) specifies it as a requirement.

---

## Research Sources

- Google `<model-viewer>` documentation — web-based 3D rendering standard.
- ARKit 6 (iOS 18) — plane detection, object anchoring, scene understanding.
- ARCore Geospatial API — persistent AR anchors.
- WWF Free River AR (2019) — educational AR case study with ~2M downloads.
- IKEA Place — AR commerce reference for item-in-space rendering.
