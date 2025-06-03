import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';
import 'services/ai_service.dart';
import 'services/analytics_service.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/enhanced_storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'services/user_consent_service.dart';
import 'services/navigation_settings_service.dart';
import 'services/community_service.dart';
import 'screens/auth_screen.dart';
import 'screens/consent_dialog_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/educational_content_screen.dart';
import 'screens/waste_dashboard_screen.dart';
import 'screens/premium_features_screen.dart';
import 'screens/data_export_screen.dart';
import 'screens/offline_mode_settings_screen.dart';
import 'screens/disposal_facilities_screen.dart';
import 'widgets/navigation_wrapper.dart';
import 'utils/constants.dart'; // For app constants, themes, and strings
import 'utils/error_handler.dart'; // Correct import for ErrorHandler
import 'providers/theme_provider.dart';
import 'services/cloud_storage_service.dart';

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
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up error handling
  _setupErrorHandling();

  if (kIsWeb) {
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('It works!')),
      ),
    ));
  } else {
    originalMain();
  }
}

Future<void> originalMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment variables are now loaded via --dart-define-from-file=.env
  if (kDebugMode) {
    debugPrint('Environment variables loaded via --dart-define-from-file');
  }

  if (!kIsWeb) {
    if (kDebugMode) {
      debugPrint('Before setPreferredOrientations');
    }
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (kDebugMode) {
      debugPrint('After setPreferredOrientations');
    }
  }

  if (kDebugMode) {
    debugPrint('Before Firebase.initializeApp');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('Firebase initialized successfully');
    }
    
    // Test Firestore connection and enable API if needed
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      if (kDebugMode) {
        debugPrint('Firestore network enabled successfully');
      }
      
      // Test basic Firestore operation
      await firestore.collection('test').limit(1).get();
      if (kDebugMode) {
        debugPrint('Firestore API is accessible');
      }
    } catch (firestoreError) {
      if (kDebugMode) {
        debugPrint('Firestore API error: $firestoreError');
        debugPrint('Please enable Firestore API at: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=waste-segregation-app-df523');
      }
      // Continue without Firestore - app can still function
    }
    
    // --- Crashlytics test: Remove after verification ---
    await FirebaseCrashlytics.instance.recordError(
      Exception('Test non-fatal error from Flutter!'),
      StackTrace.current,
      reason: 'Crashlytics integration test',
    );
    // --- End test ---
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to initialize Firebase: $e');
    }
    // Continue with app initialization even if Firebase fails
  }

  if (kDebugMode) {
    debugPrint('Before StorageService.initializeHive');
  }
  await StorageService.initializeHive();
  if (kDebugMode) {
    debugPrint('After StorageService.initializeHive');
  }

  // Initialize Error Handler
  ErrorHandler.initialize(navigatorKey);

  // Create enhanced storage service instance
  final storageService = EnhancedStorageService();
  final aiService = AiService();
  final analyticsService = AnalyticsService(storageService);
  final educationalContentService = EducationalContentService();
  final gamificationService = GamificationService(storageService, CloudStorageService(storageService));
  final premiumService = PremiumService();
  final adService = AdService();
  final googleDriveService = GoogleDriveService(storageService);
  final navigationSettingsService = NavigationSettingsService();
  final communityService = CommunityService();

  if (kDebugMode) {
    debugPrint('Before service initializations');
  }
  await Future.wait([
    gamificationService.initGamification(),
    premiumService.initialize(),
    adService.initialize(),
    communityService.initCommunity(),
  ]);
  if (kDebugMode) {
    debugPrint('After service initializations');
  }

  if (kDebugMode) {
    debugPrint('Before runApp');
  }
  runApp(WasteSegregationApp(
    storageService: storageService,
    aiService: aiService,
    analyticsService: analyticsService,
    educationalContentService: educationalContentService,
    gamificationService: gamificationService,
    premiumService: premiumService,
    adService: adService,
    googleDriveService: googleDriveService,
    navigationSettingsService: navigationSettingsService,
    communityService: communityService,
  ));
  if (kDebugMode) {
    debugPrint('After runApp');
  }
}

void _setupErrorHandling() {
  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
      debugPrint('🚨 Flutter Error Captured: ${details.exception}');
      debugPrint('📍 Stack: ${details.stack}');
    }
    
    // Send to Crashlytics in release mode
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Capture errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('🚨 Platform Error Captured: $error');
      debugPrint('📍 Stack: $stack');
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
    required this.googleDriveService,
    required this.gamificationService,
    required this.educationalContentService,
    required this.premiumService,
    required this.adService,
    required this.navigationSettingsService,
    required this.communityService,
  });
  final StorageService storageService;
  final AiService aiService;
  final AnalyticsService analyticsService;
  final GoogleDriveService googleDriveService;
  final GamificationService gamificationService;
  final EducationalContentService educationalContentService;
  final PremiumService premiumService;
  final AdService adService;
  final NavigationSettingsService navigationSettingsService;
  final CommunityService communityService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ThemeProvider for dynamic theming
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Provide existing service instances
        Provider<StorageService>.value(value: storageService),
        Provider<AiService>.value(value: aiService),
        ChangeNotifierProvider<AnalyticsService>.value(value: analyticsService),
        Provider<GoogleDriveService>.value(value: googleDriveService),
        Provider<EducationalContentService>.value(value: educationalContentService),
        Provider<GamificationService>.value(value: gamificationService),
        ChangeNotifierProvider<PremiumService>.value(value: premiumService),
        ChangeNotifierProvider<AdService>.value(value: adService),
        ChangeNotifierProvider<NavigationSettingsService>.value(value: navigationSettingsService),
        Provider<CommunityService>.value(value: communityService),

        // Other providers
        Provider(create: (_) => UserConsentService()),
        Provider(create: (context) => CloudStorageService(context.read<StorageService>())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          
          // ADD ROUTE DEFINITIONS:
          routes: {
            '/home': (context) => const MainNavigationWrapper(),
            '/settings': (context) => const SettingsScreen(),
            '/history': (context) => const HistoryScreen(),
            '/achievements': (context) => const AchievementsScreen(),
            '/educational': (context) => const EducationalContentScreen(),
            '/analytics': (context) => const WasteDashboardScreen(),
            '/premium': (context) => const PremiumFeaturesScreen(),
            '/data-export': (context) => const DataExportScreen(),
            '/offline-settings': (context) => const OfflineModeSettingsScreen(),
            '/disposal-facilities': (context) => const DisposalFacilitiesScreen(),
          },
            home: FutureBuilder<Map<String, bool>>(
              future: _checkInitialConditions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SplashScreen();
                }

                final conditions = snapshot.data ?? {
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
      ),
    );
  }

  Future<Map<String, bool>> _checkInitialConditions() async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    // Check user consent status
    final userConsentService = UserConsentService();
    final hasConsent = await userConsentService.hasAllRequiredConsents();
    
    return {
      'hasConsent': hasConsent,
    };
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
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.secondaryColor,
              AppTheme.secondaryColor.withOpacity(0.6),
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
                          color: Colors.black.withOpacity(0.3),
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
                                  AppTheme.primaryColor.withOpacity(0.1),
                                  AppTheme.secondaryColor.withOpacity(0.1),
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
                                    color: AppTheme.primaryColor.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.8),
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
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingRegular),
                    Text(
                      'Initializing...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
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