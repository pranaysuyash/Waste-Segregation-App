# Waste Segregation App: Complete Developer Guide

## Overview

This comprehensive developer guide provides everything you need to understand, develop, and contribute to the Waste Segregation App. The app is built with Flutter and uses Firebase for backend services, multiple AI providers for waste classification, and follows modern mobile development practices.

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Project Architecture](#project-architecture)
3. [Code Organization](#code-organization)
4. [Development Workflow](#development-workflow)
5. [Key Components](#key-components)
6. [API Integration](#api-integration)
7. [Testing Strategy](#testing-strategy)
8. [Performance Optimization](#performance-optimization)
9. [Deployment Guide](#deployment-guide)
10. [Troubleshooting](#troubleshooting)
11. [Contributing Guidelines](#contributing-guidelines)

## Development Environment Setup

### Prerequisites

Before starting development, ensure you have the following installed:

- **Flutter SDK**: Latest stable version (3.0.0+)
- **Dart SDK**: Comes with Flutter
- **Android Studio**: For Android development and debugging
- **Xcode**: For iOS development (macOS only)
- **Visual Studio Code**: Recommended IDE with Flutter extensions
- **Git**: Version control
- **Firebase CLI**: For Firebase integration

### Initial Setup

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd waste_segregation_app
```

#### 2. Install Flutter Dependencies
```bash
flutter pub get
```

#### 3. Generate Required Files
```bash
# Generate model files (if using code generation)
flutter pub run build_runner build

# Clean and get dependencies
flutter clean
flutter pub get
```

#### 4. Configure Environment Variables

Create a `.env` file in the project root (copy from `.env.example`):
```env
# AI Service API Keys
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# App Configuration
DEBUG_MODE=true
LOG_LEVEL=debug

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

#### 5. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Google Sign-In, Anonymous)
   - Cloud Firestore
   - Storage
   - Analytics
   - Crashlytics

3. Download configuration files:
   - `google-services.json` for Android (`android/app/`)
   - `GoogleService-Info.plist` for iOS (`ios/Runner/`)

4. Configure Firebase for Flutter:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

#### 6. Run the App
```bash
# Check for issues
flutter doctor

# Run on connected device/simulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run on specific device
flutter devices
flutter run -d <device_id>
```

## Project Architecture

### High-Level Architecture

The app follows a layered architecture pattern:

```
┌─────────────────────────────────────────┐
│              Presentation Layer          │
│         (Screens & Widgets)             │
├─────────────────────────────────────────┤
│              Business Logic Layer        │
│            (Providers & Services)        │
├─────────────────────────────────────────┤
│               Data Layer                 │
│          (Models & Repositories)         │
├─────────────────────────────────────────┤
│             Platform Layer               │
│        (External APIs & Services)        │
└─────────────────────────────────────────┘
```

### State Management

The app uses the **Provider** pattern for state management:

```dart
// Service providers for dependency injection
MultiProvider(
  providers: [
    Provider<StorageService>.value(value: storageService),
    Provider<AiService>.value(value: aiService),
    ChangeNotifierProvider<PremiumService>.value(value: premiumService),
    ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
  ],
  child: MyApp(),
)
```

## Code Organization

### Directory Structure

```
lib/
├── main.dart                    # App entry point
├── web_standalone.dart          # Web platform entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
├── screens/                     # UI screens
├── widgets/                     # Reusable widgets
├── services/                    # Business logic services
├── providers/                   # State management
├── utils/                       # Utility functions
└── web_utils/                   # Web-specific utilities
```

### Key Components

#### AI Service Architecture
```dart
class AiService {
  final List<AiProvider> _providers = [
    GeminiProvider(),
    OpenAIProvider(),
    TensorFlowLiteProvider(),
  ];
  
  Future<WasteClassification> classifyImage(File imageFile) async {
    for (final provider in _providers) {
      try {
        if (await provider.isAvailable()) {
          return await provider.classify(imageFile);
        }
      } catch (e) {
        print('Provider ${provider.name} failed: $e');
        continue; // Try next provider
      }
    }
    throw Exception('All AI providers failed');
  }
}
```

## Testing Strategy

### Testing Structure
```
test/
├── unit_tests/
│   ├── services/
│   ├── models/
│   └── utils/
├── widget_tests/
│   ├── screens/
│   └── widgets/
└── integration_tests/
```

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit_tests/services/ai_service_test.dart

# Run tests with coverage
flutter test --coverage
```

## Deployment Guide

### Android Deployment
```bash
# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS Deployment
```bash
# Build iOS release
flutter build ios --release
```

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
# Check Flutter installation
flutter doctor -v

# Fix Android licenses
flutter doctor --android-licenses
```

#### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk
```

## Contributing Guidelines

### Development Process

1. **Create Feature Branch**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

2. **Development Cycle**
```bash
# Make changes
# Test locally
flutter test
flutter analyze

# Commit changes
git add .
git commit -m "feat: add waste classification caching"

# Push feature branch
git push origin feature/your-feature-name
```

### Code Quality Standards

- Follow Dart style guidelines
- Add tests for new features
- Update documentation
- Ensure all tests pass
- Run code analysis

This developer guide provides the foundation for effective development on the Waste Segregation App, covering all essential aspects from setup to deployment and contribution guidelines.
