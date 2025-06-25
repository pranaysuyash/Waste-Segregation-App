# Environment Variables Security Setup

**Date**: June 24, 2025  
**Purpose**: Secure Firebase API key management using environment variables  
**Status**: ✅ IMPLEMENTED

## 📋 Overview

This document outlines the secure management of Firebase API keys and other sensitive configuration using environment variables instead of hardcoded values.

## 🔧 Setup Instructions

### 1. Environment File Setup

**Create `.env` file** (if not exists):
```bash
cp firebase.env.template .env
```

**Edit `.env` with your actual values**:
```bash
# Firebase Configuration
FIREBASE_ANDROID_API_KEY=your_actual_android_key_here
FIREBASE_IOS_API_KEY=your_actual_ios_key_here
FIREBASE_WEB_API_KEY=your_actual_web_key_here
# ... etc
```

### 2. Running the App

**Development**:
```bash
flutter run --dart-define-from-file=.env
```

**Build**:
```bash
flutter build apk --dart-define-from-file=.env
flutter build ios --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
```

### 3. VS Code Configuration

Add to `.vscode/launch.json`:
```json
{
  "configurations": [
    {
      "name": "waste_segregation_app",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define-from-file=.env"]
    }
  ]
}
```

## 🔍 Finding Firebase API Keys

### Firebase Console Locations:

1. **Web App Keys**: 
   - Go to: https://console.firebase.google.com/project/waste-segregation-app-df523/settings/general/web
   - Click your web app → Copy config

2. **Android App Keys**:
   - Go to: https://console.firebase.google.com/project/waste-segregation-app-df523/settings/general/android
   - Click your Android app → Copy config

3. **iOS App Keys**:
   - Go to: https://console.firebase.google.com/project/waste-segregation-app-df523/settings/general/ios
   - Click your iOS app → Copy config

### Regenerating Keys:

**Via Firebase Console**:
1. Go to Project Settings → General
2. Click on your app (Web/Android/iOS)
3. Click Settings gear icon → "Regenerate API key"

**Via Firebase CLI**:
```bash
# Create new apps (generates new keys)
firebase apps:create ANDROID 'WasteWise Android New' --package-name com.pranaysuyash.wastewise
firebase apps:create IOS 'WasteSegregation iOS New' --bundle-id com.example.wasteSegregationApp
firebase apps:create WEB 'WasteSegregation Web New'

# Get new configurations
firebase apps:sdkconfig ANDROID [new-android-app-id]
firebase apps:sdkconfig IOS [new-ios-app-id]
firebase apps:sdkconfig WEB [new-web-app-id]
```

## 🛡️ Security Features

### 1. Git Pre-commit Hook
- **Location**: `.git/hooks/pre-commit`
- **Purpose**: Prevents committing sensitive data
- **Checks for**:
  - Firebase API keys (AIzaSy pattern)
  - OpenAI API keys (sk- pattern)
  - Private keys
  - Password/secret/token patterns
  - .env file commits

### 2. .gitignore Protection
- `.env` file is ignored
- Firebase config files are protected
- Sensitive directories excluded

### 3. Environment Variable Validation
The app validates that all required environment variables are present at startup.

## 🚨 Security Best Practices

### DO:
- ✅ Use environment variables for all sensitive data
- ✅ Keep `.env` file local only (never commit)
- ✅ Regenerate keys if they've been exposed
- ✅ Add API restrictions in Firebase Console
- ✅ Use different keys for development/production
- ✅ Regular security audits

### DON'T:
- ❌ Hardcode API keys in source code
- ❌ Commit `.env` files to version control
- ❌ Share API keys in documentation
- ❌ Use production keys in development
- ❌ Ignore security warnings from git hooks

## 🔧 Troubleshooting

### Issue: Environment variables not loaded
**Solution**: Ensure you're using `--dart-define-from-file=.env` flag

### Issue: Git hook blocking valid commits
**Solution**: Check for accidentally included sensitive data, or use `git commit --no-verify` (NOT RECOMMENDED)

### Issue: Firebase authentication errors
**Solution**: Verify all environment variables are set correctly in `.env`

## 📚 Related Files

- `firebase.env.template` - Template for environment variables
- `.env` - Your actual environment variables (local only)
- `lib/firebase_options.dart` - Updated to use environment variables
- `.git/hooks/pre-commit` - Security validation hook
- `.gitignore` - Protects sensitive files

## 🔄 Migration from Hardcoded Keys

If migrating from hardcoded keys:

1. **Backup current configuration**
2. **Create `.env` file** with current values
3. **Update `firebase_options.dart`** to use environment variables
4. **Test thoroughly** with new setup
5. **Regenerate keys** for additional security
6. **Update documentation** and team procedures

---

**⚠️ SECURITY REMINDER**: This setup prevents accidental exposure of API keys. However, always follow the principle of least privilege and regularly audit your security practices. 