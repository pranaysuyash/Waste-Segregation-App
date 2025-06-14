# 🗂️ Consolidated TODOs — 2025-06-14

This file aggregates all actionable TODOs, open tasks, and incomplete checklist items from the documentation. Items are grouped by category and sub-sorted by priority for immediate planning and review.

---

## 🚀 HIGH PRIORITY

### AI & Core Features
- [ ] LLM-Generated Disposal Instructions: Replace hardcoded steps with LLM service (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Firebase Integration & Migration: Complete data migration, analytics, and backup/rollback (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] AI Classification Consistency & Re-Analysis: Add re-analysis option, confidence warnings, and feedback aggregation (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Image Segmentation Enhancement: Complete SAM integration, multi-object detection, and user controls (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] "Re-Scan" Button on Results Screen: Let users re-run classification on the same image (e.g. after adjusting camera framing or lighting)
- [ ] Confidence Threshold Slider in Settings: Allow power users to adjust the minimum confidence at which the AI auto-classifies vs. prompts for manual review
- [ ] Batch Classification: Add a gallery multi-select so users can queue up several images at once for back-to-back classification

### UI/UX & Platform
- [ ] Android vs iOS Native Design Language: Implement platform-specific UI, navigation, and animations (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Modern Design System Overhaul: Add dark mode, glassmorphism, micro-interactions, and dynamic theming (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Camera Permission Retry: If the user denies camera access, show a friendly in-app walkthrough on how to re-enable permissions
- [ ] Segmentation Fail States: Handle cases where no objects are detected (offer manual crop tool as fallback)
- [ ] Rate-Limit Feedback: If the LLM or Vision API throttles you, display a "please wait" indicator rather than a generic error

### Technical Debt & Security
- [ ] Firebase Security Rules: Add comprehensive Firestore rules, data access control, and analytics protection (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Performance & Memory Management: Optimize analytics, image caching, and memory leak prevention (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Error Handling & Resilience: Add comprehensive error handling, retry mechanisms, and data consistency checks (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Security Rules Testing: Automate Firestore rule tests in CI (e.g. via the Firebase Emulator Suite)

### CI/CD & Quality Gates
- [ ] Docs-Lint Workflow: Add a GitHub Action to fail the build if any TODOs remain in markdown or code (e.g. using markdown-todo-lint or a custom script)
- [ ] Code Quality Checks: Enforce dart analyze, flutter test --coverage, and dart_code_metrics on every PR (blocking merge if thresholds drop)

### Family & Social Features
- [ ] Family Management: Implement name editing, copy ID, toggle public/share, show member activity (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Family Invite: Implement share via messages, email, and generic share (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Achievements: Implement challenge generation and navigation to completed challenges (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)

### Security & Privacy
- [ ] Data Protection: Add granular privacy settings, consent management, analytics opt-out, and data deletion/export tools (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Security Hardening: Input validation, SQL injection prevention, rate limiting, audit logging (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)

### Offline & Sync Behavior
- [ ] Offline Queue: Cache scans and classification requests while offline, then auto-sync when connectivity returns
- [ ] Conflict Resolution UX: If a user edits or deletes an offline scan, provide in-app merge/conflict dialogs when syncing
- [ ] Connectivity Indicator: Show a subtle banner or icon when offline, with "reconnect to sync" call-to-action

---

## ⚡ MEDIUM PRIORITY

### Location & Community
- [ ] User Location & GPS Integration: Add geolocator, permissions, GPS calculations, and location-based sorting (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] User-Contributed Disposal Information: Add facility editing UI, community verification, reputation, and moderation tools (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)

### UI/UX
- [ ] Modern Design System: Add micro-interactions, hover effects, and smooth transitions (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Platform-Specific UI: Responsive design improvements, animation implementations (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)

### Testing & Quality
- [ ] Comprehensive Testing: Add unit, integration, widget, end-to-end, and performance tests (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] Code Quality: Add documentation, code coverage, automated testing pipeline, and review checklist (see `docs/planning/MASTER_TODO_COMPREHENSIVE.md`)
- [ ] End-to-End Tests for Reset/Delete: Write Flutter integration tests that simulate a user tapping "Reset Account" and verify data is gone
- [ ] Restore Flow Tests: In emulator, archive → delete → restore → assert user data and auth are fully back
- [ ] Inactive-Cleanup Cron Simulator: Add a test harness to fast-forward clock and run the cleanup, verifying logs

### Accessibility & Internationalization
- [ ] a11y Audit: Run an accessibility scanner (e.g. accessibility_test package) against key screens and surface failures as tasks
- [ ] Dark-Mode QA: Add visual regression tests (e.g. via golden_toolkit) to ensure both light and dark themes render correctly
- [ ] Localization Completion: Validate generated ARB files against translations missing keys
- [ ] Automate "missing translations" reports in CI
- [ ] Voice-Guided Scan: For low-vision users, guide them through framing via haptic/audio cues ("move phone up")
- [ ] Large-Text Mode: Override UI to use extra-large fonts for key screens, respecting system accessibility settings

### User Feedback & Reporting
- [ ] In-App Feedback Widget: Let users flag a misclassification directly from the Results screen, sending image + category for review
- [ ] Usage Survey: After a few scans, prompt opt-in for a 1-minute survey on accuracy and feature requests

### Analytics & Telemetry
- [ ] Event Instrumentation: Track key events—scans started, scans succeeded, scans failed, re-analysis used, share actions—to inform product decisions
- [ ] Funnel Analysis: Add custom events around onboarding, first scan, and sharing to identify drop-off points

### Personalization & Settings
- [ ] Scan Presets: Allow users to save common "scan contexts" (e.g. kitchen vs. office) that pre-select disposal categories or filters
- [ ] Custom Categories: Enable power users to define new waste categories (e.g. "e-waste") and map them to existing disposal instructions

### Social & Sharing
- [ ] One-Tap Share: Build share cards (image + "I just recycled a plastic bottle!") for Instagram/WhatsApp
- [ ] Group Challenges: Allow users to "invite a friend" to a mini-challenge (e.g. "Recycle 10 items this week") directly from the app

### Monitoring & Observability
- [ ] Crashlytics Verification: Beyond wiring, write a sanity check that ensures you're receiving real crash events (e.g. a test crash)
- [ ] Performance Benchmarks: Create a benchmark script to record image-segmentation latency on typical mid-range devices

### Dev-Phase Debug Tools
- [ ] Hidden Debug UI: Document and implement the /debug panel behind ENABLE_DEBUG_UI flag—list the routes and stub out buttons
- [ ] Feature-Flag Config: Create a simple feature_flags.md listing all flags (enable_account_cleanup, enable_restore_ui, etc.) and their default settings

### Backup & Disaster Recovery
- [ ] Firestore Backup Validation: Write a small script or Cloud Function that periodically verifies your daily backups contain expected collections/doc counts
- [ ] Rollback Drill: Document and script a rollback procedure in case a migration goes wrong—test it end-to-end in a staging project

### Documentation Gaps
- [ ] Feature-Flag Guide: Add a short doc (docs/admin/feature_flags.md) explaining how to flip flags, where they live, and the intended use
- [ ] Admin Panel Spec: If you haven't already, write up the high-level wireframe and API contract for the archive/restore screens in docs/admin/restore_spec.md

---

## 📝 LOW PRIORITY

### Documentation & Maintenance
- [ ] Update API documentation for new features
- [ ] Create developer guides for platform-specific UI
- [ ] Add code examples for community contributions
- [ ] Update user guides with new feedback features
- [ ] Doc-as-Code Migration: Move /docs to Docusaurus, auto-publish to GitHub Pages
- [ ] Design-Token Reference Page: Create /docs/design/design_tokens.md

### UI Polish
- [ ] App Logo: Replace Flutter logo with custom logo
- [ ] Loading States: Add modern loading states and skeletons
- [ ] Chart Accessibility: Make charts screen-reader friendly

---

## 🛠️ TECHNICAL DEBT (Ongoing)
- [ ] Provider Cleanup & Documentation: Standardize provider usage, add ADR
- [ ] Remove TODO comments from production code (40+ identified)
- [ ] Complete code TODOs in ad_service.dart, family_management_screen.dart, ai_service.dart, storage_service.dart, gamification_service.dart, and others (see `docs/project/CONSOLIDATED_ISSUES_LIST.md`)

---

## 📋 QUICK WINS
- [ ] Crashlytics & Sentry Wiring: Capture uncaught exceptions, verify dashboard reception
- [ ] Connectivity Watchdog: Wrap API calls in NetworkGuard, add offline user toast
- [ ] Firestore Security Rules Audit: Write unit tests for rules
- [ ] Feature-Flag System: Use flutter_dotenv + remote_config for experimental features
- [ ] Storybook Setup: Add Widgetbook and React Storybook with CI previews

---

## 🧩 CODE TODOs (from lib/ directory, as of 2025-06-14)

### 🏷️ i18n & Localization
- [ ] [dialog_helper.dart:2] Uncomment when gen_l10n is properly set up
- [ ] [dialog_helper.dart:17] Use AppLocalizations when properly set up
- [ ] [dialog_helper.dart:186] Use AppLocalizations when properly set up
- [ ] [polished_settings_screen.dart:87,102,113,170,178,186,194,202,210,220,284] Localize all settings titles and toggles
- [ ] [refactored_settings_screen.dart:50,63] Localize app bar title and tooltip
- [ ] [enhanced_settings_screen.dart:56,62,73,128,135,145,155,165,173,178,182,219,227,238,249,260,275,286,296] Localize all enhanced settings labels and content
- [ ] [settings/navigation_section.dart:36,44,47,59,62,74,110,148,163,179] Localize navigation section titles, subtitles, semantic labels, and feedback messages
- [ ] [settings/app_settings_section.dart:25,34,43,52] Localize app settings section titles and subtitles
- [ ] [settings/premium_section.dart:20] Localize premium section title and subtitle
- [ ] [settings/account_section.dart:20,38,64,75,104,106,107,128,142] Localize account section headers, titles, subtitles, error/success messages
- [ ] [settings/developer_section.dart:60,80,136,143,231,248,281,321,329,344,352,369,377] Localize developer section titles, subtitles, feedback, dialog content, error/success messages
- [ ] [recycling_code_info.dart:132,142,154,188,263] Localize recycling code info labels, names, examples, semantics, and SnackBar content

### 💸 Ads & Monetization
- [ ] [ad_service.dart:12] ADMOB CONFIGURATION REQUIRED
- [ ] [ad_service.dart:23,29,34] Replace with your actual ad unit IDs from AdMob console (banner, interstitial, reward ads)
- [ ] [ad_service.dart:102] Verify AdMob App ID is correctly configured in platform files
- [ ] [ad_service.dart:110] Add consent management for GDPR compliance
- [ ] [ad_service.dart:127] Implement proper error tracking/analytics
- [ ] [ad_service.dart:436] Implement reward ad functionality

### 📱 Feature Implementation
- [ ] [family_invite_screen.dart:564] Implement share via messages
- [ ] [family_invite_screen.dart:571] Implement share via email
- [ ] [family_invite_screen.dart:578] Implement generic share
- [ ] [theme_settings_screen.dart:141] Navigate to premium features screen
- [ ] [contribution_submission_screen.dart:835] Implement photo upload functionality
- [ ] [contribution_submission_screen.dart:847] Get userId from auth provider
- [ ] [settings/developer_section.dart:141,316,317,341] Check correct method names for premiumService, storageService, analyticsService, cleanupService
- [ ] [settings/developer_section.dart:365] Implement classification migration logic
- [ ] [settings/legal_support_section.dart:155] Implement email support functionality
- [ ] [settings/legal_support_section.dart:163] Implement bug reporting functionality
- [ ] [settings/legal_support_section.dart:171] Implement app rating functionality

### 🖼️ UI/UX & Animations
- [ ] [animations/data_visualization_animations.dart:22] Replace with dashboard-specific animation
- [ ] [animations/data_visualization_animations.dart:36] Implement progress tracking animation

---

*All code TODOs above are appended to the consolidated list as of 2025-06-14. For full context, see the referenced files and lines.*

*This file is auto-generated from all markdown TODOs and task lists as of 2025-06-14. For full context and implementation details, refer to the linked documents and planning files.* 