import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/waste_classification.dart';
import 'models/gamification.dart';
import 'models/educational_content.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/google_drive_service.dart';
import 'utils/constants.dart'; 

// Import generated Hive Adapters
import 'models/waste_classification.g.dart';
import 'models/gamification.g.dart';
import 'models/educational_content.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters (assuming generated files exist)
  try {
    Hive.registerAdapter(WasteClassificationAdapter());
    Hive.registerAdapter(AchievementAdapter());
    Hive.registerAdapter(ChallengeAdapter());
    Hive.registerAdapter(GamificationProfileAdapter());
    Hive.registerAdapter(ContentProgressAdapter());
    Hive.registerAdapter(EducationalContentAdapter());
    Hive.registerAdapter(ContentTypeAdapter());
    Hive.registerAdapter(DifficultyLevelAdapter());
  } catch (e) {
    print('Error registering Hive adapters: $e');
    // Handle error appropriately, maybe show an error screen
  }

  // Open Hive boxes using keys from StorageKeys
  await Hive.openBox<WasteClassification>(StorageKeys.classificationsBox);
  await Hive.openBox<GamificationProfile>(StorageKeys.gamificationBox);
  await Hive.openBox<EducationalContent>(StorageKeys.educationalContentBox);
  await Hive.openBox(StorageKeys.userInfoBox);
  await Hive.openBox(StorageKeys.appSettingsBox);

  // Initialize services (Ensure constructors match definition)
  final storageService = StorageService(); // Assumes StorageService() has no args
  final googleDriveService = GoogleDriveService(storageService: storageService); // Assuming named param
  final gamificationService = GamificationService(storageService: storageService); // Assuming named param
  final educationalContentService = EducationalContentService(storageService: storageService, gamificationService: gamificationService); // Assuming named params

  runApp(WasteSegregationApp(
    storageService: storageService,
    googleDriveService: googleDriveService,
    gamificationService: gamificationService,
    educationalContentService: educationalContentService,
  ));
}

class WasteSegregationApp extends StatelessWidget {
  final StorageService storageService;
  final GoogleDriveService googleDriveService;
  final GamificationService gamificationService;
  final EducationalContentService educationalContentService;

  const WasteSegregationApp({
    super.key,
    required this.storageService,
    required this.googleDriveService,
    required this.gamificationService,
    required this.educationalContentService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<GoogleDriveService>.value(value: googleDriveService),
        Provider<GamificationService>.value(value: gamificationService),
        Provider<EducationalContentService>.value(value: educationalContentService),
      ],
      child: FutureBuilder(
        // Check sign-in status using the Google Drive Service
        future: googleDriveService.isSignedIn(), 
        builder: (context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a themed splash screen while waiting
            return const MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
          
          final bool signedIn = snapshot.data ?? false;
          
          return MaterialApp(
            title: AppStrings.appName,
            theme: AppTheme.lightTheme, 
            darkTheme: AppTheme.darkTheme, 
            themeMode: ThemeMode.system, // TODO: Load from StorageService later
            home: signedIn ? const HomeScreen() : const AuthScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
