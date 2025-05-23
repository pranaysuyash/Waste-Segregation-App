# Waste Segregation App - Developer Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Core Features](#core-features)
4. [Code Organization](#code-organization)
5. [Development Guidelines](#development-guidelines)
6. [Integration Points](#integration-points)
7. [Testing](#testing)
8. [Future Enhancements](#future-enhancements)
9. [Troubleshooting](#troubleshooting)
10. [Recent Code Improvements](#recent-code-improvements)
11. [Crash Reporting & Error Handling](#crash-reporting-error-handling)

## Introduction

The Waste Segregation App is a Flutter-based educational application that helps users properly segregate waste items using AI-powered image classification. This document provides comprehensive documentation for developers working on the project.

## Architecture Overview

The application follows a layered architecture with:

1. **Presentation Layer**: UI components, screens, and widgets
2. **Business Logic Layer**: Services for AI, storage, authentication, and gamification
3. **Data Layer**: Models and storage implementations

### Key Components

- **AI Service**: Handles image classification using Google's Gemini API
- **Storage Service**: Manages local data using Hive
- **Google Drive Service**: Provides cloud sync capabilities
- **Educational Content Service**: Delivers learning materials
- **Gamification Service**: Manages points, achievements, and challenges
- **Premium Service**: Manages premium feature states and access

## Core Features

### 1. Premium Feature Management

#### Overview
The premium feature management system provides a framework for marking features as premium or coming soon, with a clean UI for displaying these states to users.

#### Key Files

| File | Purpose |
|------|---------|
| `/lib/widgets/premium_badge.dart` | Premium feature indicator badge |
| `/lib/widgets/premium_feature_card.dart` | Premium feature display card |
| `/lib/models/premium_feature.dart` | Premium feature data model |
| `/lib/services/premium_service.dart` | Premium feature state management |
| `/lib/screens/premium_features_screen.dart` | Premium features display screen |

#### Implementation

1. Premium Feature Model:
```dart
class PremiumFeature {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String route;
  final bool isEnabled;
}
```

2. Premium Service:
```dart
class PremiumService {
  Future<void> initialize() async {
    _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
  }

  bool isPremiumFeature(String featureId) {
    return _premiumBox.get(featureId) ?? false;
  }
}
```

3. Usage in UI:
```dart
PremiumFeatureCard(
  title: feature.title,
  description: feature.description,
  icon: IconData(int.parse(feature.icon), fontFamily: 'MaterialIcons'),
)
```

#### Integration

To mark a feature as premium:
1. Add the feature to `PremiumFeature.features` list
2. Use `PremiumBadge` widget in the feature's UI
3. Check feature access using `PremiumService.isPremiumFeature()`

### 2. Classification Caching System

#### Overview
The classification caching system provides local device-based caching of AI classification results indexed by image hash. This significantly reduces API calls, improves response times, and ensures consistent results for the same image.

#### Key Files

| File | Purpose |
|------|---------|
| `/lib/utils/image_utils.dart` | Image hashing and preprocessing |
| `/lib/models/cached_classification.dart` | Cache entry model |
| `/lib/services/cache_service.dart` | Cache management with LRU eviction |

#### Flow

1. When an image is captured/uploaded:
   - A SHA-256 hash is generated from the normalized image
   - The cache is checked for matching hash
   - If found, cached result is returned instantly
   - If not found, API is called and result is cached

#### Usage

```dart
// Initialization (in app startup)
final cacheService = ClassificationCacheService();
await cacheService.initialize();

// In AI Service
if (cachingEnabled) {
  final imageHash = await ImageUtils.generateImageHash(imageBytes);
  final cachedResult = await cacheService.getCachedClassification(imageHash);
  
  if (cachedResult != null) {
    return cachedResult.classification;
  }
  
  // Continue with API call...
}
```

#### Monitoring

The `CacheStatisticsCard` widget provides real-time visibility into cache performance including hit rate, size, and estimated data savings.

### 3. AI Classification Service

#### Overview
The AI service sends images to Google's Gemini API (with OpenAI fallback) for waste classification.

#### Key Files

| File | Purpose |
|------|---------|
| `/lib/services/ai_service.dart` | Core API integration |
| `/lib/models/waste_classification.dart` | Classification model |
| `/lib/utils/constants.dart` | API configuration |

#### Classification Hierarchy

Images are classified into a hierarchical structure:

1. **Main Categories**:
   - Wet Waste (organic, compostable)
   - Dry Waste (recyclable)
   - Hazardous Waste (requires special handling)
   - Medical Waste (potentially contaminated)
   - Non-Waste (reusable items)

2. **Subcategories** (varies by main category)
   - For example, Dry Waste includes: Paper, Plastic, Glass, Metal, etc.

#### Error Handling

The service includes:
- Automatic retries with exponential backoff
- Fallback to OpenAI when Gemini is unavailable
- Graceful degradation for offline usage via cache

### 4. Local Storage System

#### Overview
The app uses Hive for efficient local storage of all data.

#### Key Boxes

| Box Name | Content | Purpose |
|----------|---------|---------|
| `userBox` | User information | Authentication details |
| `classificationsBox` | Past classifications | History and analytics |
| `settingsBox` | User preferences | App configuration |
| `cacheBox` | Cached classifications | Performance optimization |
| `gamificationBox` | Points, achievements | User engagement |

#### Initialization

```dart
// In storage_service.dart
static Future<void> initializeHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDocumentDirectory = 
      await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDirectory.path);
  }
  
  // Open boxes
  await Hive.openBox(StorageKeys.userBox);
  await Hive.openBox(StorageKeys.classificationsBox);
  await Hive.openBox(StorageKeys.settingsBox);
  await Hive.openBox<String>(StorageKeys.cacheBox);
}
```

### 5. Authentication

#### Overview
The app supports both Google Sign-In and a Guest Mode.

#### Implementation

- Google Sign-In uses Firebase Authentication
- Guest mode stores data locally without online account
- Automatic session persistence with Hive

### 6. Gamification

#### Overview
The app includes a comprehensive gamification system to enhance user engagement.

#### Features

- Points for classifying items
- Achievement badges for specific accomplishments
- Daily streaks with bonuses
- Weekly challenges
- Leaderboard (in development)

## Code Organization

```
lib/
├── models/          # Data models
│   ├── premium_feature.dart
│   └── ...
├── screens/         # UI screens
│   ├── premium_features_screen.dart
│   └── ...
├── services/        # Business logic
│   ├── premium_service.dart
│   └── ...
├── utils/           # Utilities and constants
├── widgets/         # Reusable UI components
│   ├── premium_badge.dart
│   ├── premium_feature_card.dart
│   └── ...
└── main.dart        # Application entry point
```

## Development Guidelines

### 1. Code Style

- Follow Flutter's style guide
- Use meaningful variable and function names
- Add documentation for public APIs
- Keep functions small and focused

### 2. State Management

- Provider is used for state management
- Avoid direct widget state when possible
- Use `Consumer` widgets for targeted rebuilds

### 3. Error Handling

- Use try-catch blocks for network operations
- Provide meaningful error messages
- Implement graceful degradation for offline use
- Log errors with descriptive context

### 4. Testing

- Unit tests for services and utilities
- Widget tests for UI components
- Integration tests for key user flows
- Mock dependencies for isolated testing

### 5. Performance Considerations

- Use const constructors where possible
- Implement pagination for large lists
- Optimize image processing operations
- Use caching for network resources

## Integration Points

### 1. API Integration

The app uses Google's Gemini API via its OpenAI-compatible endpoint with the `gemini-2.0-flash` model. This is implemented in `ai_service.dart`.

Configuration in `constants.dart`:
```dart
static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
static const String model = 'gemini-2.0-flash';
```

### 2. Google Drive Integration

For users who opt in, the app can synchronize classification history to Google Drive, allowing cross-device access.

## Future Enhancements

1. **Cross-User Classification Caching**:
   - Implement Firebase Firestore integration
   - Share common classifications across all users
   - Implement privacy controls

2. **Enhanced Camera Features**:
   - Real-time item detection
   - Multi-item classification
   - Improved segmentation

3. **Social Features**:
   - Sharing classifications on social media
   - Community challenges
   - Group competitions

## Troubleshooting

### Common Issues

1. **API Rate Limiting**: If the app hits API rate limits, it will use progressively longer retry intervals and ultimately fall back to the cache.

2. **Image Processing Errors**: Large images may cause memory issues on low-end devices. The app incorporates image downsizing before processing.

3. **Cache Corruption**: If the cache becomes corrupted, the app will automatically rebuild it from scratch. This is handled in the catch blocks of cache operations.

4. **Premium Feature Access**: If premium features are not accessible:
   - Check if the feature is properly registered in `PremiumFeature.features`
   - Verify the feature state in Hive storage
   - Ensure the premium service is properly initialized

## Environment Setup

### Required Tools

- Flutter SDK (latest stable)
- Android Studio or VS Code with Flutter plugins
- Firebase CLI for deployments
- Google Cloud account for API access

### Configuration

1. Clone the repository
2. Run `flutter pub get`
3. Update API keys in `constants.dart`
4. Run `flutter pub run build_runner build` to generate code
5. Use `flutter run` to launch the app

## Deployment

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

## Additional Resources

- Project Roadmap: See `project_features.md`
- Classification Options Analysis: See `classification_caching_options.md`
- Implementation Details: See `classification_caching_implementation.md`

## Recent Code Improvements

- **Centralized Error Handling**: All major screens now use a centralized `ErrorHandler` and `AppException` pattern for consistent error logging and user feedback. See `constants.dart`.
- **Web Camera Access**: Camera capture is now supported in the browser using `image_picker_for_web` (see `web_camera_access.dart`).
- **UI and Media Rendering**: Improved text overflow handling and media (video/image) rendering in educational content screens (see `result_screen.dart`, `content_detail_screen.dart`).

## Crash Reporting & Error Handling

- **Crashlytics Integration:**
  - All errors are reported to Firebase Crashlytics via the centralized `ErrorHandler`.
  - A force crash button is available in the Settings screen (Developer Options) for testing fatal crash reporting.
  - Non-fatal errors are sent on app startup for verification.
- **How to Test:**
  - Use the force crash button in Settings > Developer Options to trigger a fatal crash and verify Crashlytics reporting in the Firebase Console.
  - Check terminal logs for Crashlytics submission messages.