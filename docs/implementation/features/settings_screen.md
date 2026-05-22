# Settings Screen Implementation

## Route Map

| Route | Screen | Final Decision |
|---|---|---|
| `/settings` | `EnhancedSettingsScreen` | **Canonical settings hub** |
| `/theme_settings` | `ThemeSettingsScreen` | Keep |
| `/notification_settings` | `NotificationSettingsScreen` | Keep |
| `/offline_mode_settings` | `OfflineModeSettingsScreen` | Keep (needs real model download) |
| `/data_export` | `DataExportScreen` | Keep (harden CSV) |
| `/navigation_demo` | `NavigationDemoScreen` | Developer/Demo only |
| `/modern_ui_showcase` | `ModernUIShowcaseScreen` | Developer/Demo only |
| `/premium_features` | `PremiumFeaturesScreen` | Keep |
| `/training_review_queue` | `TrainingReviewQueueScreen` | Developer only |
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
| Navigation | `NavigationSection` | `navigation_section.dart` | Bottom nav, FAB, style |
| Features & Tools | `FeaturesSection` | `features_section.dart` | Offline, analytics, advanced analytics, UI showcase |
| Legal & Support | `LegalSupportSection` | `legal_support_section.dart` | Privacy, terms, support, bug report, rate, about |
| Developer | `DeveloperSection` | `developer_section.dart` | Premium toggles, crash test, data clear, migration |

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
- Developer mode toggle via `DeveloperConfig.canShowDeveloperOptions`
- Training review queue accessible in developer mode

## Legacy Screen: SettingsScreen

- **Status**: Deprecated
- Held the original monolithic implementation
- Features have been migrated to modular sections
- Key migrations: privacy (PrivacySection), sync (SyncSection), feedback (FeedbackSection)
- Do not add new features here
- Tests should target EnhancedSettingsScreen

## Test Plan

### Canonical Screen Tests
- Smoke render with providers
- Section header visibility by text
- Developer section hidden by default

### Existing Widget Tests (21 tests)
- SettingTile, SettingToggleTile rendering
- SettingsSectionHeader, SettingsSectionSpacer rendering
- PremiumSection, AppSettingsSection, LegalSupportSection rendering
- Route navigation from settings sections
- Animated components

### Section-specific tests (needed)
- PrivacySection: leaderboard opt-out persistence, training consent grant/revoke
- SyncSection: Google sync toggle, upload/download, timestamp display
- FeedbackSettingsSection: allowHistoryFeedback persistence, timeframe persistence
- DeveloperSection: premium toggles call PremiumService
- LegalSupportSection: mailto attempted, fallback dialog, rate app

### Service tests (needed)
- NavigationSettingsService: reject invalid style, fallback to default
- HapticSettingsService: load/save, handle prefs failure

## Manual QA Checklist

- [ ] All sections render on /settings
- [ ] Account sign-out works with confirmation
- [ ] Developer mode shows/hides properly
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
