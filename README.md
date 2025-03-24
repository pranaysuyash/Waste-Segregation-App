# Waste Segregation App

An educational Flutter application that teaches proper waste segregation to both kids and adults using AI.

## Overview

This cross-platform app allows users to capture or upload images, then uses Google's Gemini API (via an OpenAI-compatible endpoint) to identify items and classify them into waste categories:
- Wet Waste
- Dry Waste
- Hazardous Waste
- Medical Waste
- Non-Waste

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
  - Tips and facts about proper waste disposal
  - Daily waste reduction challenges

- **Data Management**:
  - Local storage of classifications and user preferences
  - Optional sync to Google Drive for cross-device access
  - History of previously identified items

## Technical Implementation

- **Framework**: Flutter
- **State Management**: Provider
- **Local Storage**: Hive with encryption
- **Image Handling**: image_picker package
- **AI Integration**: Gemini Vision API via HTTP calls (OpenAI-compatible)
- **Google Integration**: google_sign_in and googleapis packages

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio or VS Code with Flutter extensions
- Android or iOS device/emulator

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/waste_segregation_app.git
   cd waste_segregation_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure API keys:
   - Open `lib/utils/constants.dart`
   - Replace `YOUR_GEMINI_API_ENDPOINT` with your Gemini API endpoint
   - Replace `YOUR_API_KEY` with your API key

4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/
│   └── waste_classification.dart
├── screens/
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── image_capture_screen.dart
│   └── result_screen.dart
├── services/
│   ├── ai_service.dart
│   ├── storage_service.dart
│   └── google_drive_service.dart
├── widgets/
│   ├── capture_button.dart
│   └── classification_card.dart
├── utils/
│   └── constants.dart
└── main.dart
```

## Dependencies

- provider: ^6.1.1
- hive: ^2.2.3
- hive_flutter: ^1.1.0
- path_provider: ^2.1.1
- image_picker: ^1.0.4
- http: ^1.1.0
- google_sign_in: ^6.1.6
- googleapis: ^12.0.0
- share_plus: ^7.2.1

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini API for AI vision capabilities
- Flutter team for the amazing framework
- All contributors to the open-source packages used in this project
