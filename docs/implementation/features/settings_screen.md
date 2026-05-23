# Settings Screen Implementation

## Route Map

| Route | Screen | Final Decision |
|---|---|---|
| `/settings` | `EnhancedSettingsScreen` | **Canonical settings hub** |
| `/theme_settings` | `ThemeSettingsScreen` | Keep |
| `/notification_settings` | `NotificationSettingsScreen` | Keep |
| `/offline_mode_settings` | `OfflineModeSettingsScreen` | Keep (needs real model download) |
| `/data_export` | `DataExportScreen` | Keep (harden CSV) |
| `/navigation_demo` | `NavigationDemoScreen` | **Developer only** — gated behind DeveloperSection + runtime toggle |
| `/modern_ui_showcase` | `ModernUIShowcaseScreen` | **Developer only** — gated behind DeveloperSection + runtime toggle |
| `/premium_features` | `PremiumFeaturesScreen` | Keep |
| `/training_review_queue` | `TrainingReviewQueueScreen` | **Developer only** — gated behind DeveloperSection + runtime toggle |
| `/privacy_policy` | `LegalDocumentScreen` | Keep |
| `/terms_of_service` | `LegalDocumentScreen` | Keep |
| (legacy) `settings_screen.dart` | `SettingsScreen` | **Deprecated** - source for migration only |

## Section Inventory (EnhancedSettingsScreen)

| Section | Widget | Source | Features |
|---|---|---|---|
| Account & Identity | `AccountSection` | `account_section.dart` | Sign in/out, reset data |
| Premium | `PremiumSection` | `premium_section.dart` | Premium features link |
| App Settings | `AppSettingsSection` | `app_settings_section.dart` | Theme, notifications, offline, export, haptics |
| Privacy & Consent | `PrivacySection` | `privacy_section.dart` | Leaderboard opt-out, training consent |
| Sync & Backup | `SyncSection` | `sync_section.dart` | Google Cloud Sync, upload/download |
| Feedback Settings | `FeedbackSettingsSection` | `feedback_settings_section.dart` | History feedback, timeframe |
| Navigation | `NavigationSection` | `navigation_section.dart` | Bottom nav, FAB, style dropdown |
| Features & Tools | `FeaturesSection` | `features_section.dart` | Offline mode, analytics, advanced analytics |
| Legal & Support | `LegalSupportSection` | `legal_support_section.dart` | Privacy, terms, support, bug report, rate, about |
| Developer | `DeveloperSection` | `developer_section.dart` | Premium toggles, dev tool tiles, crash test, data clear, migration |

### Developer Section Contents

The DeveloperSection is **double-gated**:
1. **Compile-time**: `DeveloperConfig.canShowDeveloperOptions` (only `true` in debug builds)
2. **Runtime toggle**: `_showDeveloperOptions` state in `EnhancedSettingsScreen`, toggled via developer icon in app bar

When both gates are open, the DeveloperSection exposes:

| Tile | Action |
|---|---|
| Premium Feature Toggles | `PremiumService.setPremiumFeature()` for `remove_ads`, `theme_customization`, `offline_mode`, `advanced_analytics`, `export_data` |
| Modern UI Components | Opens `Routes.modernUIShowcase` — component gallery for visual regression testing |
| Navigation Styles | Opens `Routes.navigationDemo` — interactive navigation style preview |
| Force Crash Test | Crashes app via `FirebaseCrashlytics.instance.crash()` (additionally gated by `canShowCrashTest`) |
| Clear Firebase Data | Full data cleanup via `FirebaseCleanupService` with confirmation dialog |
| Migrate Old Classifications | Runs `ClassificationMigrationService.migrateOldClassifications()` |

### Removed from Developer Section (cleanup)

The following inert tiles (empty `onTap` callbacks) were removed:
- Debug Mode
- Performance Monitor
- Reset App Data

## Services Used

| Service | Role |
|---|---|
| `StorageService` | Local Hive persistence for settings, user profile |
| `CloudStorageService` | Firestore sync, leaderboard privacy, cloud data management |
| `PremiumService` | Premium feature entitlements, test toggles |
| `GoogleDriveService` | Sign-in/sign-out state |
| `NavigationSettingsService` | SharedPreferences-backed nav style persistence |
| `HapticSettingsService` | SharedPreferences-backed haptic toggle |
| `AdService` | Settings context for ad state |
| `AnalyticsService` | Analytics data clearing |
| `TrainingDataService` | Training consent revocation and deletion request |
| `ClassificationMigrationService` | Old classification upgrade |
| `FirebaseCleanupService` | Full data cleanup for fresh install |

## Settings Keys

| Key | Service | Type | Default |
|---|---|---|---|
| `bottom_nav_enabled` | NavigationSettingsService | bool | true |
| `fab_enabled` | NavigationSettingsService | bool | false |
| `navigation_style` | NavigationSettingsService | String | `glassmorphism` |
| `haptic_success_enabled` | HapticSettingsService | bool | true |
| `isDarkMode` | StorageService | bool | false |
| `isGoogleSyncEnabled` | StorageService | bool | true |
| `allowHistoryFeedback` | StorageService | bool | true |
| `feedbackTimeframeDays` | StorageService | int | 7 |
| `leaderboardOptOut` | UserProfile.preferences | bool | false |
| `trainingConsent` | UserProfile.trainingConsent | TrainingConsent | disabled |

## Canonical Screen: EnhancedSettingsScreen

- Route target: `Routes.settings`
- Composes all modular sections
- Developer mode toggle via `DeveloperConfig.canShowDeveloperOptions` (app bar icon)
- `TrainingReviewQueue`, `NavigationDemo`, `ModernUIShowcase` are **developer-only** — exposed only in `DeveloperSection` under double gate
- No demo/component-gallery routes appear as normal user settings

## Legacy Screen: SettingsScreen

- **Status**: Deprecated
- Held the original monolithic implementation
- Features have been migrated to modular sections
- Key migrations: privacy (PrivacySection), sync (SyncSection), feedback (FeedbackSection)
- Do not add new features here
- Tests should target EnhancedSettingsScreen

## Gating: Production vs Developer Surfaces

### Production (always visible to all users)
- AccountSection, PremiumSection, AppSettingsSection, PrivacySection, SyncSection
- FeedbackSettingsSection, RegionSelectionSection, NavigationSection, FeaturesSection
- LegalSupportSection

### Developer-only (double-gated: compile-time `kDebugMode` + runtime toggle)
- `DeveloperSection` (premium toggles, dev tool tiles, crash test, data clear, migration)
- `TrainingReviewQueue` tile (in `EnhancedSettingsScreen._buildSections`)
- `NavigationDemoScreen` (via `DeveloperSection._buildDevToolTiles`)
- `ModernUIShowcaseScreen` (via `DeveloperSection._buildDevToolTiles`)

## Test Plan

### Canonical Screen Tests
- Smoke render with providers
- Section header visibility by text
- Developer section hidden by default
- Developer section visible when toggle is active (debug builds only)
- Modern UI and Navigation Demo tiles NOT visible in normal settings
- Modern UI and Navigation Demo tiles visible in DeveloperSection when enabled

### Existing Widget Tests
- SettingTile, SettingToggleTile rendering
- SettingsSectionHeader, SettingsSectionSpacer rendering
- PremiumSection, AppSettingsSection, LegalSupportSection rendering
- Route navigation from settings sections
- Animated components

### Section-specific tests (needed)
- PrivacySection: leaderboard opt-out persistence, training consent grant/revoke
- SyncSection: Google sync toggle, upload/download, timestamp display
- FeedbackSettingsSection: allowHistoryFeedback persistence, timeframe persistence
- DeveloperSection: premium toggles call PremiumService, dev tool tiles route correctly
- LegalSupportSection: mailto attempted, fallback dialog, rate app

### Service tests (needed)
- NavigationSettingsService: reject invalid style, fallback to default
- HapticSettingsService: load/save, handle prefs failure

## Manual QA Checklist

- [ ] All sections render on /settings
- [ ] Account sign-out works with confirmation
- [ ] Modern UI Components NOT visible in normal settings
- [ ] Navigation Styles demo NOT visible in normal settings
- [ ] Navigation Style dropdown in NavigationSection persists properly
- [ ] Developer mode shows/hides properly (debug builds only)
- [ ] Developer mode toggles Modern UI Showcase and Navigation Demo visibility
- [ ] Developer section has no inert/no-op tiles
- [ ] Privacy: leaderboard opt-out persists across app restart
- [ ] Privacy: training consent grant shows confirmation
- [ ] Privacy: training consent revocation requests deletion
- [ ] Sync: Google Cloud Sync toggle persists
- [ ] Sync: enabling sync shows upload prompt
- [ ] Sync: upload/download with loading states
- [ ] Sync: last sync timestamp updates
- [ ] Feedback: history feedback toggle persists
- [ ] Feedback: timeframe dropdown saves correctly
- [ ] Legal: privacy policy and terms open
- [ ] Legal: contact support opens mailto with correct info
- [ ] Legal: bug report opens mailto with template
- [ ] Legal: rate app opens store URL or fallback
- [ ] Legal: email fallback dialog with copy works
- [ ] Navigation: style persists and applies
- [ ] Developer: premium toggles actually enable features
- [ ] Developer: dangerous actions have confirmation