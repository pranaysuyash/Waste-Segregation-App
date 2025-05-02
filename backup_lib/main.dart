import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/waste_classification.dart';
import 'models/gamification.dart';
import 'models/educational_content.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/educational_content_service.dart';
import 'services/gamification_service.dart';
import 'services/google_drive_service.dart';
import 'services/ai_service.dart';
import 'utils/constants.dart'; 

// Import generated Hive Adapters
import 'models/waste_classification.g.dart';
import 'models/gamification.g.dart';
import 'models/educational_content.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive Adapters
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
  }

  // Open Hive boxes
  await Hive.openBox<WasteClassification>(StorageKeys.classificationsBox);
  await Hive.openBox<GamificationProfile>(StorageKeys.gamificationBox);
  await Hive.openBox<EducationalContent>(StorageKeys.educationalContentBox);
  await Hive.openBox(StorageKeys.userInfoBox);
  await Hive.openBox(StorageKeys.appSettingsBox);

  // Initialize services
  final storageService = StorageService();
  final aiService = AiService();
  final googleDriveService = GoogleDriveService(storageService: storageService);
  final gamificationService = GamificationService(storageService: storageService);
  final educationalContentService = EducationalContentService(
    storageService: storageService, 
    gamificationService: gamificationService
  );

  runApp(WasteSegregationApp(
    storageService: storageService,
    aiService: aiService,
    googleDriveService: googleDriveService,
    gamificationService: gamificationService,
    educationalContentService: educationalContentService,
  ));
}

class WasteSegregationApp extends StatelessWidget {
  final StorageService storageService;
  final AiService aiService;
  final GoogleDriveService googleDriveService;
  final GamificationService gamificationService;
  final EducationalContentService educationalContentService;

  const WasteSegregationApp({
    super.key,
    required this.storageService,
    required this.aiService,
    required this.googleDriveService,
    required this.gamificationService,
    required this.educationalContentService,
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
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/auth': (context) => const AuthScreen(),
        },
      ),
    );
  }
}