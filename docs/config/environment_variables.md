# Environment Variables Configuration

## Overview

The Waste Segregation App utilizes a `.env` file to manage sensitive information like API keys and other environment-specific configurations. This approach enhances security by keeping secrets out of the version-controlled codebase and allows for different configurations across various environments (e.g., development, staging, production).

## .env File

- **Location**: The `.env` file should be placed in the root directory of the project.
- **Security**: This file **must not** be committed to version control. It is included in the `.gitignore` file to prevent accidental commits.
- **Purpose**: To store API keys, model names, and other configuration variables that might change between environments or should be kept secret.

### Example `.env` File Structure (`.env.example`)

An example file, typically named `.env.example`, should be committed to the repository to show the required variables. Users will copy this to `.env` and fill in their actual values.

```env
# API Keys for Waste Segregation App
OPENAI_API_KEY=your-actual-openai-api-key
GEMINI_API_KEY=your-actual-gemini-api-key

# Model Configuration
PRIMARY_MODEL=gpt-4.1-nano
SECONDARY_MODEL_1=gpt-4o-mini
SECONDARY_MODEL_2=gpt-4.1-mini
TERTIARY_MODEL=gemini-2.0-flash

# Firebase Configuration (if needed)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_API_KEY=your-firebase-api-key

# App Configuration
APP_ENV=development # or production, staging
DEBUG_MODE=true # or false
# ... other app-specific flags
```

**(Note: The example above shows placeholder values. The actual `.env` file will contain real keys.)**

## Accessing Environment Variables in Code

Environment variables are accessed in the Dart code, primarily within `lib/utils/constants.dart`, using the `String.fromEnvironment()` constructor.

**Mechanism**:
- Flutter allows passing compile-time environment variables using the `--dart-define` flag during the build process (e.g., `flutter run --dart-define=OPENAI_API_KEY=YOUR_KEY`).
- For local development, a common practice (though not directly supported by `String.fromEnvironment` out-of-the-box without build runner or similar tools for `.env` parsing) is to manage these in the `.env` and ensure your IDE or run configurations pass these defines.
- Alternatively, packages like `flutter_dotenv` can be used to load `.env` files at runtime, but the current implementation relies on `String.fromEnvironment` with default values for direct compilation.

### Example from `lib/utils/constants.dart`:

```dart
class ApiConfig {
  // OpenAI API Configuration
  static const String openAiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'your-openai-api-key-here' // Fallback/placeholder if not defined
  );

  // Gemini API Configuration
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'your-gemini-api-key-here' // Fallback/placeholder
  );

  // Model Names
  static const String primaryModel = String.fromEnvironment(
    'PRIMARY_MODEL',
    defaultValue: 'gpt-4.1-nano'
  );
  static const String secondaryModel1 = String.fromEnvironment(
    'SECONDARY_MODEL_1',
    defaultValue: 'gpt-4o-mini'
  );
  static const String secondaryModel2 = String.fromEnvironment(
    'SECONDARY_MODEL_2',
    defaultValue: 'gpt-4.1-mini'
  );
  static const String tertiaryModel = String.fromEnvironment(
    'TERTIARY_MODEL',
    defaultValue: 'gemini-2.0-flash' // Gemini model as the 4th option
  );
}
```

## Setup for New Developers

1.  **Copy `.env.example`**: If `.env.example` exists, copy it to a new file named `.env` in the project root.
    ```bash
    cp .env.example .env
    ```
    If `.env.example` does not exist, create `.env` manually based on the required structure.
2.  **Fill in Values**: Open `.env` and replace the placeholder values with actual API keys and desired configurations.
3.  **Build/Run with Defines (Recommended for Production/CI)**: When building for release or in CI/CD pipelines, pass the variables using `--dart-define`:
    ```bash
    flutter build apk --dart-define=OPENAI_API_KEY=YOUR_ACTUAL_KEY --dart-define=GEMINI_API_KEY=YOUR_ACTUAL_GEMINI_KEY
    # Add other --dart-define flags as needed for all variables in .env
    ```
4.  **Local Development**: For local development, ensure your `.env` file is populated. If `String.fromEnvironment` does not pick these up directly (which is typical without a build_runner setup for this), you might rely on the default values in `constants.dart` for initial runs, or ensure your IDE can pass these as dart-defines (e.g., in VS Code `launch.json` or Android Studio run configurations).

    *Self-correction during generation: The current setup with `String.fromEnvironment` and a `.env` file implies that either a build tool processes the `.env` into `--dart-define` flags, or developers manually provide these flags or rely on defaults. For true `.env` loading at runtime without manual `dart-define`, a package like `flutter_dotenv` would be used. The documentation should clarify the current expectation based on the existing code.* 

    **Clarification based on current code**: The `lib/utils/constants.dart` uses `String.fromEnvironment` with default values. This means that if `--dart-define` is not used during compilation, the `defaultValue` will be used. The `.env` file serves as a secure place for developers to store these keys for their reference and to *manually* use them when creating `--dart-define` flags or configuring their IDE's build process.

## Security Benefits

- **Prevents Accidental Commits of Secrets**: By keeping keys in `.env` (which is gitignored), the risk of exposing them in the codebase is significantly reduced.
- **Environment-Specific Configuration**: Allows easy switching of API endpoints, keys, or feature flags for different build environments.

This system is crucial for maintaining a secure and flexible development workflow. 