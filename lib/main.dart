import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        debugPaintBaselinesEnabled,
        debugPaintLayerBordersEnabled,
        debugPaintPointersEnabled,
        debugPaintSizeEnabled;
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/ai_service.dart';
import 'services/analytics_service.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/enhanced_storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/educational_content_analytics_service.dart';
import 'services/gamification_service.dart';
import 'services/premium_service.dart';
import 'services/purchase_service.dart';
import 'services/ad_service.dart';
import 'services/user_consent_service.dart';
import 'services/navigation_settings_service.dart';
import 'services/haptic_settings_service.dart';
import 'services/community_service.dart';
import 'services/dynamic_link_service.dart';
import 'services/cache_service.dart';
import 'services/firebase_backend_diagnostics_service.dart';
import 'utils/permission_handler.dart';
import 'services/local_guidelines_plugin.dart';
import 'services/hive_box_manager.dart';
import 'screens/auth_screen.dart';
import 'screens/consent_dialog_screen.dart';
import 'screens/data_export_screen.dart';
import 'screens/disposal_facilities_screen.dart';
import 'screens/impact_dashboard_screen.dart';
import 'screens/legal_document_screen.dart';
import 'screens/modern_ui_showcase_screen.dart';
import 'screens/navigation_demo_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/offline_mode_settings_screen.dart';
import 'screens/enhanced_settings_screen.dart';
import 'screens/premium_features_screen.dart';
import 'screens/training_review_queue_screen.dart';
import 'screens/theme_settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/educational_content_screen.dart';
import 'screens/waste_dashboard_screen.dart';
import 'screens/smart_suggestions_screen.dart';
import 'screens/token_wallet_screen.dart';
import 'screens/model_routing_screen.dart';
import 'screens/gamification_analytics_screen.dart';
import 'services/gamification_analytics_service.dart';
import 'utils/constants.dart';
import 'utils/routes.dart';
import 'utils/error_handler.dart';
import 'utils/developer_config.dart';
import 'utils/waste_app_logger.dart';
import 'utils/analytics_route_observer.dart';
import 'utils/frame_performance_monitor.dart';
import 'utils/firebase_gate.dart';
import 'providers/theme_provider.dart';
import 'providers/points_engine_provider.dart';
import 'services/cloud_storage_service.dart';
import 'providers/app_providers.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Default: show the real app flow even in debug. Enable the purple debug screen
// with: --dart-define=FORCE_DEBUG_HOME=true
const bool _forceDebugHome = bool.fromEnvironment('FORCE_DEBUG_HOME');
const String _appCheckWebRecaptchaSiteKey =
    String.fromEnvironment('APPCHECK_WEB_RECAPTCHA_SITE_KEY');

void _setPreferredOrientationsSafe() {
  if (kIsWeb) return;

  // On iOS simulators this call can hang; never block app boot on it.
  unawaited(
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).timeout(
      const Duration(seconds: 3),
      onTimeout: () => Future.value(),
    ),
  );
}

void main() {
  // Ensure Flutter is ready for interaction
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode && const bool.fromEnvironment('DEBUG_OVERFLOWS')) {
    debugPaintSizeEnabled = true;
    debugPaintBaselinesEnabled = true;
    debugPaintLayerBordersEnabled = true;
    debugPaintPointersEnabled = true;
  }

  // Run the Bootstrapper which handles the transition from splash to app
  runApp(const _AppBootstrapper());
}

/// A top-level widget that handles the asynchronous initialization of services
/// while showing a splash screen to the user.
class _AppBootstrapper extends StatefulWidget {
  const _AppBootstrapper();

  @override
  State<_AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<_AppBootstrapper> {
  bool _initialized = false;
  String? _error;
  UserConsentService? _userConsentService;
  bool? _lastReportedInitialized;
  bool _reportedErrorState = false;

  // Service instances
  late StorageService _storageService;
  late AiService _aiService;
  late AnalyticsService _analyticsService;
  late EducationalContentAnalyticsService _educationalContentAnalyticsService;
  late EducationalContentService _educationalContentService;
  late GamificationService _gamificationService;
  late PremiumService _premiumService;
  late PurchaseService _purchaseService;
  late AdService _adService;
  late GoogleDriveService _googleDriveService;
  late NavigationSettingsService _navigationSettingsService;
  late HapticSettingsService _hapticSettingsService;
  late CommunityService _communityService;
  final FirebaseBackendDiagnosticsService _backendDiagnosticsService =
      FirebaseBackendDiagnosticsService();

  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      if (mounted) {
        setState(() {
          _error = null;
          _initialized = false;
        });
      }

      if (!kIsWeb) {
        _setPreferredOrientationsSafe();
      }

      // 1. Core Logging & Error Handling
      await WasteAppLogger.initialize().timeout(const Duration(seconds: 3));
      _setupErrorHandling();
      WasteAppLogger.debug('BOOT: Logger initialized');
      unawaited(_backendDiagnosticsService.initialize());

      // Consent service should be ready early; if SharedPreferences hangs, we continue with a safe "false" default.
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
            'SharedPreferences.getInstance timed out (bootstrapper)',
          ),
        );
        _userConsentService = UserConsentService(prefs);
      } catch (e) {
        WasteAppLogger.warning(
          'BOOT: SharedPreferences unavailable during bootstrap; continuing with in-memory consent state.',
          error: e,
        );
        _userConsentService = UserConsentService();
      }

      // 2. Firebase (Conditional)
      final skipFirebaseInit = !isFirebaseEnabled;
      if (!skipFirebaseInit) {
        try {
          var alreadyInitialized = Firebase.apps.isNotEmpty;
          if (!alreadyInitialized) {
            // Some platforms auto-initialize the default app via native config.
            // `Firebase.apps` may still appear empty early, so probe `Firebase.app()`.
            try {
              Firebase.app();
              alreadyInitialized = true;
            } catch (_) {}
          }

          if (alreadyInitialized) {
            WasteAppLogger.debug('BOOT: Firebase already initialized');
          } else {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ).timeout(const Duration(seconds: 10));
            WasteAppLogger.debug('BOOT: Firebase initialized');
          }
        } catch (e) {
          // Some environments initialize the default app via native config before
          // Flutter calls initializeApp(). Treat duplicate-app as a no-op.
          if (e is FirebaseException && e.code == 'duplicate-app') {
            WasteAppLogger.debug('BOOT: Firebase already initialized (native)');
          } else {
            WasteAppLogger.severe('Firebase init failed', error: e);
          }
        }
      }

      if (!skipFirebaseInit) {
        await _runInitStep(
          'App Check',
          _initializeAppCheck,
          timeout: const Duration(seconds: 10),
        );
      }

      // 3. Storage & Database
      const skipHiveInit = bool.fromEnvironment('SKIP_HIVE');
      if (skipHiveInit) {
        throw StateError(
          'Hive initialization is disabled (SKIP_HIVE=true). Remove the define to run the full app.',
        );
      } else {
        await _runInitStep('Hive', () async {
          try {
            await StorageService.initializeHive();
          } catch (e, s) {
            final isNullIntCast = e.toString().contains(
                  "type 'Null' is not a subtype of type 'int'",
                );

            if (!isNullIntCast) rethrow;

            WasteAppLogger.warning(
              'BOOT: Hive null->int cast detected; attempting targeted Hive recovery',
              error: e,
              stackTrace: s,
            );

            final repairedBoxes =
                await StorageService.recoverFromNullIntHiveCast();

            WasteAppLogger.warning(
              'BOOT: Hive recovery completed, retrying initialization',
              context: {
                'repaired_boxes_count': repairedBoxes.length,
                'repaired_boxes': repairedBoxes,
              },
            );

            await StorageService.initializeHive();
          }

          await HiveBoxManager.instance.initialize();
          await CacheFeatureFlags.initialize();
        }, critical: true);
      }

      // 4. Critical UI Services
      ErrorHandler.initialize(navigatorKey);
      DeveloperConfig.validateSecurity();

      // Request App Tracking Transparency on iOS (non-blocking)
      try {
        // Import is in utils/permission_handler.dart
        unawaited(PermissionHandler.checkTrackingPermission());
      } catch (_) {}

      // 5. Instantiate Services
      final storageService = EnhancedStorageService();
      _storageService = storageService;

      // Migrations (Non-critical, but better done early)
      if (!kIsWeb) {
        await _runInitStep('Migrations', () async {
          await storageService.migrateImagePathsToRelative();
          await storageService.migrateThumbnails();
        });
      }

      _aiService = AiService();
      _analyticsService =
          AnalyticsService(storageService, enableFirestore: !skipFirebaseInit);
      _educationalContentAnalyticsService =
          EducationalContentAnalyticsService();

      FramePerformanceMonitor.initialize(_analyticsService);
      if (kDebugMode) FramePerformanceMonitor.startMonitoring();

      _educationalContentService =
          EducationalContentService(_educationalContentAnalyticsService);
      _gamificationService = GamificationService(
          storageService, CloudStorageService(storageService));
      _premiumService = PremiumService();
      _purchaseService = PurchaseService(_premiumService);
      _adService = AdService();
      _googleDriveService = GoogleDriveService(storageService);
      _navigationSettingsService = NavigationSettingsService();
      _hapticSettingsService = HapticSettingsService();
      _communityService = CommunityService();

      LocalGuidelinesManager.initializeDefaultPlugins();

      // Secondary initializations (can be async without blocking)
      unawaited(_premiumService
          .initialize()
          .catchError((e) => WasteAppLogger.severe('Premium init failed: $e')));
      unawaited(_purchaseService.initialize().catchError(
          (e) => WasteAppLogger.severe('Purchase init failed: $e')));
      unawaited(_adService
          .initialize()
          .catchError((e) => WasteAppLogger.severe('Ad init failed: $e')));

      WasteAppLogger.debug('BOOT: All services instantiated');

      WasteAppLogger.info(
        'BOOT: About to mark bootstrap initialized',
        context: {
          'mounted': mounted,
          'initialized_before': _initialized,
        },
      );

      if (mounted) {
        setState(() {
          _initialized = true;
        });

        WasteAppLogger.info(
          'BOOT: Bootstrap initialized flag set',
          context: {'initialized_after': _initialized},
        );
      }

      // Initialize dynamic links once the MaterialApp is mounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentState?.context;
        if (context != null) {
          DynamicLinkService.initDynamicLinks(context);
        }
      });
    } catch (e, s) {
      WasteAppLogger.severe('Fatal boot error', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _runInitStep(
    String label,
    Future<void> Function() action, {
    Duration timeout = const Duration(seconds: 15),
    bool critical = false,
  }) async {
    try {
      await action().timeout(timeout);
      WasteAppLogger.debug('BOOT: Step $label finished');
    } catch (e, s) {
      WasteAppLogger.severe('BOOT: Step $label failed',
          error: e, stackTrace: s);
      if (critical) rethrow;
    }
  }

  Future<void> _initializeAppCheck() async {
    if (!isFirebaseEnabled) {
      return;
    }

    if (kIsWeb) {
      if (_appCheckWebRecaptchaSiteKey.isEmpty) {
        if (kReleaseMode) {
          throw StateError(
            'APPCHECK_WEB_RECAPTCHA_SITE_KEY is required for web release builds.',
          );
        }
        WasteAppLogger.warning(
          'BOOT: App Check web site key missing; skipping App Check activation for this non-release build.',
        );
        return;
      }

      await FirebaseAppCheck.instance
          .activate(
            webProvider: ReCaptchaV3Provider(_appCheckWebRecaptchaSiteKey),
          )
          .timeout(const Duration(seconds: 10));
      WasteAppLogger.debug('BOOT: App Check activated for web');
      return;
    }

    if (kDebugMode) {
      await FirebaseAppCheck.instance
          .activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          )
          .timeout(const Duration(seconds: 10));
      WasteAppLogger.debug('BOOT: App Check activated in debug mode');
      return;
    }

    await FirebaseAppCheck.instance
        .activate(
          appleProvider: AppleProvider.appAttest,
          androidProvider: AndroidProvider.playIntegrity,
        )
        .timeout(const Duration(seconds: 10));
    WasteAppLogger.debug('BOOT: App Check activated for production modes');
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    _backendDiagnosticsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastReportedInitialized != _initialized) {
      _lastReportedInitialized = _initialized;
      WasteAppLogger.info(
        'BOOT_UI: bootstrap build state changed',
        context: {
          'initialized': _initialized,
          'has_error': _error != null,
        },
      );
    }

    if (_error != null) {
      if (!_reportedErrorState) {
        _reportedErrorState = true;
        WasteAppLogger.severe(
          'BOOT_UI: rendering initialization error screen',
          context: {'error': _error},
        );
      }
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Initialization Failed',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _startInitialization(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const _StartupApp();
    }

    return WasteSegregationApp(
      storageService: _storageService,
      aiService: _aiService,
      analyticsService: _analyticsService,
      educationalContentAnalyticsService: _educationalContentAnalyticsService,
      educationalContentService: _educationalContentService,
      gamificationService: _gamificationService,
      premiumService: _premiumService,
      purchaseService: _purchaseService,
      adService: _adService,
      googleDriveService: _googleDriveService,
      navigationSettingsService: _navigationSettingsService,
      hapticSettingsService: _hapticSettingsService,
      communityService: _communityService,
      userConsentService: _userConsentService ?? UserConsentService(),
    );
  }
}

class _StartupApp extends StatelessWidget {
  const _StartupApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReLoop',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2ECC71)),
      ),
      home: const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();
  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    _logoController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2ECC71), Color(0xFF00B4D8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10))
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.recycling,
                        size: 70, color: Color(0xFF2ECC71)),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class WasteSegregationApp extends StatefulWidget {
  const WasteSegregationApp({
    super.key,
    required this.storageService,
    required this.aiService,
    required this.analyticsService,
    required this.educationalContentAnalyticsService,
    required this.educationalContentService,
    required this.gamificationService,
    required this.premiumService,
    required this.purchaseService,
    required this.adService,
    required this.googleDriveService,
    required this.navigationSettingsService,
    required this.hapticSettingsService,
    required this.communityService,
    required this.userConsentService,
  });

  final StorageService storageService;
  final AiService aiService;
  final AnalyticsService analyticsService;
  final EducationalContentAnalyticsService educationalContentAnalyticsService;
  final EducationalContentService educationalContentService;
  final GamificationService gamificationService;
  final PremiumService premiumService;
  final PurchaseService purchaseService;
  final AdService adService;
  final GoogleDriveService googleDriveService;
  final NavigationSettingsService navigationSettingsService;
  final HapticSettingsService hapticSettingsService;
  final CommunityService communityService;
  final UserConsentService userConsentService;

  @override
  State<WasteSegregationApp> createState() => _WasteSegregationAppState();
}

class _WasteSegregationAppState extends State<WasteSegregationApp> {
  @override
  Widget build(BuildContext context) {
    WasteAppLogger.info(
      'APP_UI: WasteSegregationApp build entered',
      context: {'widget_hash': widget.hashCode},
    );

    return riverpod.ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(widget.storageService),
        cloudStorageServiceProvider
            .overrideWith((ref) => CloudStorageService(widget.storageService)),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<StorageService>.value(value: widget.storageService),
          Provider<AiService>.value(value: widget.aiService),
          ChangeNotifierProvider<AnalyticsService>.value(
              value: widget.analyticsService),
          ChangeNotifierProvider<EducationalContentAnalyticsService>.value(
              value: widget.educationalContentAnalyticsService),
          Provider<GoogleDriveService>.value(value: widget.googleDriveService),
          Provider<EducationalContentService>.value(
              value: widget.educationalContentService),
          ChangeNotifierProvider<GamificationService>.value(
              value: widget.gamificationService),
          ChangeNotifierProvider<PremiumService>.value(
              value: widget.premiumService),
          ChangeNotifierProvider<PurchaseService>.value(
              value: widget.purchaseService),
          ChangeNotifierProvider<AdService>.value(value: widget.adService),
          ChangeNotifierProvider<NavigationSettingsService>.value(
              value: widget.navigationSettingsService),
          ChangeNotifierProvider<HapticSettingsService>.value(
              value: widget.hapticSettingsService),
          Provider<CommunityService>.value(value: widget.communityService),
          Provider<UserConsentService>.value(value: widget.userConsentService),
          Provider(
              create: (context) =>
                  CloudStorageService(context.read<StorageService>())),
          ChangeNotifierProvider(
            create: (context) => PointsEngineProvider(
              context.read<StorageService>(),
              context.read<CloudStorageService>(),
            ),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final lightScheme = lightDynamic ??
                    ColorScheme.fromSeed(seedColor: AppTheme.seedColor);
                final darkScheme = darkDynamic ??
                    ColorScheme.fromSeed(
                        seedColor: AppTheme.seedColor,
                        brightness: Brightness.dark);

                return MaterialApp(
                  navigatorKey: navigatorKey,
                  title: AppStrings.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.fromScheme(lightScheme),
                  darkTheme: AppTheme.fromScheme(darkScheme),
                  highContrastTheme: AppTheme.highContrastTheme,
                  highContrastDarkTheme: AppTheme.highContrastDarkTheme,
                  themeMode: themeProvider.themeMode,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  navigatorObservers: [analyticsRouteObserver],
                  builder: (context, child) {
                    final mediaQuery = MediaQuery.of(context);
                    final currentScale = mediaQuery.textScaler.scale(1.0);
                    final clampedScale = currentScale.clamp(1.0, 2.0);
                    final childWidget = child ?? const SizedBox.shrink();
                    final mediaWrapped = MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(clampedScale),
                      ),
                      child: childWidget,
                    );

                    if (kDebugMode) {
                      // Debug overlay showing quick init statuses
                      const openAiKey =
                          String.fromEnvironment('OPENAI_API_KEY');
                      const geminiKey =
                          String.fromEnvironment('GEMINI_API_KEY');
                      final hasApiKeys =
                          openAiKey.isNotEmpty || geminiKey.isNotEmpty;

                      var hasConsent = false;
                      try {
                        final uc = Provider.of<UserConsentService>(
                          context,
                          listen: false,
                        );
                        hasConsent = uc.hasAllRequiredConsents;
                      } catch (_) {}

                      var firebaseOk = false;
                      try {
                        firebaseOk = Firebase.apps.isNotEmpty;
                      } catch (_) {}

                      var openHiveBoxes = 0;
                      try {
                        openHiveBoxes = HiveBoxManager.instance.openBoxCount;
                      } catch (_) {}

                      const showInitOverlay =
                          bool.fromEnvironment('SHOW_INIT_STATUS_OVERLAY');

                      if (showInitOverlay) {
                        return Stack(
                          children: [
                            mediaWrapped,
                            Positioned(
                              top: 40,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Init Status',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Firebase: ${firebaseOk ? '✓' : '✗'}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Hive boxes: $openHiveBoxes',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Consent: ${hasConsent ? '✓' : '✗'}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'API Keys: ${hasApiKeys ? '✓' : '✗'}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        );
                      }
                    }

                    return mediaWrapped;
                  },
                  routes: {
                    Routes.settings: (context) =>
                        const EnhancedSettingsScreen(),
                    Routes.auth: (context) => const AuthScreen(),
                    '/history': (context) => const HistoryScreen(),
                    '/achievements': (context) => const AchievementsScreen(),
                    '/educational': (context) =>
                        const EducationalContentScreen(),
                    Routes.wasteDashboard: (context) =>
                        const WasteDashboardScreen(),
                    Routes.premium: (context) => const PremiumFeaturesScreen(),
                    Routes.premiumFeatures: (context) =>
                        const PremiumFeaturesScreen(),
                    Routes.premiumFeaturesHyphen: (context) =>
                        const PremiumFeaturesScreen(),
                    '/token-wallet': (context) => const TokenWalletScreen(),
                    Routes.dataExport: (context) => const DataExportScreen(),
                    Routes.offlineModeSettings: (context) =>
                        const OfflineModeSettingsScreen(),
                    Routes.themeSettings: (context) =>
                        const ThemeSettingsScreen(),
                    Routes.notificationSettings: (context) =>
                        const NotificationSettingsScreen(),
                    Routes.navigationDemo: (context) =>
                        const NavigationDemoScreen(),
                    Routes.modernUIShowcase: (context) =>
                        const ModernUIShowcaseScreen(),
                    Routes.trainingReviewQueue: (context) =>
                        const TrainingReviewQueueScreen(),
                    Routes.modelRouting: (context) =>
                        const ModelRoutingScreen(),
                    Routes.gamificationAnalytics: (context) =>
                        GamificationAnalyticsScreen(
                          analyticsService: GamificationAnalyticsService(
                            analyticsService:
                                context.read<AnalyticsService>(),
                          ),
                        ),
                    '/disposal-facilities': (context) =>
                        const DisposalFacilitiesScreen(),
                    '/impact-dashboard': (context) =>
                        const ImpactDashboardScreen(),
                    '/smart-suggestions': (context) =>
                        const SmartSuggestionsScreen(),
                    Routes.privacyPolicy: (context) =>
                        const LegalDocumentScreen(
                          title: 'Privacy Policy',
                          assetPath: 'assets/docs/privacy_policy.md',
                        ),
                    Routes.termsOfService: (context) =>
                        const LegalDocumentScreen(
                          title: 'Terms of Service',
                          assetPath: 'assets/docs/terms_of_service.md',
                        ),
                  },
                  home: kDebugMode && _forceDebugHome
                      ? const _DebugHome()
                      : _buildInitialHome(context),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInitialHome(BuildContext context) {
    var hasConsent = false;
    try {
      hasConsent = widget.userConsentService.hasAllRequiredConsents;
      WasteAppLogger.info(
        'APP_UI: Initial home consent evaluated',
        context: {'has_consent': hasConsent},
      );
    } catch (e, s) {
      WasteAppLogger.warning(
        'Initial consent read failed; defaulting to consent dialog.',
        error: e,
        stackTrace: s,
      );
    }

    if (!hasConsent) {
      WasteAppLogger.info('APP_UI: Rendering ConsentDialogScreen');
      return ConsentDialogScreen(
        onConsent: () {
          final nav = navigatorKey.currentState;
          if (nav == null) {
            WasteAppLogger.warning(
              'Consent accepted but navigator was unavailable; staying on consent screen.',
            );
            return;
          }
          nav.pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        },
        onDecline: () => SystemNavigator.pop(),
      );
    }

    WasteAppLogger.info('APP_UI: Rendering AuthScreen');
    return const AuthScreen();
  }
}

class _DebugHome extends StatelessWidget {
  const _DebugHome();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('DEBUG HOME: UI OK',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => WasteAppLogger.debug('Debug button pressed'),
              child: const Text('Test Interaction'),
            ),
          ],
        ),
      ),
    );
  }
}

void _setupErrorHandling() {
  if (kDebugMode) {
    ErrorWidget.builder = (details) => Material(
          color: Colors.red,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                  'WIDGET ERROR:\n${details.exception}\n\n${details.stack}',
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        );
  }

  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      WasteAppLogger.severe('Platform Error', error: error, stackTrace: stack);
    }
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}
