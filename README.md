# Waste Segregation App

A comprehensive Flutter application for proper waste identification, segregation guidance, and environmental education, enhanced with world-class recycling research and AI-powered material recognition.

## 🌟 **Latest Achievement: World's Most Comprehensive Recycling Research**

**🔬 Research Milestone**: Completed the world's most comprehensive recycling codes and material identification research, synthesizing knowledge from 9 leading AI systems across 175+ authoritative sources covering 70+ countries and regions.

**📖 Documentation**: [`docs/technical/comprehensive_recycling_codes_research.md`](docs/technical/comprehensive_recycling_codes_research.md)

**🎯 Impact**: This research transforms our app into the definitive global authority on proper waste disposal, environmental education, and sustainable material management.

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
  - Animated rewards with immediate visual feedback
  - Enhanced achievement notifications
  - Challenge completion celebrations

- **Data Management**:
  - Local storage of classifications and user preferences
  - Optional sync to Google Drive for cross-device access
  - History of previously identified items
  - Personal waste analytics dashboard
  - Waste composition trends and insights

## Accessibility & Color Contrast
- All screens have been updated for improved color contrast and text visibility.
- The app now meets accessibility standards for color contrast in both light and dark themes.

## Technical Implementation

- **Framework**: Flutter
- **State Management**: Provider
- **Local Storage**: Hive
- **Backend Services**: Firebase for authentication
- **Image Handling**: image_picker package
- **AI Integration**: Gemini API via OpenAI-compatible endpoint using the gemini-2.0-flash model
- **Google Integration**: google_sign_in package with Firebase authentication
- **Data Visualization**: fl_chart package for waste analytics

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
   flutter run --dart-define-from-file=.env
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
│   ├── waste_dashboard_screen.dart
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
│   ├── gamification_widgets.dart
│   ├── enhanced_gamification_widgets.dart
│   └── waste_chart_widgets.dart
├── utils/
│   ├── constants.dart
│   └── animation_helpers.dart
└── main.dart
```

## Current Status

### App Store Status

- ✅ Google Play Developer Account created
- ✅ App bundle uploaded to Google Play Console (May 2025)
- ⏳ Waiting for Google Play review and approval
- ❌ Apple App Store submission (not started)

### Implemented Features
- AI integration with Gemini Vision API
- Waste classification with detailed categories
- Basic image capture and upload functionality
- Core UI screens (home, auth, image capture, results)
- Educational content framework
- Comprehensive gamification system (points, achievements, challenges)
- Enhanced gamification with immediate visual feedback
- Animated rewards and achievement notifications
- Personal waste analytics dashboard with visualizations
- Local storage with Hive
- Google Sign-In
- Thumbnail generation and storage for classifications (local image caching)
- Device-local SHA-256 based image classification caching system
- Cache statistics monitoring and visualization

### In Progress / Pending
- Leaderboard implementation
- Enhanced camera features
- Quiz functionality completion
- Social sharing capabilities
- Enhanced web camera support
- Cross-user classification caching with Firestore (planned)
- UI Refactoring & Modularization (breaking screens into reusable widgets)

## Documentation

For comprehensive documentation including setup guides, technical details, and project status:

- **[📖 Documentation Hub](docs/README.md)** - Main documentation index
- **[🚀 Quick Start Guide](docs/guides/developer_guide.md)** - Development setup instructions
- **[📊 Project Status](docs/project/status.md)** - Current development status
- **[🔧 Technical Documentation](docs/technical/README.md)** - Recent fixes and technical details
- **[📋 Resolution Plan](docs/planning/RESOLUTION_PLAN.md)** - Priority issues and fixes
- **[🗺️ Project Roadmap](docs/planning/roadmap/unified_project_roadmap.md)** - Development roadmap and timeline
- **[❓ Troubleshooting](docs/reference/troubleshooting.md)** - Common issues and solutions

## Current Project Status

**Version:** 0.1.4+96 (Current Deployed Release)  
**Play Store Version:** 0.1.5+97 (Reserved for Google Play Store)  
**Status:** ✅ Ready for Production  
**Latest Changes:** Critical UI fixes applied - AdWidget errors resolved, overflow warnings fixed, modal dialogs improved

### Recent Critical Fixes ✅
- **History Duplication Fix:** Fixed issue where scanning one item created two history entries due to duplicate save operations in result screen
- **User Data Isolation:** Fixed privacy issue where guest and Google account data was shared on same device
- **ViewAllButton Styling:** Fixed invisible text in "View All" button for recent classifications
- **AdWidget "Already in Tree" Error:** Fixed ad widget reuse causing development errors
- **Layout Overflow Warnings:** Resolved overflow issues in History screen and modal dialogs  
- **Version Management:** Fixed Play Store version code conflicts
- **Modal Responsiveness:** Added height constraints and scrolling for better UX on small screens

### Build Status
- **Android App Bundle:** Ready for Play Store deployment
- **Play Store Version:** 0.1.5+97 reserved for Google Play Store submission
- **Version Code:** Dynamically managed from pubspec.yaml
- **UI Issues:** All critical overflow and widget tree errors resolved

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
- fl_chart: ^0.65.0
- intl: ^0.19.0

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini API for AI vision capabilities through the OpenAI-compatible endpoint
- Flutter team for the amazing framework
- All contributors to the open-source packages used in this project

## Versioning and Play Store Issue (May 2025)
- The app now uses 0.1.x versioning for public/internal releases. Latest: 0.1.2+94.
- Google Play App Signing SHA-1 is now added to Firebase for internal testing compatibility.
- See CHANGELOG.md and docs/current_issues.md for details.

## 🚀 Quick Start

### Development & Testing

Choose the method that works best for you:

#### Option 1: Simple Development Run
```bash
# Loads your .env file automatically
flutter run --dart-define-from-file=.env
```

#### Option 2: Validated Run (Recommended)
```bash
# Validates .env file and runs with error checking
./run_with_env.sh
```

#### Option 3: Plain Flutter Run
```bash
# Uses default placeholder API keys (will show "incorrect API key" errors)
flutter run
```

#### Option 4: VS Code
- Press `F5` or use Run & Debug panel
- Automatically loads `.env` file

### Production Builds

#### Android APK
```bash
# Set production environment variables first
export PROD_OPENAI_API_KEY="your_production_key"
export PROD_GEMINI_API_KEY="your_production_key"

# Build for production
./build_production.sh apk
```

#### Android App Bundle (Play Store)
```bash
./build_production.sh aab
```

#### iOS (App Store)
```bash
./build_production.sh ios
```

## 📋 Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
2. **API Keys** in `.env` file:
   ```bash
   OPENAI_API_KEY=your_openai_api_key_here
   GEMINI_API_KEY=your_gemini_api_key_here
   OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano
   OPENAI_API_MODEL_SECONDARY=gpt-4o-mini
   OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini
   GEMINI_API_MODEL=gemini-2.0-flash
   ```
3. **Firebase Project** with Firestore enabled

## 🔧 Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd waste_segregation_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create .env file** (see Prerequisites above)

4. **Enable Firestore API**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Cloud Firestore API for your project

5. **Run the app**
   ```bash
   ./run_with_env.sh
   ```

## 📖 Documentation

- [Environment Setup Guide](docs/config/environment_setup.md)
- [API Documentation](docs/reference/api_documentation/)
- [Architecture Overview](docs/technical/architecture/)
- [Testing Guide](docs/testing/)

## 🎯 Features

- **AI-Powered Classification**: Uses OpenAI and Gemini APIs for accurate waste identification
- **Multi-Category Support**: Wet waste, dry waste, hazardous waste, medical waste, and non-waste
- **Gamification**: Points, achievements, challenges, and leaderboards
- **Family Features**: Share progress with family members
- **Offline Support**: Works without internet connection
- **Educational Content**: Learn about proper waste disposal
- **Analytics**: Track your waste segregation habits

## 🏗️ Architecture

The app follows a clean architecture pattern with:
- **Provider** for state management
- **Hive** for local storage
- **Firebase** for cloud sync and analytics
- **Modular services** for different functionalities

## 🧪 Testing

Run tests with:
```bash
flutter test
```

For widget tests with golden files:
```bash
flutter test --update-goldens
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (iOS 12+)
- 🚧 Web (limited functionality)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Check the [documentation](docs/)
- Open an issue on GitHub
- Contact the development team

---

**Made with ❤️ for a cleaner environment**