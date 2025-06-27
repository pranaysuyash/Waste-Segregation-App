import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/providers/theme_provider.dart';
import 'package:waste_segregation_app/providers/points_engine_provider.dart';
import '../mocks/mock_services.dart';

class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final MockAiService? mockAiService;
  final MockStorageService? mockStorageService;
  final MockGamificationService? mockGamificationService;
  final MockPremiumService? mockPremiumService;
  final MockAnalyticsService? mockAnalyticsService;
  final MockCommunityService? mockCommunityService;

  const TestAppWrapper({
    Key? key,
    required this.child,
    this.mockAiService,
    this.mockStorageService,
    this.mockGamificationService,
    this.mockPremiumService,
    this.mockAnalyticsService,
    this.mockCommunityService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (mockAiService != null) aiServiceProvider.overrideWithValue(mockAiService!),
        if (mockStorageService != null) storageServiceProvider.overrideWithValue(mockStorageService!),
        if (mockGamificationService != null) gamificationServiceProvider.overrideWithValue(mockGamificationService!),
        if (mockPremiumService != null) premiumServiceProvider.overrideWithValue(mockPremiumService!),
        if (mockAnalyticsService != null) analyticsServiceProvider.overrideWithValue(mockAnalyticsService!),
        if (mockCommunityService != null) communityServiceProvider.overrideWithValue(mockCommunityService!),
      ],
      child: MaterialApp(
        title: 'Test App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
        ),
        home: child,
        navigatorObservers: [
          DebugNavigatorObserver(),
        ],
      ),
    );
  }
}

class DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('🧭 NAVIGATION PUSH: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('🧭 NAVIGATION POP: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('🧭 NAVIGATION REPLACE: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
  }
}

// Test helper to initialize Hive for tests
Future<void> initializeHiveForTesting() async {
  if (!Hive.isAdapterRegistered(0)) {
    // Register any required Hive adapters here
    // This prevents "adapter not registered" errors in tests
  }

  // Initialize Hive with a temporary directory for tests
  await Hive.initFlutter('test_hive');
}

// Test helper to clean up Hive after tests
Future<void> cleanupHiveAfterTesting() async {
  await Hive.deleteFromDisk();
  await Hive.close();
}

// Provider definitions for dependency injection
final aiServiceProvider = Provider<AiService>((ref) => throw UnimplementedError());
final storageServiceProvider = Provider<StorageService>((ref) => throw UnimplementedError());
final gamificationServiceProvider = Provider<GamificationService>((ref) => throw UnimplementedError());
final premiumServiceProvider = Provider<PremiumService>((ref) => throw UnimplementedError());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => throw UnimplementedError());
final communityServiceProvider = Provider<CommunityService>((ref) => throw UnimplementedError());
