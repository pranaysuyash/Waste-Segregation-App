# iOS / Android / Web Cross-Platform Parity

**Purpose**: Document which features intentionally diverge vs accidentally diverge across iOS, Android, and Web platforms.
**Status**: Exploration — `IOS_ANDROID_PARITY.md` exists as worklog; no systematic matrix
**Last Updated**: 2026-05-25
**Related**: [ON_DEVICE_INFERENCE.md](ON_DEVICE_INFERENCE.md), [AB_TESTING_AND_FEATURE_FLAGS.md](AB_TESTING_AND_FEATURE_FLAGS.md), [LAUNCH_AND_STORE_COMPLIANCE.md](LAUNCH_AND_STORE_COMPLIANCE.md)

---

## Problem Statement

"Where does this feature work?" and "what subset works on each platform?" determines the actual install/activation funnel. On-device inference, ATT, push notifications, AdMob, and in-app purchases all diverge per platform. Today there's no single source of truth for platform parity.

---

## Feature Parity Matrix

| Feature | iOS | Android | Web | Notes |
|---------|-----|---------|-----|-------|
| **Camera classification** | ✅ | ✅ | 🔴 (no camera) | Web uses upload |
| **On-device inference** | 🟡 (Core ML) | 🟡 (NNAPI/TFLite) | 🔴 | Needs NPU detection |
| **Push notifications** | ✅ (APNs) | ✅ (FCM) | 🔴 | Web only via service workers |
| **App Check** | ✅ | ✅ | 🔴 | Device attestation only |
| **In-app purchases** | ✅ (StoreKit) | ✅ (Play Billing) | 🔴 | Web uses different vendor |
| **Face/plate blur (on-device)** | 🟡 (Vision) | 🟡 (ML Kit) | 🔴 | Not available |
| **Background processing** | 🟡 (BGTaskScheduler) | ✅ (WorkManager) | 🔴 | iOS has stricter limits |
| **AdMob** | ✅ | ✅ | 🔴 | Web uses different network |
| **Dynamic links** | ✅ | ✅ | 🟡 (limited) | Web fallback URL |
| **Offline queue** | ✅ | ✅ | 🟡 (limited) | Service worker storage limits |
| **Haptics** | ✅ | ✅ | 🔴 | Not available |
| **Keyboard shortcuts** | 🔴 | 🔴 | ✅ | Web only |
| **Multi-window** | 🔴 | ✅ | ✅ | iOS does not support |

---

## Feature Divergence Classification

### Intentionally Divergent (by design)

| Feature | Platform Difference | Rationale |
|---------|-------------------|-----------|
| On-device inference tier | Flagship Android (NPU) vs iOS (Neural Engine) | Hardware capability varies |
| Background processing | Android more capable (WorkManager) | iOS BGTaskScheduler has tighter limits |
| Push notification delivery | Android more consistent | iOS requires user opt-in via ATT |
| Web camera | Upload only | No camera access in web browsers |

### Accidentally Divergent (need fixing)

| Feature | Platform Difference | Action |
|---------|-------------------|--------|
| Haptic feedback | Missing on some Android devices | Test and standardise |
| Ad placement | Different fill rates per platform | Unify ad strategy |
| Crash reporting | Different capture rates | Unify crash service config |

### Not Applicable

| Feature | Why |
|---------|-----|
| Web camera classification | Browser limitations |
| iOS background fetch | API constraints |
| Web push notifications | Different UX expectations |

---

## Key Decisions Needed

1. **Web role**: Landing surface, demo, full app, or progressive fallback?
2. **Feature flag strategy**: Should features be flagged per platform even when possible?
3. **Minimum parity bar**: What features must work on all platforms before launch?

---

## Open Questions

- Should on-device model selection be device-tier-aware or platform-aware?
- How do we test cross-platform feature drift in CI?
- Should premium features be platform-consistent or platform-optimised?

---

## Next Steps

1. Build parity matrix as living document in code (Dart constants)
2. Add platform checks to feature flag definitions
3. Document web's explicit role and limitations
4. Fix any accidentally divergent features found in audit
