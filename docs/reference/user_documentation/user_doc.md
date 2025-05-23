# Waste Segregation App - Technical Documentation

> **NOTE:** The canonical, comprehensive user guide is [`user_documentation.md`](./user_documentation.md). This file is a quick technical reference for developers or advanced users who want a summary of the system architecture and models.

## Project Overview

The Waste Segregation App is a Flutter-based application designed to educate users about proper waste segregation using AI technology. It classifies waste images into detailed categories and provides educational content and gamification to motivate users.

## System Architecture

### Technology Stack

- Flutter for cross-platform mobile and web
- Provider for state management
- Hive database for local data persistence
- Google Gemini Vision API (OpenAI-compatible) for AI classification
- Google Sign-In for authentication
- Google Drive API for optional cloud sync

### Directory Structure (Key folders)

```
lib/
├── main.dart             # App entry point
├── models/               # Core data models
│   ├── waste_classification.dart     # Waste categories and classification
│   ├── educational_content.dart      # Articles, videos, quizzes, tutorials
│   ├── gamification.dart             # User achievements, challenges, points
├── screens/              # UI screens (home, camera, results, quizzes, leaderboard)
├── services/             # Business logic (AI, gamification, storage, sync)
├── utils/                # Utilities and platform-specific helpers
└── widgets/              # Reusable UI components
```

## Core Models

### WasteClassification

- Represents classified waste items with fields for item name, category, subcategory, material type, recycling code, explanation, disposal method, and flags for recyclability and compostability.
- Includes enums for categories (wet, dry, hazardous, medical, non-waste) and detailed subcategories.
- Provides JSON serialization and extensions for readable names and color coding.

### EducationalContent

- Supports various content types: articles, videos, infographics, quizzes, tutorials, and tips.
- Contains metadata fields such as title, description, categories, difficulty level, and premiums.
- Supports structured quiz questions and tutorial steps.
- Helper methods for UI display properties like content type colors and formatted durations.

### Gamification

- Models achievements (badges), streaks, user points, challenges, and weekly statistics.
- Achievements track progress towards goals with earned timestamps.
- Challenges provide time-limited tasks with requirements and progress.
- UserPoints track total and category-specific points along with user level and rank.
- WeeklyStats store leaderboard data.
- GamificationProfile consolidates user gamification data for persistence.

## Services Overview

### AI Service

- Integrates Google Gemini Vision API for classifying waste in images with advanced prompting.
- Supports image classification on mobile and web, including segmentation-based analysis.
- Uses exponential backoff retries and fallback to OpenAI API if needed for robustness.
- Parses structured JSON responses from AI to construct WasteClassification objects.

### Gamification Service

- Handles gamification data lifecycle, including local storage in Hive.
- Tracks and updates user streaks, awards points for actions like classifying waste and completing challenges.
- Manages achievements and dynamic challenges.
- Maintains weekly statistics for leaderboards.
