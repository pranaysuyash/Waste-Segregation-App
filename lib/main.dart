import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/ai_service.dart';
import 'services/google_drive_service.dart';
import 'services/storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
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
  
  // Initialize Gamification Service
  final gamificationService = GamificationService();
  await gamificationService.initGamification();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<AiService>(
          create: (_) => AiService(),
        ),
        Provider<EducationalContentService>(
          create: (_) => EducationalContentService(),
        ),
        Provider<GamificationService>(
          create: (_) => GamificationService(),
        ),
        ProxyProvider<StorageService, GoogleDriveService>(
          update: (_, storageService, __) => GoogleDriveService(storageService),
        ),
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
    final storageService = Provider.of<StorageService>(context, listen: false);
    return storageService.isUserLoggedIn();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({Key? key}) : super(key: key);

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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Icon(
                Icons.restore_from_trash,
                size: 100,
                color: Colors.white,
              ),
              
              SizedBox(height: AppTheme.paddingRegular),
              
              // App name
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: AppTheme.paddingLarge),
              
              // Loading indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}