import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/premium_service.dart';
import 'providers/theme_provider.dart';

/// Riverpod providers for existing services
/// This allows gradual migration from Provider to Riverpod

// Theme Provider - migrated to Riverpod
final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());

// Premium Service Provider - migrated to Riverpod
final premiumServiceProvider = Provider<PremiumService>((ref) => PremiumService());

// For testing, we can easily override these providers:
// Example:
// ProviderScope(
//   overrides: [
//     premiumServiceProvider.overrideWithValue(mockPremiumService),
//     themeProvider.overrideWithValue(mockThemeProvider),
//   ],
//   child: MyApp(),
// ) 