# Home Launch Hardening — Execution Audit

**Date:** 2026-05-22
**Scope:** Home screen (`lib/screens/home_screen.dart`) launch hardening
**Status:** IN PROGRESS

---

## Task 1: Runtime References Verification

### Finding: MainNavigationWrapper correctly uses HomeScreen

```textnFile: lib/widgets/navigation_wrapper.dart
Line 177-185: _getScreens() returns HomeScreen at index 0
Line 74: Global popup suppression: if (delta > 0 && mounted && _currentIndex != 0)
Line 83: Achievement suppression: if (mounted && _currentIndex != 0)
```

Conclusion: Navigation wrapper correctly routes to `HomeScreen`. No active runtime references to `UltraModernHomeScreen` remain outside its own file. The deprecated screen is self-contained.

### Recommendation for UltraModernHomeScreen

After UI revamp is approved, remove `lib/screens/ultra_modern_home_screen.dart` entirely. Until then, the `@Deprecated` annotation is sufficient.

---

## Task 2: Duplicate Data Reads

### Finding: `todayGoalProvider` reads all classifications independently

```textnFile: lib/providers/app_providers.dart
Lines 67-83: todayGoalProvider reads via `storageService.getAllClassifications()`
File: lib/screens/home_screen.dart
Lines 196, 927: classificationsProvider also reads the same data
```

`todayGoalProvider` and `classificationsProvider` both call `getAllClassifications()`. `todayGoalProvider` then filters for today's classifications. When Home watches both providers, the storage service fetches all classifications twice.

### Fix Plan
Derive today's goal from `classificationsProvider` rather than reading storage again. This unifies the data path and prevents double-fetch.

---

## Task 3: Popup Authority

### Finding: Home manages its own result popups; wrapper suppresses global stream popups when on Home tab

```textnFile: lib/screens/home_screen.dart
Lines 1806-1832: Navigator.push returns GamificationResult; Home shows points popup + achievement celebration
File: lib/widgets/navigation_wrapper.dart
Lines 72-77: Points popup suppressed when _currentIndex == 0
Lines 80-86: Achievement celebration suppressed when _currentIndex == 0
```

Home receives `GamificationResult` from `ImageCaptureScreen` and shows points/achievement popups. The wrapper suppresses the global `PointsEngine` popups when on the home tab. This avoids duplicates.

**Risk:** If instant analysis or other flows emit via `PointsEngine` but don't return a `GamificationResult` to Home, the wrapper will suppress the popup and Home won't show one.

**Mitigation needed:** Add targeted test or integration test to verify popup flows.

---

## Task 4: Capture Flow Duplication

### Finding: HomeScreen._pickAndRouteImage and NavigationWrapper have similar but not identical capture logic

```textnFile: lib/screens/home_screen.dart
Lines 1749-1839: _pickAndRouteImage handles camera permission, PlatformCamera fallback, image quality 85, maxWidth 1920, maxHeight 1080
File: lib/widgets/navigation_wrapper.dart
Lines 303-441: _takePictureDirectly handles camera permission, PlatformCamera fallback, image quality 85, maxWidth 1200, maxHeight 1200; _pickImageDirectly uses maxWidth 1200, maxHeight 1200
```

Differences:
- Home: maxWidth=1920, maxHeight=1080
- FAB: maxWidth=1200, maxHeight=1200
- Home also routes to `InstantAnalysisScreen`; FAB routes only to `ImageCaptureScreen`

**Recommendation:** Extract shared capture logic or at least unify image constraints. This is a launch risk for inconsistent permissions and image sizing.

---

## Task 5: Missing Tests

### Current tests (from home_screen_test.dart):
- Mission and action surfaces rendered
- Settings navigation
- Learn navigation
- Recent sorting and cap at 3
- View All opens history
- Error state shows retry
- Empty state with CTAs
- Daily tip preferred category (fresh vs stale)
- Small width + text scale (320px, 1.5x)

### Missing tests:
- Daily progress card renders with today goal
- Near milestone nudge renders and taps to Achievements
- Community impact card renders and taps to WasteDashboard
- Active challenge card renders, clamps progress, taps to Achievements
- Daily tip with contentId opens ContentDetailScreen
- No overflow at 320 width and text scale 2.0
- Dark mode smoke test
- Capture button behavior (requires picker abstraction)

---

## Next Steps

1. Fix `todayGoalProvider` to derive from `classificationsProvider`
2. Unify capture image constraints or extract shared helper
3. Add missing tests
4. Run `flutter analyze` and `flutter test`
