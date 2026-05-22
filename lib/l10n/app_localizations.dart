import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn')
  ];

  /// Title for the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Header for account management section
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// Button text to sign out
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Button text to switch to Google account
  ///
  /// In en, this message translates to:
  /// **'Switch to Google Account'**
  String get switchToGoogle;

  /// Subtitle for sign out option
  ///
  /// In en, this message translates to:
  /// **'Sign out and return to login screen'**
  String get signOutSubtitle;

  /// Subtitle when in guest mode
  ///
  /// In en, this message translates to:
  /// **'Currently in guest mode - sign in to sync data'**
  String get guestModeSubtitle;

  /// Title for sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// Confirmation text when signing out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out? Your data will remain on this device, but you won\'t be able to sync with the cloud.'**
  String get signOutConfirmBody;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Header for premium features section
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumSection;

  /// Premium features menu item
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// Subtitle for premium features
  ///
  /// In en, this message translates to:
  /// **'Unlock advanced features'**
  String get premiumFeaturesSubtitle;

  /// Header for app settings section
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsSection;

  /// Theme settings menu item
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// Subtitle for theme settings
  ///
  /// In en, this message translates to:
  /// **'Customize app appearance'**
  String get themeSettingsSubtitle;

  /// Notification settings menu item
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Subtitle for notification settings
  ///
  /// In en, this message translates to:
  /// **'Manage notifications and alerts'**
  String get notificationSettingsSubtitle;

  /// Offline mode menu item
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Subtitle for offline mode
  ///
  /// In en, this message translates to:
  /// **'Configure offline functionality'**
  String get offlineModeSubtitle;

  /// Data export menu item
  ///
  /// In en, this message translates to:
  /// **'Data Export'**
  String get dataExport;

  /// Subtitle for data export
  ///
  /// In en, this message translates to:
  /// **'Export your data and history'**
  String get dataExportSubtitle;

  /// Haptic feedback setting title
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// Haptic feedback setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Vibrate on successful scan'**
  String get hapticFeedbackSubtitle;

  /// Header for navigation settings section
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigationSection;

  /// Navigation settings menu item
  ///
  /// In en, this message translates to:
  /// **'Navigation Settings'**
  String get navigationSettings;

  /// Subtitle for navigation settings
  ///
  /// In en, this message translates to:
  /// **'Customize navigation behavior'**
  String get navigationSettingsSubtitle;

  /// Bottom navigation toggle
  ///
  /// In en, this message translates to:
  /// **'Bottom Navigation'**
  String get bottomNavigation;

  /// Subtitle for bottom navigation toggle
  ///
  /// In en, this message translates to:
  /// **'Show bottom navigation bar'**
  String get bottomNavigationSubtitle;

  /// Camera button toggle
  ///
  /// In en, this message translates to:
  /// **'Camera Button (FAB)'**
  String get cameraButton;

  /// Subtitle for camera button toggle
  ///
  /// In en, this message translates to:
  /// **'Show floating camera button'**
  String get cameraButtonSubtitle;

  /// Navigation style setting
  ///
  /// In en, this message translates to:
  /// **'Navigation Style'**
  String get navigationStyle;

  /// Current navigation style display
  ///
  /// In en, this message translates to:
  /// **'Current: {style}'**
  String navigationStyleCurrent(String style);

  /// Navigation styles demo
  ///
  /// In en, this message translates to:
  /// **'Navigation Styles'**
  String get navigationStyles;

  /// Subtitle for navigation styles demo
  ///
  /// In en, this message translates to:
  /// **'Try different navigation designs'**
  String get navigationStylesSubtitle;

  /// Title for the training review queue
  ///
  /// In en, this message translates to:
  /// **'Training Review Queue'**
  String get trainingReviewQueue;

  /// Subtitle for the training review queue
  ///
  /// In en, this message translates to:
  /// **'Review pending training samples and labels'**
  String get trainingReviewQueueSubtitle;

  /// Header for features section
  ///
  /// In en, this message translates to:
  /// **'Features & Tools'**
  String get featuresSection;

  /// Modern UI components showcase
  ///
  /// In en, this message translates to:
  /// **'Modern UI Components'**
  String get modernUIComponents;

  /// Subtitle for modern UI components
  ///
  /// In en, this message translates to:
  /// **'Showcase of new design elements'**
  String get modernUIComponentsSubtitle;

  /// Subtitle for offline mode feature
  ///
  /// In en, this message translates to:
  /// **'Classify items without internet'**
  String get offlineModeClassify;

  /// Analytics menu item
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Subtitle for analytics
  ///
  /// In en, this message translates to:
  /// **'View your waste classification insights'**
  String get analyticsSubtitle;

  /// Advanced analytics menu item
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalytics;

  /// Subtitle for advanced analytics
  ///
  /// In en, this message translates to:
  /// **'Detailed insights and trends'**
  String get advancedAnalyticsSubtitle;

  /// Premium segmentation toggle title
  ///
  /// In en, this message translates to:
  /// **'Advanced Segmentation'**
  String get advancedSegmentation;

  /// Premium segmentation toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Identify multiple objects in a single image'**
  String get advancedSegmentationSubtitle;

  /// SnackBar text for offline mode settings coming soon
  ///
  /// In en, this message translates to:
  /// **'Offline mode settings coming soon!'**
  String get offlineModeComingSoon;

  /// Header for legal and support section
  ///
  /// In en, this message translates to:
  /// **'Legal & Support'**
  String get legalSupportSection;

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Subtitle for privacy policy
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacyPolicySubtitle;

  /// Terms of service menu item
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Subtitle for terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get termsOfServiceSubtitle;

  /// Help and support menu item
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Subtitle for help and support
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get helpSupportSubtitle;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Subtitle for about
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get aboutSubtitle;

  /// Contact support option
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// Subtitle for contact support
  ///
  /// In en, this message translates to:
  /// **'Send us an email'**
  String get contactSupportSubtitle;

  /// Report bug option
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// Subtitle for report bug
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app'**
  String get reportBugSubtitle;

  /// Rate app option
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateApp;

  /// Subtitle for rate app
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get rateAppSubtitle;

  /// Developer options header
  ///
  /// In en, this message translates to:
  /// **'DEVELOPER OPTIONS'**
  String get developerOptions;

  /// Developer mode tile title
  ///
  /// In en, this message translates to:
  /// **'Debug Mode'**
  String get debugMode;

  /// Developer mode tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Enable debug logging'**
  String get debugModeSubtitle;

  /// Performance monitor tile title
  ///
  /// In en, this message translates to:
  /// **'Performance Monitor'**
  String get performanceMonitor;

  /// Performance monitor tile subtitle
  ///
  /// In en, this message translates to:
  /// **'View performance metrics'**
  String get performanceMonitorSubtitle;

  /// Reset app data tile title
  ///
  /// In en, this message translates to:
  /// **'Reset App Data'**
  String get resetAppData;

  /// Reset app data tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Clear all app data'**
  String get resetAppDataSubtitle;

  /// Tooltip for developer mode toggle
  ///
  /// In en, this message translates to:
  /// **'Toggle Developer Mode'**
  String get toggleDeveloperMode;

  /// Subtitle for developer options
  ///
  /// In en, this message translates to:
  /// **'Toggle features for testing'**
  String get toggleFeaturesForTesting;

  /// Reset all button text
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// Factory reset dialog title
  ///
  /// In en, this message translates to:
  /// **'Factory Reset'**
  String get factoryReset;

  /// Factory reset confirmation text
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL app data including classifications, settings, and user preferences. This action cannot be undone.\\n\\nAre you sure you want to continue?'**
  String get factoryResetBody;

  /// Reset all data button text
  ///
  /// In en, this message translates to:
  /// **'Reset All Data'**
  String get resetAllData;

  /// Clear Firebase data dialog title
  ///
  /// In en, this message translates to:
  /// **'Clear Firebase Data'**
  String get clearFirebaseData;

  /// Clear Firebase data confirmation text
  ///
  /// In en, this message translates to:
  /// **'This will clear all Firebase data for testing purposes. This simulates a fresh install experience.\\n\\nContinue?'**
  String get clearFirebaseDataBody;

  /// Clear data button text
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get clearData;

  /// Developer toggle subtitle for a feature
  ///
  /// In en, this message translates to:
  /// **'Test mode: {feature}'**
  String testModeFeature(String feature);

  /// Developer feature toggle feedback message
  ///
  /// In en, this message translates to:
  /// **'{feature} {status} for testing'**
  String featureEnabledForTesting(String feature, String status);

  /// Support contact coming soon message
  ///
  /// In en, this message translates to:
  /// **'Support contact feature coming soon!'**
  String get supportContactComingSoon;

  /// Bug reporting coming soon message
  ///
  /// In en, this message translates to:
  /// **'Bug reporting feature coming soon!'**
  String get bugReportComingSoon;

  /// Rate app coming soon message
  ///
  /// In en, this message translates to:
  /// **'App rating feature coming soon!'**
  String get rateAppComingSoon;

  /// First line of the settings about dialog body
  ///
  /// In en, this message translates to:
  /// **'A comprehensive Flutter application for proper waste identification, segregation guidance, and environmental education.'**
  String get aboutDialogBodyLine1;

  /// Second line of the settings about dialog body
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter and powered by AI for accurate waste classification.'**
  String get aboutDialogBodyLine2;

  /// Application name used in About dialogs and settings surfaces
  ///
  /// In en, this message translates to:
  /// **'Waste Segregation App'**
  String get appName;

  /// Badge label for newly added settings items
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// Developer mode feedback message
  ///
  /// In en, this message translates to:
  /// **'Developer mode {status}'**
  String developerModeToggled(String status);

  /// Loading message while resetting app data
  ///
  /// In en, this message translates to:
  /// **'Resetting all data...'**
  String get resettingAllData;

  /// Error message when clearing app data fails
  ///
  /// In en, this message translates to:
  /// **'Data clearing failed: {error}'**
  String dataClearingFailed(String error);

  /// Migration success message
  ///
  /// In en, this message translates to:
  /// **'Migration completed: {updated} updated, {skipped} skipped, {errors} errors'**
  String migrationCompleted(int updated, int skipped, int errors);

  /// Migration failure message
  ///
  /// In en, this message translates to:
  /// **'Migration failed: {message}'**
  String migrationFailed(String message);

  /// Premium feature dialog title
  ///
  /// In en, this message translates to:
  /// **'{feature} - Premium Feature'**
  String premiumFeatureTitle(String feature);

  /// Premium feature dialog body
  ///
  /// In en, this message translates to:
  /// **'{feature} is a premium feature. Upgrade to unlock this and other advanced features.'**
  String premiumFeatureBody(String feature);

  /// Upgrade button text
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// Bottom navigation status message
  ///
  /// In en, this message translates to:
  /// **'Bottom navigation {status}'**
  String bottomNavEnabled(String status);

  /// Camera button status message
  ///
  /// In en, this message translates to:
  /// **'Camera button {status}'**
  String cameraButtonEnabled(String status);

  /// Navigation style change message
  ///
  /// In en, this message translates to:
  /// **'Navigation style changed to {style}'**
  String navigationStyleChanged(String style);

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get enabled;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabled;

  /// Success message for sign in
  ///
  /// In en, this message translates to:
  /// **'Successfully signed in to Google account'**
  String get successfullySignedIn;

  /// Error message for sign out failure
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String signOutFailed(String error);

  /// Semantic label for new feature badge
  ///
  /// In en, this message translates to:
  /// **'New feature'**
  String get newFeatureBadge;

  /// Semantic label for updated feature badge
  ///
  /// In en, this message translates to:
  /// **'Updated feature'**
  String get updatedFeatureBadge;

  /// Semantic label for premium feature badge
  ///
  /// In en, this message translates to:
  /// **'Premium feature'**
  String get premiumFeatureBadge;

  /// Semantic label for bottom navigation toggle
  ///
  /// In en, this message translates to:
  /// **'Toggle bottom navigation bar'**
  String get toggleBottomNavigation;

  /// Semantic label for floating camera button toggle
  ///
  /// In en, this message translates to:
  /// **'Toggle floating camera button'**
  String get toggleFloatingCameraButton;

  /// Semantic label for camera shutter button
  ///
  /// In en, this message translates to:
  /// **'Camera shutter'**
  String get cameraShutterLabel;

  /// Hint for camera shutter button
  ///
  /// In en, this message translates to:
  /// **'Takes a photo'**
  String get cameraShutterHint;

  /// Hint for the start classifying button
  ///
  /// In en, this message translates to:
  /// **'Opens the camera to classify waste'**
  String get startClassifyingHint;

  /// Semantic label for achievement confetti overlay
  ///
  /// In en, this message translates to:
  /// **'Reward confetti'**
  String get rewardConfettiLabel;

  /// Hint for achievement confetti overlay
  ///
  /// In en, this message translates to:
  /// **'Celebrates your achievement'**
  String get rewardConfettiHint;

  /// Message when all premium features are reset
  ///
  /// In en, this message translates to:
  /// **'All premium features reset'**
  String get allPremiumFeaturesReset;

  /// Remove ads feature name
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get removeAds;

  /// Theme customization feature name
  ///
  /// In en, this message translates to:
  /// **'Theme Customization'**
  String get themeCustomization;

  /// Advanced analytics feature name
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalyticsFeature;

  /// Export data feature name
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Force crash test button
  ///
  /// In en, this message translates to:
  /// **'Force Crash (Crashlytics Test)'**
  String get forceCrashTest;

  /// Reset full data button
  ///
  /// In en, this message translates to:
  /// **'Reset Full Data (Factory Reset)'**
  String get resetFullData;

  /// Clear Firebase data button
  ///
  /// In en, this message translates to:
  /// **'Clear Firebase Data (Fresh Install)'**
  String get clearFirebaseDataFresh;

  /// Migrate old classifications button
  ///
  /// In en, this message translates to:
  /// **'Migrate Old Classifications'**
  String get migrateOldClassifications;

  /// Glassmorphism navigation style
  ///
  /// In en, this message translates to:
  /// **'Glassmorphism'**
  String get glassmorphism;

  /// Material 3 navigation style
  ///
  /// In en, this message translates to:
  /// **'Material 3'**
  String get material3;

  /// Floating navigation style
  ///
  /// In en, this message translates to:
  /// **'Floating'**
  String get floating;

  /// Message when ads are disabled
  ///
  /// In en, this message translates to:
  /// **'Ads are disabled'**
  String get adsDisabled;

  /// Subtitle for ad settings
  ///
  /// In en, this message translates to:
  /// **'Manage ad preferences'**
  String get manageAdPreferences;

  /// Snackbar message when ads are disabled
  ///
  /// In en, this message translates to:
  /// **'Ads are currently disabled'**
  String get adsCurrentlyDisabled;

  /// Subtitle for export data option
  ///
  /// In en, this message translates to:
  /// **'Export your classification history'**
  String get exportDataSubtitle;

  /// Google cloud sync setting
  ///
  /// In en, this message translates to:
  /// **'Google Cloud Sync'**
  String get googleCloudSync;

  /// Feedback settings title
  ///
  /// In en, this message translates to:
  /// **'Feedback Settings'**
  String get feedbackSettings;

  /// Feedback settings subtitle
  ///
  /// In en, this message translates to:
  /// **'Control when you can provide feedback'**
  String get feedbackSettingsSubtitle;

  /// Allow feedback on recent history setting
  ///
  /// In en, this message translates to:
  /// **'Allow Feedback on Recent History'**
  String get allowFeedbackRecentHistory;

  /// Feedback timeframe setting
  ///
  /// In en, this message translates to:
  /// **'Feedback Timeframe'**
  String get feedbackTimeframe;

  /// Feedback timeframe description
  ///
  /// In en, this message translates to:
  /// **'Can provide feedback on items from last {days} days'**
  String feedbackTimeframeDays(int days);

  /// One day option
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get oneDay;

  /// Three days option
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get threeDays;

  /// Seven days option
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sevenDays;

  /// Fourteen days option
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get fourteenDays;

  /// Thirty days option
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get thirtyDays;

  /// Last cloud sync label
  ///
  /// In en, this message translates to:
  /// **'Last Cloud Sync'**
  String get lastCloudSync;

  /// Sync local data to cloud option
  ///
  /// In en, this message translates to:
  /// **'Sync Local Data to Cloud'**
  String get syncLocalDataToCloud;

  /// Sync local data subtitle
  ///
  /// In en, this message translates to:
  /// **'Upload existing local classifications to cloud'**
  String get syncLocalDataSubtitle;

  /// Force download from cloud option
  ///
  /// In en, this message translates to:
  /// **'Force Download from Cloud'**
  String get forceDownloadFromCloud;

  /// Force download subtitle
  ///
  /// In en, this message translates to:
  /// **'Download latest data from cloud'**
  String get forceDownloadSubtitle;

  /// Reset all app data subtitle
  ///
  /// In en, this message translates to:
  /// **'Reset all app data (history, settings, preferences)'**
  String get resetAllAppData;

  /// Message when all data is cleared
  ///
  /// In en, this message translates to:
  /// **'All data cleared successfully'**
  String get allDataClearedSuccessfully;

  /// Privacy policy and terms subtitle
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy and Terms of Service'**
  String get privacyPolicyAndTerms;

  /// About section subtitle
  ///
  /// In en, this message translates to:
  /// **'App information and credits'**
  String get appInformationAndCredits;

  /// Contact support subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help via email'**
  String get getHelpViaEmail;

  /// Report bug subtitle
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app'**
  String get helpUsImproveApp;

  /// Rate app subtitle
  ///
  /// In en, this message translates to:
  /// **'Rate us on the app store'**
  String get rateUsOnAppStore;

  /// Signing out progress message
  ///
  /// In en, this message translates to:
  /// **'Signing out...'**
  String get signingOut;

  /// Error signing out message
  ///
  /// In en, this message translates to:
  /// **'Error signing out: {error}'**
  String errorSigningOut(String error);

  /// Stay in guest mode button
  ///
  /// In en, this message translates to:
  /// **'Stay in Guest Mode'**
  String get stayInGuestMode;

  /// Sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Upgrade to use feature dialog title
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Use {feature}'**
  String upgradeToUse(String feature);

  /// Not now button
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// See premium features button
  ///
  /// In en, this message translates to:
  /// **'See Premium Features'**
  String get seePremiumFeatures;

  /// Error opening email message
  ///
  /// In en, this message translates to:
  /// **'Error opening email: {error}'**
  String errorOpeningEmail(String error);

  /// Unable to open app store message
  ///
  /// In en, this message translates to:
  /// **'Unable to open app store. Please search for \"Waste Segregation App\" in your app store.'**
  String get unableToOpenAppStore;

  /// Error opening app store message
  ///
  /// In en, this message translates to:
  /// **'Error opening app store: {error}'**
  String errorOpeningAppStore(String error);

  /// Email not available dialog title
  ///
  /// In en, this message translates to:
  /// **'Email Not Available'**
  String get emailNotAvailable;

  /// No email app found message
  ///
  /// In en, this message translates to:
  /// **'No email app found. Please send an email to:'**
  String get noEmailAppFound;

  /// Email address copied message
  ///
  /// In en, this message translates to:
  /// **'Email address copied to clipboard'**
  String get emailAddressCopied;

  /// Copy email button
  ///
  /// In en, this message translates to:
  /// **'Copy Email'**
  String get copyEmail;

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Feature status changed message
  ///
  /// In en, this message translates to:
  /// **'{title} {status}'**
  String featureStatusChanged(String title, String status);

  /// Factory reset warning message
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL app data including:\\n\\n• All classification history\\n• All gamification progress (points, streaks, achievements)\\n• All user preferences and settings\\n• All cached data\\n• All premium feature settings\\n\\nThis action cannot be undone.\\n\\nAre you sure you want to continue?'**
  String get factoryResetWarning;

  /// Resetting to factory settings message
  ///
  /// In en, this message translates to:
  /// **'Resetting app to factory settings...'**
  String get resettingToFactorySettings;

  /// Google sync disabled message
  ///
  /// In en, this message translates to:
  /// **'Google sync disabled. Future classifications will be saved locally only.'**
  String get googleSyncDisabled;

  /// Failed to toggle Google sync message
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle Google sync: {error}'**
  String failedToToggleGoogleSync(String error);

  /// Google sync enabled dialog title
  ///
  /// In en, this message translates to:
  /// **'Google Sync Enabled'**
  String get googleSyncEnabled;

  /// Google sync enabled message
  ///
  /// In en, this message translates to:
  /// **'Google sync is now enabled!'**
  String get googleSyncEnabledMessage;

  /// Header for the privacy and consent section
  ///
  /// In en, this message translates to:
  /// **'Privacy & Consent'**
  String get privacySection;

  /// Leaderboard opt-out toggle label
  ///
  /// In en, this message translates to:
  /// **'Hide from Leaderboard'**
  String get leaderboardOptOut;

  /// Subtitle when leaderboard opt-out is enabled
  ///
  /// In en, this message translates to:
  /// **'Your name and photo are hidden on the leaderboard'**
  String get leaderboardOptOutHide;

  /// Subtitle when leaderboard opt-out is disabled
  ///
  /// In en, this message translates to:
  /// **'Your name and photo are visible on the leaderboard'**
  String get leaderboardOptOutVisible;

  /// Snackbar message when user opts out of leaderboard
  ///
  /// In en, this message translates to:
  /// **'You are now hidden from the leaderboard'**
  String get leaderboardHidden;

  /// Snackbar message when user opts into leaderboard
  ///
  /// In en, this message translates to:
  /// **'You are now visible on the leaderboard'**
  String get leaderboardVisible;

  /// Error message when leaderboard privacy update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update leaderboard privacy: {error}'**
  String failedToUpdateLeaderboard(String error);

  /// Message when no user profile is found
  ///
  /// In en, this message translates to:
  /// **'No user profile found. Please sign in first.'**
  String get noUserProfileFound;

  /// Training consent toggle label
  ///
  /// In en, this message translates to:
  /// **'Improve model with my images'**
  String get trainingConsent;

  /// Subtitle when training consent is enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled. You can revoke anytime and request deletion of contributed training candidates.'**
  String get trainingConsentEnabled;

  /// Subtitle when training consent is disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled. No new image/correction enters training candidates.'**
  String get trainingConsentDisabled;

  /// Snackbar when training consent is granted
  ///
  /// In en, this message translates to:
  /// **'Training consent enabled.'**
  String get trainingConsentGranted;

  /// Snackbar when training consent is revoked
  ///
  /// In en, this message translates to:
  /// **'Training consent revoked and deletion requested.'**
  String get trainingConsentRevoked;

  /// Error message when training consent update fails
  ///
  /// In en, this message translates to:
  /// **'Could not update training consent: {error}'**
  String couldNotUpdateTrainingConsent(String error);

  /// Prompt when enabling sync to upload existing data
  ///
  /// In en, this message translates to:
  /// **'Would you like to upload your existing local classifications to the cloud?'**
  String get syncEnabledUploadPrompt;

  /// Info text about cloud sync availability
  ///
  /// In en, this message translates to:
  /// **'This will make them available across all your devices.'**
  String get syncAvailableAcrossDevices;

  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Upload now button text
  ///
  /// In en, this message translates to:
  /// **'Upload Now'**
  String get uploadNow;

  /// Loading message while syncing data to cloud
  ///
  /// In en, this message translates to:
  /// **'Syncing data to cloud...'**
  String get syncingDataToCloud;

  /// Message when classifications are synced to cloud
  ///
  /// In en, this message translates to:
  /// **'Successfully synced {count} classifications to cloud!'**
  String syncedToCloud(int count);

  /// Message when no classifications were synced
  ///
  /// In en, this message translates to:
  /// **'No classifications were synced.'**
  String get noClassificationsSynced;

  /// Error message when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailed(String error);

  /// Loading message while downloading from cloud
  ///
  /// In en, this message translates to:
  /// **'Downloading from cloud...'**
  String get downloadingFromCloud;

  /// Message when classifications are downloaded from cloud
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} classifications from cloud!'**
  String downloadedFromCloud(int count);

  /// Message when no classifications were downloaded
  ///
  /// In en, this message translates to:
  /// **'No classifications were downloaded.'**
  String get noClassificationsDownloaded;

  /// Error message when download fails
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// Subtitle when feedback on history is enabled
  ///
  /// In en, this message translates to:
  /// **'Can provide feedback on recent classifications from history'**
  String get feedbackOnHistoryEnabled;

  /// Subtitle when feedback on history is disabled
  ///
  /// In en, this message translates to:
  /// **'Can only provide feedback on new classifications'**
  String get feedbackOnHistoryDisabled;

  /// Explanation when feedback on history is enabled
  ///
  /// In en, this message translates to:
  /// **'Perfect for scanning multiple items quickly and providing feedback later when you have more time!'**
  String get feedbackExplanationEnabled;

  /// Explanation when feedback on history is disabled
  ///
  /// In en, this message translates to:
  /// **'Feedback is only available immediately after classification.'**
  String get feedbackExplanationDisabled;

  /// Subtitle when Google Cloud Sync is enabled
  ///
  /// In en, this message translates to:
  /// **'Classifications sync to cloud automatically'**
  String get syncClassificationsLocally;

  /// Subtitle when Google Cloud Sync is disabled
  ///
  /// In en, this message translates to:
  /// **'Classifications saved locally only'**
  String get syncClassificationsLocalOnly;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'kn': return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
