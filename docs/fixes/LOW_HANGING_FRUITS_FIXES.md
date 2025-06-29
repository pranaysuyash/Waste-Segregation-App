# Low-Hanging Fruits Fixes

This document tracks quick win fixes that improve the user experience without major refactoring. These items were addressed as part of routine polish.

## Completed Fixes

1. **Consistent Dialog Button Styling**
   - Added `dialogCancelButtonStyle`, `dialogConfirmButtonStyle`, and `dialogDestructiveButtonStyle` helpers in `constants.dart`.
   - Applied these styles to all permission dialogs and confirmation prompts for a unified look.

2. **Toast Timing Cleanup**
   - Removed automatic "Sign in to save" toasts from the authentication flow.
   - Static informational text on the auth screen now explains the benefits of signing in.

3. **Profile Menu Label Update**
   - Renamed the "Profile" menu option to "Settings" in `modern_home_screen.dart` to better reflect the destination screen.

4. **Save/Share Button Consistency**
   - Added a temporary `_showSavedState` flag so the "Saved" message displays for one second before turning into "Share".
   - Ensures the main action button is always functional and clearly communicates its state.

5. **Web Standalone Debug Prints Guarded**
   - Wrapped initialization debug prints in `web_standalone.dart` with `kDebugMode` so they only appear in debug builds.

These fixes remove small UX papercuts and make the app feel more polished.

## June 2025 Additions

6. **Color Palette Refresh**
   - Updated category colors in `constants.dart` to the new "Living Earth" palette.

7. **Animated Capture Button**
   - Added a subtle press animation in `capture_button.dart` using `AnimatedScale`.

8. **History Filter Dialog Polish**
   - Inserted dividers and spacing for clearer grouping in the history screen filter dialog.

9. **Educational Content Analytics**
   - Basic view and completion tracking hooked up via `EducationalContentAnalyticsService`.

10. **Settings Accessibility Improvements**
    - Wrapped toggle controls in `Semantics` widgets for better screen reader support.
