# UX Improvements Task List (2025)

This file tracks specific user experience tasks derived from the 2025 mobile UX research. Each task has an ID, title, definition of done, and difficulty indicator.

| ID | Title | Definition of Done | Difficulty |
| --- | --- | --- | --- |
| UX-01 | Adaptive Layout Refactor | Home & History respond correctly at 360 dp, 600 dp (rail), 840 dp (list-detail) with golden tests. | ⚙️ Medium |
| UX-02 | Dynamic Color + Dark Mode | `ThemeData` switches via `MediaQuery.platformBrightness`; contrast ratios ≥ 4.5:1 verified. | ⚙️ Medium |
| UX-03 | Complete Semantics Pass | 100 % tappables labelled; no `flutter analyze --fatal-warnings` a11y issues. | 🔧 Easy |
| UX-04 | Camera Overlay & Pinch-Zoom | Grid overlay toggle + pinch-zoom on both Android & iOS; unit test records zoom value. | ⚙️ Medium |
| UX-05 | Progressive Onboarding | First-run flow with skip button, persisted in `SharedPreferences`; A/B test enable flag. | ⚙️ Medium |
| UX-06 | Empty-State Illustrations | Replace blank screens with Lottie animations and contextual CTAs. | 🔧 Easy |
| UX-07 | i18n Pipeline Setup | All strings extracted, Hindi/Kannada bundles added; language picker in settings. | ⚙️ Medium |
| UX-08 | Haptic Success Feedback | `HapticFeedback.lightImpact()` on positive scan; user toggle in settings. | 🔧 Easy |

Each task should be implemented as an isolated pull request with appropriate tests or documentation updates.
