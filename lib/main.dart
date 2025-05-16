import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'services/ai_service.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/premium_service.dart';
import 'services/ad_service.dart';
import 'screens/auth_screen.dart';
import 'utils/constants.dart';

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
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await StorageService.initializeHive();

  // Create service instances early to allow initialization
  final storageService = StorageService();
  final aiService = AiService();
  final educationalContentService = EducationalContentService();
  final gamificationService = GamificationService();
  final premiumService = PremiumService();
  final adService = AdService();
  final googleDriveService = GoogleDriveService(storageService);

  // Initialize services in parallel
  await Future.wait([
    gamificationService.initGamification(),
    premiumService.initialize(),
    adService.initialize(),
  ]);

  runApp(MyApp(
    storageService: storageService,
    aiService: aiService,
    educationalContentService: educationalContentService,
    gamificationService: gamificationService,
    premiumService: premiumService,
    adService: adService,
    googleDriveService: googleDriveService,
  ));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final AiService aiService;
  final EducationalContentService educationalContentService;
  final GamificationService gamificationService;
  final PremiumService premiumService;
  final AdService adService;
  final GoogleDriveService googleDriveService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.aiService,
    required this.educationalContentService,
    required this.gamificationService,
    required this.premiumService,
    required this.adService,
    required this.googleDriveService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<AiService>.value(value: aiService),
        Provider<EducationalContentService>.value(value: educationalContentService),
        Provider<GamificationService>.value(value: gamificationService),
        // Use ChangeNotifierProvider for PremiumService
        ChangeNotifierProvider<PremiumService>.value(value: premiumService),
        // Use ChangeNotifierProvider for AdService 
        ChangeNotifierProvider<AdService>.value(value: adService),
        Provider<GoogleDriveService>.value(value: googleDriveService),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: ThemeData(
          primaryColor: AppTheme.primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryColor,
            secondary: AppTheme.secondaryColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        darkTheme: ThemeData(
          primaryColor: AppTheme.darkPrimaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.darkPrimaryColor,
            secondary: AppTheme.darkSecondaryColor,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppTheme.darkPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          scaffoldBackgroundColor: AppTheme.darkBackgroundColor,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: AppTheme.darkTextPrimaryColor,
            ),
          ),
        ),
        themeMode: ThemeMode.system, // Allows the system to choose light or dark theme
        home: FutureBuilder<bool>(
          future: _checkIfUserLoggedIn(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SplashScreen();
            }

            final bool isLoggedIn = snapshot.data ?? false;
            return isLoggedIn
                ? const AuthScreen() // Will automatically redirect to HomeScreen if logged in
                : const AuthScreen();
          },
        ),
      ),
    );
  }

  Future<bool> _checkIfUserLoggedIn(BuildContext context) async {
    // Wait a bit to show splash screen
    await Future.delayed(const Duration(seconds: 1));

    // Check if user is logged in
    return storageService.isUserLoggedIn();
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