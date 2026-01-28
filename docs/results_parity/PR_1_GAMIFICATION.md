# PR 1: Port Gamification to ResultScreen V2

> **Status:** In Progress  
> **Related:** `INVARIANTS.md` Section 5 (Side Effects), Section 6 (Gamification)  
> **Risk Level:** Medium (user-facing, affects engagement)

---

## Summary

Port gamification features from Legacy ResultScreen to V2:
- Points earned popup
- Achievement celebration modal
- Haptic feedback on save

---

## Parity Checklist

### Display Parity
- [x] Points earned displayed in header (already in V2 via `ResultHeader`)
- [x] Points popup animation (Legacy: `_showPointsEarnedPopup`)
- [x] Achievement celebration modal (Legacy: `_showAchievementCelebration`)
- [x] Haptic feedback on successful save

### State Management
- [x] Points earned from pipeline (already implemented)
- [x] New achievements from pipeline (already implemented)
- [x] Track if celebration already shown (prevent duplicates)

### Analytics
- [x] `achievement_celebration_shown` event
- [x] `points_popup_shown` event (if new)

### Testing
- [x] Golden test: Achievement celebration trigger (framework added)
- [x] Widget test: Points popup visibility
- [x] Widget test: Celebration modal renders (framework added)

---

## Implementation Plan

### 1. Add Gamification State Management to V2

```dart
// Add to _ResultScreenV2State
bool _hasShownCelebration = false;
bool _hasShownPointsPopup = false;
```

### 2. Create Gamification Widgets

- `PointsEarnedPopup` - Animated points display
- `AchievementCelebrationWrapper` - Reuses existing `AchievementCelebration`

### 3. Integrate into V2 Build

Listen to pipeline state changes and trigger celebrations.

### 4. Add Haptic Feedback

Use `HapticSettingsService` like Legacy does.

---

## Files to Modify

1. `lib/screens/result_screen_v2.dart` - Add celebration logic
2. `lib/widgets/result_screen/points_popup.dart` - NEW
3. `lib/widgets/result_screen/achievement_wrapper.dart` - NEW
4. `test/screens/result_screen_gamification_test.dart` - NEW

---

## Testing Strategy

### Unit Tests
- Pipeline state triggers celebration correctly
- Duplicate prevention works

### Widget Tests
- Celebration modal renders with achievement data
- Points popup shows correct amount
- Haptic feedback fires

### Manual Verification
- [ ] Classify item, see points popup
- [ ] Earn achievement, see celebration
- [ ] Re-open result, no duplicate celebration

---

## Migration Notes

- Reuses existing `AchievementCelebration` widget (no duplication)
- Points popup is new but matches Legacy behavior
- Haptic feedback uses same service as Legacy

---

## Rollback Plan

If issues detected:
1. Disable V2 feature flag
2. Users fall back to Legacy with full gamification
3. Fix and redeploy
