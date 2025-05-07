# Waste Segregation App - Developer Documentation

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

## Core Features

### 1. Classification Caching System

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

### 2. AI Classification Service

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

### 3. Local Storage System

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

### 4. Authentication

#### Overview
The app supports both Google Sign-In and a Guest Mode.

#### Implementation

- Google Sign-In uses Firebase Authentication
- Guest mode stores data locally without online account
- Automatic session persistence with Hive

### 5. Gamification

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
├── screens/         # UI screens
├── services/        # Business logic
├── utils/           # Utilities and constants
├── widgets/         # Reusable UI components
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