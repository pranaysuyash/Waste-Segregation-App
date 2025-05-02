# Waste Segregation App

An educational Flutter application that teaches proper waste segregation to both kids and adults using AI.

## Overview

This cross-platform app allows users to capture or upload images, then uses Google's Gemini API (via OpenAI-compatible endpoint with the gemini-2.0-flash model) to identify items and classify them into waste categories:
- Wet Waste (organic, compostable)
- Dry Waste (recyclable)
- Hazardous Waste (requires special handling)
- Medical Waste (potentially contaminated)
- Non-Waste (reusable items, edible food)

The app provides educational content about each category, stores classification data locally using Hive, and optionally synchronizes user data to Google Drive.

## Features

- **User Authentication**:
  - Google Sign-In integration
  - Guest Mode for local-only storage

- **Image Recognition**:
  - Capture images using the camera
  - Upload images from the gallery
  - AI-powered item recognition and waste classification

- **Educational Content**:
  - Detailed explanations for each waste category
  - Articles, videos, infographics, and quizzes
  - Bookmarkable content for quick access
  - Waste category-specific information

- **Gamification & User Engagement**:
  - Points and levels system
  - Achievement badges for waste identification
  - Daily streaks with bonus incentives
  - Challenges with rewards
  - Weekly statistics tracking

- **Data Management**:
  - Local storage of classifications and user preferences
  - Optional sync to Google Drive for cross-device access
  - History of previously identified items

## Technical Implementation

- **Framework**: Flutter
- **State Management**: Provider
- **Local Storage**: Hive
- **Backend Services**: Firebase for authentication
- **Image Handling**: image_picker package
- **AI Integration**: Gemini API via OpenAI-compatible endpoint using the gemini-2.0-flash model
- **Google Integration**: google_sign_in package with Firebase authentication

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- Android or iOS device/emulator

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/pranaysuyash/Waste-Segregation-App.git
   cd waste_segregation_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate model code:
   ```bash
   flutter pub run build_runner build
   ```

4. Configure API keys:
   - Open `lib/utils/constants.dart`
   - Update the `ApiConfig` class with your own Gemini API key
   - The app uses Gemini API via OpenAI-compatible endpoint and the gemini-2.0-flash model
   - The API authentication uses the standard Bearer token format

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/
│   ├── waste_classification.dart
│   ├── educational_content.dart
│   └── gamification.dart
├── screens/
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── image_capture_screen.dart
│   ├── result_screen.dart
│   ├── educational_content_screen.dart
│   ├── content_detail_screen.dart
│   ├── quiz_screen.dart
│   ├── achievements_screen.dart
│   └── leaderboard_screen.dart
├── services/
│   ├── ai_service.dart
│   ├── storage_service.dart
│   ├── google_drive_service.dart
│   ├── educational_content_service.dart
│   └── gamification_service.dart
├── widgets/
│   ├── capture_button.dart
│   ├── classification_card.dart
│   ├── platform_camera.dart
│   ├── enhanced_camera.dart
│   └── gamification_widgets.dart
├── utils/
│   └── constants.dart
└── main.dart
```

## Current Status

-### Implemented Features
- AI integration with Gemini Vision API
- Waste classification with detailed categories
- Basic image capture and upload functionality
- Core UI screens (home, auth, image capture, results)
- Educational content framework
- Comprehensive gamification system (points, achievements, challenges)
- Local storage with Hive
- Google Sign-In
- Thumbnail generation and storage for classifications (local image caching)
- Local in-memory SHA-256 image classification cache

-### In Progress / Pending
- Leaderboard implementation
- Enhanced camera features
- Quiz functionality completion
- Social sharing capabilities
- Enhanced web camera support
- Cross-user classification caching with Firestore (planned)
- UI Refactoring & Modularization (breaking screens into reusable widgets)

## Roadmap

For a consolidated feature roadmap—including implemented, in-progress, pending, and future plans—see [project_features.md](project_features.md).

## Dependencies

- provider: ^6.1.1
- hive: ^2.2.3
- hive_flutter: ^1.1.0
- path_provider: ^2.1.1
- image_picker: ^1.0.7
- image_picker_for_web: ^3.0.1
- camera: ^0.10.5+9
- permission_handler: ^11.2.0
- http: ^1.1.0
- google_sign_in: ^6.1.6
- googleapis: ^13.2.0
- share_plus: ^7.2.1

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini API for AI vision capabilities through the OpenAI-compatible endpoint
- Flutter team for the amazing framework
- All contributors to the open-source packages used in this project