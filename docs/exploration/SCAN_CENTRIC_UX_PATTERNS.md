# Scan-Centric UX Patterns

**Purpose**: Competitive teardown and gap analysis of scan-centric UX patterns applied to waste classification.
**Status**: Exploration — no doc exists; practice deviates from scan-centric conventions
**Last Updated**: 2026-05-25
**Related**: [NAVIGATION_IA.md](NAVIGATION_IA.md), [HOME_SCREEN_IA.md](HOME_SCREEN_IA.md), [ONBOARDING_AND_ACTIVATION.md](ONBOARDING_AND_ACTIVATION.md)

---

## Problem Statement

The app is scan-centric (primary action: point camera at waste, get classification) but the UI is structured like a content-feed app (5-tab nav, dashboard home screen, social feed). This adds friction to the primary use case: quick scan while standing at a bin.

Current cold-launch-to-scan funnel: App → Home screen (header, stat chips, activity feed) → Tap profile icon → Locate scan CTA → Frame subject → Tap capture → Wait for result. This is 4-5 taps minimum.

---

## Competitive Pattern Matrix

| App | Primary Use | Camera Auto-Open | Scan CTA | Result Display | Re-Scan Pattern | Haptics |
|-----|------------|-----------------|----------|---------------|-----------------|---------|
| **Yuka** | Food/cosmetic scan | Manual via tab | Tab 2 of 4 | Bottom sheet overlay | Dismiss → scan again | Light haptic |
| **PictureThis** | Plant ID | Yes (on home) | Persistent widget | Full-screen overlay | Swipe to dismiss | Audio + haptic |
| **Google Lens** | General visual search | Immediate | In viewfinder | Bottom sheet | Instant re-scan | Visual + subtle haptic |
| **FoodKeeper** | Food storage data | No (nav-based) | None (search) | List view | Manual back | None |
| **Recycle Coach** | Waste lookup | No (search-based) | Search bar | Card view | Manual back | None |
| **Current App** | Waste classification | Manual (scan tab) | Tab 3 of 5 | Full page result | Back-to-scan button | None |

---

## Industry Standards

### Cold Launch to Result: Target ≤ 2 Taps

The ideal flow: Tap app icon → Camera viewfinder active → Auto-scan or single tap → Result. No dashboard, no stat chips, no feed between user and scan.

### Camera Auto-Open After Permission Grant

Best practice: If camera permission is granted, open the viewfinder directly. If not, show permission explanation *within* the viewfinder as an overlay, not as a separate onboarding step.

### Instant Re-Scan

After a result, the user's next action is likely to scan another item. Offer one-tap re-scan from the result screen (half-sheet overlay, camera still active in background).

### Feedback Signals

- **Success**: Crisp haptic + subtle confirmation tone
- **Error/No match**: Double-pulse haptic + muted tone
- **Processing**: Subtle ambient animation (not a spinner blocking the camera)

---

## Gap Analysis

| Capability | Current State | Target State |
|-----------|--------------|--------------|
| Taps to first scan | 4-5 (app open → nav → scan → capture) | ≤ 2 (app open → auto-scan → result) |
| Camera on launch | Only on scan tab | Persistent viewfinder or one-tap from anywhere |
| Re-scan speed | Manual back → reframe → capture | Dismiss result → next scan ready |
| Haptic feedback | None | Success/error haptic patterns |
| Result presentation | Full page (loses camera context) | Bottom sheet over camera (maintains context) |
| Offline result UX | Error state | Cached result + "offline" badge |

---

## Key Design Decisions

1. **Scan CTA**: Persistent FAB overlay on all tabs vs dedicated scan tab vs camera-first launch?
2. **Result persistence**: How long does the result stay visible before auto-dismiss?
3. **History integration**: Should recent scans be accessible from the viewfinder (swipe down)?
4. **Multi-item scan**: Does the scan session support rapid sequential scanning without leaving camera mode?

---

## Implementation Recommendations

1. **Phase 1**: Add haptic feedback to scan success/failure (low effort, high UX impact)
2. **Phase 2**: Convert result screen to bottom sheet overlay over camera preview
3. **Phase 3**: Add quick re-scan gesture (swipe down to dismiss result → camera ready)
4. **Phase 4**: Evaluate camera-first launch as A/B test variant
5. **Phase 5**: Persistent FAB overlay experiment (scan available from any tab)
