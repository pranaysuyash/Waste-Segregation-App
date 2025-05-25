# Environment Setup Guide

This guide explains how to set up environment variables for the Waste Segregation App, including API keys and configuration options.

## Overview

The app uses environment variables to securely manage API keys and configuration settings. We use Flutter's built-in `--dart-define-from-file` feature to load these variables from a `.env` file during development.

## Required Environment Variables

### API Keys

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `OPENAI_API_KEY` | OpenAI API key for primary AI classification | Yes | `sk-proj-...` |
| `GEMINI_API_KEY` | Google Gemini API key for fallback classification | Yes | `AIzaSy...` |

### Model Configuration

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `OPENAI_API_MODEL_PRIMARY` | Primary OpenAI model | `gpt-4.1-nano` | Any OpenAI model |
| `OPENAI_API_MODEL_SECONDARY` | Secondary OpenAI model (fallback) | `gpt-4o-mini` | Any OpenAI model |
| `OPENAI_API_MODEL_TERTIARY` | Tertiary OpenAI model (fallback) | `gpt-4.1-mini` | Any OpenAI model |
| `GEMINI_API_MODEL` | Gemini model for final fallback | `gemini-2.0-flash` | Any Gemini model |

## Setup Instructions

### 1. Create .env File

Create a `.env` file in the project root with your API keys:

```bash
# API Keys for Waste Segregation App
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here

# Model Configuration
OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano
OPENAI_API_MODEL_SECONDARY=gpt-4o-mini
OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini
GEMINI_API_MODEL=gemini-2.0-flash

# App Configuration (Optional)
APP_ENV=development
DEBUG_MODE=true
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true

# Storage Configuration (Optional)
MAX_CACHE_SIZE=200
CACHE_DURATION_HOURS=24

# Feature Flags (Optional)
ENABLE_OFFLINE_MODE=true
ENABLE_PREMIUM_FEATURES=false
ENABLE_FAMILY_FEATURES=true
ENABLE_GAMIFICATION=true
```

### 2. Obtain API Keys

#### OpenAI API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign in or create an account
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (starts with `sk-proj-` or `sk-`)

#### Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Create a new API key
4. Copy the key (starts with `AIzaSy`)

### 3. Security Considerations

- **Never commit `.env` files to version control**
- The `.env` file is already added to `.gitignore`
- Use different API keys for development and production
- Regularly rotate your API keys
- Monitor API usage and set billing alerts

## Running the App

### Option 1: Direct Flutter Run (Simplest)

Flutter can directly load your `.env` file:

```bash
flutter run --dart-define-from-file=.env
```

### Option 2: Using the Run Script (Recommended for validation)

We provide a convenient shell script that validates your `.env` file and runs the app:

```bash
./run_with_env.sh
```

This script will:
- Check if `.env` file exists
- Validate required API keys
- Run Flutter with the `.env` file loaded

### Option 3: Manual Flutter Run with Individual Variables

You can also run the app manually with individual environment variables:

```bash
flutter run \
  --dart-define=OPENAI_API_KEY="your_key_here" \
  --dart-define=GEMINI_API_KEY="your_key_here" \
  --dart-define=OPENAI_API_MODEL_PRIMARY="gpt-4.1-nano" \
  --dart-define=OPENAI_API_MODEL_SECONDARY="gpt-4o-mini" \
  --dart-define=OPENAI_API_MODEL_TERTIARY="gpt-4.1-mini" \
  --dart-define=GEMINI_API_MODEL="gemini-2.0-flash"
```

### Option 4: VS Code Integration

If you're using VS Code, the project includes launch configurations that automatically load environment variables from `.env`:

1. Open the project in VS Code
2. Go to Run and Debug (Ctrl+Shift+D)
3. Select one of the available configurations:
   - `waste_segregation_app` (Default)
   - `waste_segregation_app (Debug)`
   - `waste_segregation_app (Profile)`
   - `waste_segregation_app (Release)`
4. Press F5 or click the play button

### Option 5: Android Studio/IntelliJ

For Android Studio or IntelliJ IDEA:

1. Go to **Run** → **Edit Configurations...**
2. Select your Flutter app configuration
3. In **Additional run args**, add:
   ```
   --dart-define-from-file=.env
   ```

   Or for individual variables:
   ```
   --dart-define=OPENAI_API_KEY=your_key_here --dart-define=GEMINI_API_KEY=your_key_here --dart-define=OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano --dart-define=OPENAI_API_MODEL_SECONDARY=gpt-4o-mini --dart-define=OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini --dart-define=GEMINI_API_MODEL=gemini-2.0-flash
   ```
4. Replace `your_key_here` with your actual API keys

## Troubleshooting

### Common Issues

#### "Incorrect API key provided" Error
- Verify your API keys are correct in the `.env` file
- Ensure there are no extra spaces or newlines in the keys
- Check that the keys haven't expired

#### "Failed to load .env file" Warning
- This is normal if you're using `--dart-define` flags instead
- The app will fall back to default placeholder values
- Ensure your `.env` file is in the project root

#### Environment Variables Not Loading
- Make sure you're using one of the recommended run methods
- Verify the `.env` file is properly formatted
- Check that the file is named exactly `.env` (not `.env.txt`)

#### Firebase/Firestore Permission Errors
- Enable Cloud Firestore API in Google Cloud Console
- Set up proper security rules for your Firebase project
- Ensure your Firebase configuration is correct

### Debug Mode

To enable debug logging for environment variables, add this to your `.env`:

```bash
DEBUG_MODE=true
```

This will print environment variable loading status to the console.

## Production Deployment

For production builds, you should:

1. Use a separate set of API keys
2. Set up proper CI/CD environment variables
3. Use `--dart-define` flags in your build scripts
4. Never include `.env` files in production builds

### Production Build Commands:

**Option 1: Using environment variables from CI/CD:**
```bash
flutter build apk --release \
  --dart-define=OPENAI_API_KEY="$PROD_OPENAI_KEY" \
  --dart-define=GEMINI_API_KEY="$PROD_GEMINI_KEY" \
  --dart-define=OPENAI_API_MODEL_PRIMARY="gpt-4.1-nano" \
  --dart-define=OPENAI_API_MODEL_SECONDARY="gpt-4o-mini" \
  --dart-define=OPENAI_API_MODEL_TERTIARY="gpt-4.1-mini" \
  --dart-define=GEMINI_API_MODEL="gemini-2.0-flash"
```

**Option 2: Using a production .env file (if available):**
```bash
flutter build apk --release --dart-define-from-file=.env.production
```

**Option 3: iOS App Store:**
```bash
flutter build ios --release \
  --dart-define=OPENAI_API_KEY="$PROD_OPENAI_KEY" \
  --dart-define=GEMINI_API_KEY="$PROD_GEMINI_KEY" \
  --dart-define=OPENAI_API_MODEL_PRIMARY="gpt-4.1-nano" \
  --dart-define=OPENAI_API_MODEL_SECONDARY="gpt-4o-mini" \
  --dart-define=OPENAI_API_MODEL_TERTIARY="gpt-4.1-mini" \
  --dart-define=GEMINI_API_MODEL="gemini-2.0-flash"
```

## Related Documentation

- [API Documentation](../reference/api_documentation/README.md)
- [AI Classification System](../ai_classification_system.md)
- [Deployment Guide](../technical/deployment/README.md)
- [Security Best Practices](../technical/security/README.md) 