import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed unused imports: hive_flutter, path_provider, connectivity_plus, package_info_plus

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
import 'services/ad_service.dart';
import 'services/user_consent_service.dart';
import 'services/navigation_settings_service.dart';
import 'services/haptic_settings_service.dart';
import 'services/community_service.dart';
import 'services/dynamic_link_service.dart';
import 'services/cache_service.dart';
import 'services/local_guidelines_plugin.dart';
import 'screens/auth_screen.dart';
import 'screens/consent_dialog_screen.dart';
import 'screens/settings_screen.dart';
import 'l10n/app_localizations.dart';
import 'screens/history_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/educational_content_screen.dart';
import 'screens/waste_dashboard_screen.dart';
import 'screens/premium_features_screen.dart';
import 'screens/data_export_screen.dart';
import 'screens/offline_mode_settings_screen.dart';
import 'screens/disposal_facilities_screen.dart';
import 'widgets/global_menu_wrapper.dart';
import 'widgets/navigation_wrapper.dart';
import 'utils/constants.dart'; // For app constants, themes, and strings
import 'utils/error_handler.dart'; // Correct import for ErrorHandler
import 'utils/developer_config.dart'; // For developer-only features security
import 'utils/waste_app_logger.dart';
import 'utils/analytics_route_observer.dart';
import 'utils/frame_performance_monitor.dart';
import 'providers/theme_provider.dart';
import 'providers/points_engine_provider.dart';
import 'services/cloud_storage_service.dart';
import 'providers/app_providers.dart'; // Import central providers
// Removed unused imports: points_manager, points_engine, new_modern_home_screen, routes

// Global Navigator Key for Error Handling
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/*
Required packages:
  provider: ^6.1.1
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  http: ^1.1.0
  google_sign_in: ^6.1.6
  googleapis: ^12.0.0
  share_plus: ^7.2.1
  firebase_core: ^latest_version
  firebase_auth: ^latest_version
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize structured logging
  await WasteAppLogger.initialize();
  WasteAppLogger.info('App startup initiated');

  // Set up error handling
  _setupErrorHandling();

  // Environment variables are now loaded via --dart-define-from-file=.env
  if (kDebugMode) {
    WasteAppLogger.info('Environment variables loaded via --dart-define-from-file');
  }

  if (!kIsWeb) {
    if (kDebugMode) {
      WasteAppLogger.info('Before setPreferredOrientations');
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (kDebugMode) {
      WasteAppLogger.info('After setPreferredOrientations');
    }
  }

  if (kDebugMode) {
    WasteAppLogger.info('Before Firebase.initializeApp');
  }
  try {
    // Initialize Firebase with better error handling for web
    if (kIsWeb) {
      // Web-specific initialization with error handling
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Add web-specific Firestore settings to prevent internal assertion failures
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();

      // Set web-specific settings to prevent connection issues
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      WasteAppLogger.info('Firebase initialized for web with enhanced error handling');
    } else {
      // Mobile initialization
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      WasteAppLogger.info('Firebase initialized for mobile');
    }

    // Test Firestore connection and enable API if needed
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      if (kDebugMode) {
        WasteAppLogger.info('Firestore network enabled successfully');
      }

      // Test basic Firestore operation
      await firestore.collection('test').limit(1).get();
      if (kDebugMode) {
        WasteAppLogger.info('Firestore API is accessible');
      }
    } catch (firestoreError) {
      if (kDebugMode) {
        WasteAppLogger.severe('Firestore API error: $firestoreError');
        WasteAppLogger.info(
            'Please enable Firestore API at: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=waste-segregation-app-df523');
      }
      // Continue without Firestore - app can still function
    }

    // Crashlytics is ready for error reporting
  } catch (e, s) {
    WasteAppLogger.severe('Firebase initialization failed', e, s);
    // Continue with app initialization even if Firebase fails
    if (kDebugMode) {
      WasteAppLogger.severe('Firebase initialization error', e);
    }
  }

  Trace? startupTrace;
  try {
    startupTrace = FirebasePerformance.instance.newTrace('app_startup');
    await startupTrace.start();
  } catch (e) {
    WasteAppLogger.severe('Failed to start performance trace: $e');
  }

  if (kDebugMode) {
    WasteAppLogger.info('Before StorageService.initializeHive');
  }
  await StorageService.initializeHive();
  if (kDebugMode) {
    WasteAppLogger.info('After StorageService.initializeHive');
  }

  // Initialize cache feature flags
  await CacheFeatureFlags.initialize();
  if (kDebugMode) {
    WasteAppLogger.info('Cache feature flags initialized');
  }

  // Initialize Error Handler
  ErrorHandler.initialize(navigatorKey);

  // Validate developer config security (must be called early)
  DeveloperConfig.validateSecurity();

  // Create enhanced storage service instance
  final storageService = EnhancedStorageService();

  // Run migration tasks with error handling (skip on web)
  if (!kIsWeb) {
    try {
      // Run image path migration
      await storageService.migrateImagePathsToRelative();

      // Migrate existing classifications to generate missing thumbnails
      await storageService.migrateThumbnails();
    } catch (e) {
      WasteAppLogger.severe('Migration error (non-critical): $e');
      // Continue with app initialization even if migrations fail
    }
  } else {
    WasteAppLogger.info('⏭️ Skipping migrations on web platform');
  }

  final aiService = AiService();
  final analyticsService = AnalyticsService(storageService);
  final educationalContentAnalyticsService = EducationalContentAnalyticsService();

  // Initialize frame performance monitoring
  FramePerformanceMonitor.initialize(analyticsService);
  if (kDebugMode) {
    FramePerformanceMonitor.startMonitoring();
    WasteAppLogger.info('Frame performance monitoring started for debug builds');
  }
  final educationalContentService = EducationalContentService(educationalContentAnalyticsService);
  final gamificationService = GamificationService(storageService, CloudStorageService(storageService));
  final premiumService = PremiumService();
  final adService = AdService();
  final googleDriveService = GoogleDriveService(storageService);
  final navigationSettingsService = NavigationSettingsService();
  final hapticSettingsService = HapticSettingsService();
  final communityService = CommunityService();

  // Initialize Enhanced AI Analysis v2.0 - Local Guidelines Plugin System
  LocalGuidelinesManager.initializeDefaultPlugins();
  WasteAppLogger.info('Local guidelines plugins initialized (Enhanced AI Analysis v2.0)');

  try {
    if (kDebugMode) {
      WasteAppLogger.info('Before service initializations');
    }
    // Check persistent fresh install flag before any sync/service init
    final prefs = await SharedPreferences.getInstance();
    final justDidFreshInstall = prefs.getBool('justDidFreshInstall') ?? false;
    if (justDidFreshInstall) {
      WasteAppLogger.info('🚫 SKIPPING automatic service initialization due to fresh install (persistent flag).');
      await prefs.setBool('justDidFreshInstall', false); // Reset for next launch
    } else {
      if (kIsWeb) {
        // Initialize only web-compatible services
        WasteAppLogger.info('🌐 Initializing web-compatible services only');
        try {
          await gamificationService.initGamification();
          WasteAppLogger.info('✅ Gamification service initialized');
        } catch (e) {
          WasteAppLogger.severe('❌ Gamification service failed: $e');
        }

        try {
          await premiumService.initialize();
          WasteAppLogger.info('✅ Premium service initialized');
        } catch (e) {
          WasteAppLogger.severe('❌ Premium service failed: $e');
        }
      } else {
        // Initialize all services on mobile
        await Future.wait([
          gamificationService.initGamification(),
          premiumService.initialize(),
          adService.initialize(),
          communityService.initCommunity(),
        ]);
      }
    }
    if (kDebugMode) {
      WasteAppLogger.info('After service initializations');
    }

    if (kDebugMode) {
      WasteAppLogger.info('Before runApp');
    }
    runApp(WasteSegregationApp(
      storageService: storageService,
      aiService: aiService,
      analyticsService: analyticsService,
      educationalContentAnalyticsService: educationalContentAnalyticsService,
      educationalContentService: educationalContentService,
      gamificationService: gamificationService,
      premiumService: premiumService,
      adService: adService,
      googleDriveService: googleDriveService,
      navigationSettingsService: navigationSettingsService,
      hapticSettingsService: hapticSettingsService,
      communityService: communityService,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentState?.context;
      if (context != null) {
        DynamicLinkService.initDynamicLinks(context);
      }
    });
    if (kDebugMode) {
      WasteAppLogger.info('After runApp');
    }
  } finally {
    if (startupTrace != null) {
      try {
        await startupTrace.stop();
      } catch (e) {
        WasteAppLogger.severe('Failed to stop performance trace: $e');
      }
    }
  }
}

void _setupErrorHandling() {
  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
      WasteAppLogger.severe('🚨 Flutter Error Captured: ${details.exception}');
      WasteAppLogger.info('📍 Stack: ${details.stack}');
    }

    // Send to Crashlytics in release mode
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Capture errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      WasteAppLogger.severe('🚨 Platform Error Captured: $error');
      WasteAppLogger.info('📍 Stack: $stack');
    }

    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
}

class WasteSegregationApp extends StatelessWidget {
  const WasteSegregationApp({
    super.key,
    required this.storageService,
    required this.aiService,
    required this.analyticsService,
    required this.educationalContentAnalyticsService,
    required this.educationalContentService,
    required this.gamificationService,
    required this.premiumService,
    required this.adService,
    required this.googleDriveService,
    required this.navigationSettingsService,
    required this.hapticSettingsService,
    required this.communityService,
  });
  final StorageService storageService;
  final AiService aiService;
  final AnalyticsService analyticsService;
  final EducationalContentAnalyticsService educationalContentAnalyticsService;
  final EducationalContentService educationalContentService;
  final GamificationService gamificationService;
  final PremiumService premiumService;
  final AdService adService;
  final GoogleDriveService googleDriveService;
  final NavigationSettingsService navigationSettingsService;
  final HapticSettingsService hapticSettingsService;
  final CommunityService communityService;

  @override
  Widget build(BuildContext context) {
    return riverpod.ProviderScope(
      overrides: [
        // Override service providers for dependency injection
        storageServiceProvider.overrideWithValue(storageService),
        cloudStorageServiceProvider.overrideWith((ref) => CloudStorageService(storageService)),
      ],
      child: MultiProvider(
        providers: [
          // ThemeProvider for dynamic theming
          ChangeNotifierProvider(create: (_) => ThemeProvider()),

          // Provide existing service instances
          Provider<StorageService>.value(value: storageService),
          Provider<AiService>.value(value: aiService),
          ChangeNotifierProvider<AnalyticsService>.value(value: analyticsService),
          ChangeNotifierProvider<EducationalContentAnalyticsService>.value(value: educationalContentAnalyticsService),
          Provider<GoogleDriveService>.value(value: googleDriveService),
          Provider<EducationalContentService>.value(value: educationalContentService),
          ChangeNotifierProvider<GamificationService>.value(value: gamificationService),
          ChangeNotifierProvider<PremiumService>.value(value: premiumService),
          ChangeNotifierProvider<AdService>.value(value: adService),
          ChangeNotifierProvider<NavigationSettingsService>.value(value: navigationSettingsService),
          ChangeNotifierProvider<HapticSettingsService>.value(value: hapticSettingsService),
          Provider<CommunityService>.value(value: communityService),

          // Other providers
          Provider(create: (_) => UserConsentService()),
          Provider(create: (context) => CloudStorageService(context.read<StorageService>())),

          // Points Engine Provider - Single source of truth for points
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
                final lightScheme = lightDynamic ?? ColorScheme.fromSeed(seedColor: AppTheme.seedColor);
                final darkScheme =
                    darkDynamic ?? ColorScheme.fromSeed(seedColor: AppTheme.seedColor, brightness: Brightness.dark);
                return MaterialApp(
                  navigatorKey: navigatorKey,
                  title: AppStrings.appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.fromScheme(lightScheme),
                  darkTheme: AppTheme.fromScheme(darkScheme),
                  highContrastTheme: AppTheme.highContrastTheme,
                  highContrastDarkTheme: AppTheme.highContrastDarkTheme,
                  themeMode: themeProvider.themeMode,
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  // Add RouteObserver for automatic analytics tracking
                  navigatorObservers: [
                    analyticsRouteObserver,
                  ],
                  builder: (context, child) {
                    final mediaQuery = MediaQuery.of(context);
                    final currentScale = mediaQuery.textScaler.scale(1.0);
                    final clampedScale = currentScale.clamp(1.0, 2.0);
                    return MediaQuery(
                      data: mediaQuery.copyWith(textScaler: TextScaler.linear(clampedScale)),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },

                  // ADD ROUTE DEFINITIONS:
                  routes: {
                    '/home': (context) => const GlobalMenuWrapper(child: MainNavigationWrapper()),
                    '/settings': (context) => const GlobalMenuWrapper(child: SettingsScreen()),
                    '/history': (context) => const GlobalMenuWrapper(child: HistoryScreen()),
                    '/achievements': (context) => const GlobalMenuWrapper(child: AchievementsScreen()),
                    '/educational': (context) => const GlobalMenuWrapper(child: EducationalContentScreen()),
                    '/analytics': (context) => const GlobalMenuWrapper(child: WasteDashboardScreen()),
                    '/premium': (context) => const GlobalMenuWrapper(child: PremiumFeaturesScreen()),
                    '/premium-features': (context) => const GlobalMenuWrapper(child: PremiumFeaturesScreen()),
                    '/premium_features': (context) => const GlobalMenuWrapper(child: PremiumFeaturesScreen()),
                    '/data-export': (context) => const GlobalMenuWrapper(child: DataExportScreen()),
                    '/offline-settings': (context) => const GlobalMenuWrapper(child: OfflineModeSettingsScreen()),
                    '/disposal-facilities': (context) => const GlobalMenuWrapper(child: DisposalFacilitiesScreen()),
                  },
                  home: FutureBuilder<Map<String, bool>>(
                    future: _checkInitialConditions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _SplashScreen();
                      }

                      final conditions = snapshot.data ??
                          {
                            'hasConsent': false,
                          };

                      final hasConsent = conditions['hasConsent'] ?? false;

                      // First, check if user has accepted privacy policy and terms
                      if (!hasConsent) {
                        return ConsentDialogScreen(
                          onConsent: () {
                            // After consent, navigate to auth screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()),
                            );
                          },
                          onDecline: () {
                            // If user declines, exit the app
                            SystemNavigator.pop();
                          },
                        );
                      }

                      // Then check login status
                      return const AuthScreen(); // Will automatically redirect to HomeScreen if logged in
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, bool>> _checkInitialConditions() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Check user consent status with timeout for web compatibility
      final userConsentService = UserConsentService();
      final hasConsent = await userConsentService.hasAllRequiredConsents().timeout(const Duration(seconds: 3));

      return {
        'hasConsent': hasConsent,
      };
    } catch (e) {
      // If consent check fails (e.g., on web), assume no consent
      // This allows the app to continue and show the consent dialog
      return {
        'hasConsent': false,
      };
    }
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Text fade animation
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Text slide animation
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withValues(alpha: 0.8),
              AppTheme.secondaryColor,
              AppTheme.secondaryColor.withValues(alpha: 0.6),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Enhanced App logo with proper branding and animation
              AnimatedBuilder(
                animation: _logoScale,
                builder: (context, child) => Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Stack(
                        children: [
                          // Gradient background for the logo
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                          ),
                          // Main logo icon
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.recycling,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Eco leaves decoration
                          Positioned(
                            top: 15,
                            right: 15,
                            child: Icon(
                              Icons.eco,
                              size: 20,
                              color: Colors.green.shade600,
                            ),
                          ),
                          Positioned(
                            bottom: 15,
                            left: 15,
                            child: Icon(
                              Icons.science,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Enhanced App name with animation
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(
                    children: [
                      // Main app name
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.paddingSmall),

                      // Enhanced tagline with gradient text effect
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white70,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'AI-Powered Waste Classification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black12,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppTheme.paddingSmall),

                      // Community tagline
                      Text(
                        'Join the Eco-Warriors Community',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingExtraLarge),

              // Enhanced loading indicator with pulsing animation
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingRegular),
                    Text(
                      'Initializing...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
