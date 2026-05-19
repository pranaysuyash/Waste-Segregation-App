# Enhancement Backlog

* Source: `stash@{1}` (`docs/QUICK_WINS_TODO.md`, never merged)
* Last updated: 2025-06-20 (backlog compilation from stash)
* Status: aspirational reference — items are ideas, not commitments

---

## How to use this document

This is a **preserved backlog** recovered from a stash that was never merged. Items here represent past thinking about what to build next. They are **not** current priorities — the project roadmap (`docs/planning/roadmap/unified_project_roadmap.md`) is the source of truth for what's being worked on now.

Use this as:
- A reference when planning sprints
- A source of ideas when current roadmap items are complete
- A "don't lose" preservation of past planning work

---

## Core Infrastructure

### Material You Dynamic Color
- Implement dynamic color theming using the `dynamic_color` package
- Already partially in main: `dynamic_color` is in pubspec, need to wire it into theme
- Status: already in main's pubspec.yaml, needs full integration

### Adaptive Navigation
- Navigation rail / list-detail layout for larger screens (tablets, desktops)
- Follows ADR-001 clean architecture guidance
- Status: aspirational

### Dark Mode / High Contrast Theme
- Full dark mode support with proper contrast ratios
- High-contrast theme option for accessibility (WCAG AAA)
- Status: aspirational

### Widget-Tree Modularization
- Break large screens (home, settings, result) into smaller reusable widgets
- Status: in progress per ADR-001 migration

---

## Gamification & Engagement

### Leaderboard
- Global leaderboard of top contributors
- Weekly and all-time views
- Status: aspirational — see `docs/planning/roadmap/SOCIAL_GAMIFICATION.md`

### Social Sharing (Enhanced)
- Share classification results with custom cards
- Share achievements on social media
- Status: early exploration — `share_plus` already in pubspec

### Cross-User Classification Caching with Firestore
- Share classification results across users to reduce API costs
- Deduplicate identical items
- Status: planned, not started

### Camera Package Upgrade
- Upgrade `camera` package for direct camera preview
- Enhanced camera UI with zoom, flash, focus
- Status: deferred — see `docs/technical/features/camera_architecture.md`

### Offline Facility Mapping
- Download facility maps for offline use
- Cache facility data in Hive
- Status: aspirational

---

## UI/UX Polish

### Re-Analysis UI Hook
- "Analyze again" button on result screen with different model
- Progress indicator during re-analysis
- Status: mentioned in stash 1, may already exist

### Premium Feature Visuals (VIS-22)
- Grey-out segmentation switch for free tier
- Crown icon on premium-locked features
- Upgrade banner with clear value proposition
- Status: aspirational

### Animated Empty States
- Beautiful animated illustrations for empty screens
- Contextual messages encouraging action
- Status: foundation phase mentioned as complete in stash 1

### Semantic Labels Sweep (T-05)
- Audit charts, animations, and interactive elements for missing `Semantics` / `semanticLabel`
- Integration tests verifying semantic coverage
- Reusable helper: `withSemantics` wrapper in `lib/utils/ui_consistency_utils.dart` (line ~629)
- Cross-reference: design docs document a complete Semantics Pass (UX-03 in `docs/design/user_experience/ux_2025_custom_tasks.md`)
- Status: partially completed — remaining work on charts/animations

### Educational Content UX (from stash 7, never merged)
- **Advanced filter system**: toggleable filter UI with ContentLevel (beginner/intermediate/advanced), Bookmarked Only, Premium Only toggles, reset button
- **Persistent search history**: recent searches bar when query empty, delete management (clear all or tap-to-research), clear icon in search field
- **Dedicated Bookmarks tab**: 7th navigation tab with specialized empty state ("Explore content to bookmark")
- **Level indicators on cards**: color-coded difficulty badges (green=beginner/looks_one, orange=intermediate/looks_two, red=advanced/looks_3)
- Source: `stash@{7}` educational content screen rewrite
- Status: aspirational — UX patterns preserved; implementation would need current screen architecture

### Low-Confidence Warning Banner
- Warning banner when AI confidence is below threshold
- Suggest manual review or re-capture
- Status: foundation phase mentioned as complete in stash 1

---

## Animation Enhancements

### Loading States
- Skeleton loading for classification results
- Shimmer effects for lists and cards
- Status: partially implemented

### Transitions
- Hero animations between screens
- Shared element transitions
- Page transitions (slide, fade, scale)
- Status: partially implemented

### Celebrations
- Confetti on achievement unlock
- Trophy/loot box opening animations
- Streak milestone celebrations
- Status: partially implemented

### Educational Content Animations
- Interactive infographics with animated elements
- Progress animations for quizzes
- Animated tutorial step transitions
- Status: aspirational

### Social Widget Animations
- Like/heart button bounce animation
- Share button ripple effect
- Contribution streak fire animation
- Status: aspirational

---

## Quality & Testing

### CI/CD
- Automated test runs on PR
- Code quality gate
- Build verification
- Status: aspirational

### E2E Testing
- Full user flow tests
- Cross-platform testing
- Status: 0% passing (test infrastructure failure)

### Performance Budgets
- Startup time < 2 seconds
- Classification < 5 seconds
- Scroll jank-free
- Status: aspirational

### Crash Reporting
- Firebase Crashlytics integration
- Error boundary UI
- Status: not started

---

## Security & Connectivity

### Connectivity Protection
- Graceful offline handling
- Queue classification requests when offline
- Sync when reconnected
- Status: partially implemented (offline_queue_service.dart exists)

### Firestore Security Rules
- Properly scoped read/write rules
- Data validation in rules
- Status: in progress

---

## Implementation Priority Order (from stash 1)

The stash 1 document proposed this priority order (preserved for reference):

1. **Phase 1 — UI/UX Foundation**: Analytics tracking, empty states, warning banners, visual modernization
2. **Phase 2 — Interactions**: Material You, re-analysis UI, premium features, adaptive nav
3. **Phase 3 — Animation Polish**: Loading states, transitions, celebrations, educational animations
4. **Phase 4 — Advanced Features**: Social widgets, admin dashboard, skeleton/optimistic states

---

## Links

* Source stash: `stash@{1}` (`feature/material-you-dynamic-color`)
* Original file: `docs/QUICK_WINS_TODO.md` (preserved in stash 1)
* Current roadmap: `docs/planning/roadmap/unified_project_roadmap.md`
* ADR-001: `docs/adr/ADR-001-clean-architecture.md`
* Social/Gamification roadmap: `docs/planning/roadmap/SOCIAL_GAMIFICATION.md`
* Camera architecture: `docs/technical/features/camera_architecture.md`
* Data sync strategy: `docs/adr/ADR-003-data-sync-strategy.md`
* Design docs — Semantics Pass UX-03: `docs/design/user_experience/ux_2025_custom_tasks.md`
* Accessibility guide: `docs/design/user_experience/accessibility/accessibility_implementation_guide.md`
