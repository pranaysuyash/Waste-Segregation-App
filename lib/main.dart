import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'services/ai_service.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/enhanced_storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'services/user_consent_service.dart';
import 'screens/auth_screen.dart';
import 'screens/consent_dialog_screen.dart';
import 'utils/constants.dart'; // For app constants, themes, and strings
import 'utils/design_system.dart';
import 'utils/error_handler.dart'; // Correct import for ErrorHandler
import 'providers/theme_provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

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

void main() {
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

  if (!kIsWeb) {
    print('Before setPreferredOrientations');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    print('After setPreferredOrientations');
  }

  print('Before Firebase.initializeApp');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
    // --- Crashlytics test: Remove after verification ---
    await FirebaseCrashlytics.instance.recordError(
      Exception('Test non-fatal error from Flutter!'),
      StackTrace.current,
      reason: 'Crashlytics integration test',
      fatal: false,
    );
    // --- End test ---
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }

  print('Before StorageService.initializeHive');
  await StorageService.initializeHive();
  print('After StorageService.initializeHive');

  // Initialize Error Handler
  ErrorHandler.initialize(navigatorKey);

  // Create enhanced storage service instance
  final storageService = EnhancedStorageService();
  final aiService = AiService();
  final educationalContentService = EducationalContentService();
  final gamificationService = GamificationService();
  final premiumService = PremiumService();
  final adService = AdService();
  final googleDriveService = GoogleDriveService(storageService);

  print('Before service initializations');
  await Future.wait([
    gamificationService.initGamification(),
    premiumService.initialize(),
    adService.initialize(),
  ]);
  print('After service initializations');

  print('Before runApp');
  runApp(WasteSegregationApp(
    storageService: storageService,
    aiService: aiService,
    educationalContentService: educationalContentService,
    gamificationService: gamificationService,
    premiumService: premiumService,
    adService: adService,
    googleDriveService: googleDriveService,
  ));
  print('After runApp');
}

class WasteSegregationApp extends StatelessWidget {
  final StorageService storageService;
  final AiService aiService;
  final GoogleDriveService googleDriveService;
  final GamificationService gamificationService;
  final EducationalContentService educationalContentService;
  final PremiumService premiumService;
  final AdService adService;

  const WasteSegregationApp({
    super.key,
    required this.storageService,
    required this.aiService,
    required this.googleDriveService,
    required this.gamificationService,
    required this.educationalContentService,
    required this.premiumService,
    required this.adService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AiService>.value(value: aiService),
        Provider<GoogleDriveService>.value(value: googleDriveService),
        Provider<GamificationService>.value(value: gamificationService),
        Provider<EducationalContentService>.value(value: educationalContentService),
        ChangeNotifierProvider<PremiumService>.value(value: premiumService),
        ChangeNotifierProvider<AdService>.value(value: adService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          theme: WasteAppDesignSystem.lightTheme,
          darkTheme: WasteAppDesignSystem.darkTheme,
          themeMode: themeProvider.themeMode,
            home: FutureBuilder<Map<String, bool>>(
              future: _checkInitialConditions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SplashScreen();
                }

                final Map<String, bool> conditions = snapshot.data ?? {
                  'hasConsent': false,
                  'isLoggedIn': false,
                };
                
                final bool hasConsent = conditions['hasConsent'] ?? false;
                final bool isLoggedIn = conditions['isLoggedIn'] ?? false;
                
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
    final bool hasConsent = await userConsentService.hasAllRequiredConsents();
    
    // Check if user is logged in
    final bool isLoggedIn = storageService.isUserLoggedIn();
    
    return {
      'hasConsent': hasConsent,
      'isLoggedIn': isLoggedIn,
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

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
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              SvgPicture.asset(
                'assets/images/splash_screen.svg',
                width: 100,
                height: 100,
                placeholderBuilder: (context) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.white.withOpacity(0.3),
                  child: const Icon(
                    Icons.restore_from_trash,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.paddingRegular),

              // App name
              const Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: AppTheme.paddingLarge),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}