# Riverpod Architecture Guide

**Date:** June 18, 2025  
**Author:** AI Assistant  
**Status:** ✅ Completed and Documented  

## Overview

This guide documents the pure Riverpod architecture that has been successfully implemented across the application. The migration from a hybrid Provider/Riverpod setup is complete, resulting in a more consistent, maintainable, and performant state management solution.

## Core Principles

The app's state management is now built entirely on Riverpod, following these core principles:

1.  **Single Source of Truth:** All application services and state notifiers are exposed through providers.
2.  **Centralized Providers:** Core service providers are declared in `lib/providers/app_providers.dart` to avoid duplication and provide a clear overview of the app's dependencies. Feature-specific providers are located in their respective feature directories.
3.  **Dependency Injection:** Riverpod's `ref` object is used for dependency injection, allowing services to be easily accessed and mocked in tests.
4.  **Consumer Widgets:** All UI components that need to interact with state are `ConsumerWidget` or `ConsumerStatefulWidget`, ensuring that they only rebuild when necessary.

## Current Architecture

The application's providers are organized as follows:

### 1. Central Service Providers (`lib/providers/app_providers.dart`)

This file contains providers for all major singleton services. This is the first place to look when you need to access a core service.

**Example from `app_providers.dart`:**
```dart
/// Storage service provider - single source of truth
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// Gamification service provider - depends on storage services
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  final cloudStorageService = ref.read(cloudStorageServiceProvider);
  return GamificationService(storageService, cloudStorageService);
});

/// User profile provider - for accessing user display name and other profile data
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getCurrentUserProfile();
});
```

### 2. Feature-Specific Providers

Providers that are specific to a certain feature (e.g., disposal instructions, leaderboard) are co-located with their feature code.

**Example (`lib/providers/disposal_instructions_provider.dart`):**
```dart
final disposalInstructionsProvider = FutureProvider.family<String, String>((ref, String material) async {
  // Fetches disposal instructions for a given material
});
```

## How to Use Providers in Widgets

To access state or services, use a `ConsumerWidget` or `ConsumerStatefulWidget` and the `WidgetRef` object.

**Example of a `ConsumerWidget`:**
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch a provider to rebuild the widget when its state changes
    final userProfile = ref.watch(userProfileProvider);

    // Read a service provider for one-time access (e.g., in an onTap callback)
    final gamificationService = ref.read(gamificationServiceProvider);

    return userProfile.when(
      data: (profile) => Text('Hello, ${profile?.displayName}'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

## Benefits of the Pure Riverpod Architecture

### 1. **Compile-Safe Dependencies**
- No more runtime `ProviderNotFoundException` errors.
- Type-safe provider access.
- Compile-time dependency validation.

### 2. **Superior Testing**
- Cleanly override any provider in any test.
- No complex `MultiProvider` setup required.
- Easy to mock individual services and dependencies.

**Example of a clean test:**
```dart
testWidgets('MyScreen shows user name', (tester) async {
  final mockProfile = UserProfile(id: '1', displayName: 'Test User');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Override the future provider with a pre-resolved value
        userProfileProvider.overrideWith((ref) => Future.value(mockProfile)),
      ],
      child: MaterialApp(home: MyScreen()),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('Hello, Test User'), findsOneWidget);
});
```

### 3. **Improved Performance**
- Widgets only rebuild when the specific providers they `watch` are updated.
- Automatic caching and disposal of provider state.

### 4. **Consistent and Maintainable Architecture**
- A single, well-understood pattern for state management across the app.
- Simplified dependency graph and easier maintenance.

## Migration Status: ✅ Complete

The migration is finished. All legacy `provider` package usage has been removed.

- [x] **Phase 1: Create Providers:** All services are now behind Riverpod providers.
- [x] **Phase 2: Convert Screens:** All screens and widgets have been converted to `ConsumerWidget` or `ConsumerStatefulWidget`.
- [x] **Phase 3: Update Tests:** All relevant tests use `ProviderScope` and `overrides` for mocking.
- [x] **Phase 4: Clean Up:** The `provider` package has been removed, and `main.dart` has been simplified. 