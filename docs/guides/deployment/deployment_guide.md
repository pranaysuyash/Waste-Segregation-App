# Waste Segregation App: Deployment & Infrastructure Guide

## Overview

This comprehensive deployment guide covers all aspects of deploying the Waste Segregation App to production environments, including mobile app stores, web platforms, and cloud infrastructure management.

## Table of Contents

1. [Pre-deployment Preparation](#pre-deployment-preparation)
2. [Mobile App Deployment](#mobile-app-deployment)
3. [Web Platform Deployment](#web-platform-deployment)
4. [Cloud Infrastructure Setup](#cloud-infrastructure-setup)
5. [CI/CD Pipeline Configuration](#cicd-pipeline-configuration)
6. [Monitoring and Analytics](#monitoring-and-analytics)
7. [Security Configuration](#security-configuration)
8. [Performance Optimization](#performance-optimization)
9. [Rollback Procedures](#rollback-procedures)
10. [Maintenance and Updates](#maintenance-and-updates)

## Pre-deployment Preparation

### Environment Configuration

#### 1. Environment Variables Setup
```bash
# Production environment variables
FLUTTER_ENV=production
GEMINI_API_KEY=prod_gemini_key_here
OPENAI_API_KEY=prod_openai_key_here
FIREBASE_PROJECT_ID=waste-app-prod

# Feature flags
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
ENABLE_PERFORMANCE_MONITORING=true

# App configuration
APP_VERSION=1.0.0
BUILD_NUMBER=1
MINIMUM_SUPPORTED_VERSION=1.0.0
```

### Pre-deployment Code Review
- [ ] All tests passing (unit, widget, integration)
- [ ] Code coverage >= 80%
- [ ] No critical security vulnerabilities
- [ ] Performance benchmarks met
- [ ] Accessibility guidelines followed
- [ ] Internationalization complete
- [ ] Documentation updated

## Mobile App Deployment

### Android Deployment

#### 1. App Signing Configuration
```bash
# Generate production keystore
keytool -genkey -v -keystore production-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias production-key
```

#### 2. Play Store Deployment
```bash
# Build App Bundle
flutter build appbundle --release

# Upload to Play Console
# 1. Go to Google Play Console
# 2. Create app listing
# 3. Upload AAB file
# 4. Configure store listing
# 5. Submit for review
```

### iOS Deployment

#### 1. Build and Archive
```bash
# Build iOS release
flutter build ios --release

# Or use Xcode:
# Product > Archive
# Upload to App Store Connect
```

## Web Platform Deployment

### Static Site Deployment

#### 1. Build Web Version
```bash
# Build optimized web version
flutter build web --release --web-renderer html
```

#### 2. Firebase Hosting
```bash
# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Cloud Infrastructure Setup

### Firebase Configuration

#### 1. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## CI/CD Pipeline Configuration

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
    - name: Run tests
      run: flutter test --coverage
```

## Monitoring and Analytics

### Application Monitoring

```dart
class AnalyticsService {
  static Future<void> logClassification({
    required String category,
    required double confidence,
  }) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'waste_classified',
      parameters: {
        'category': category,
        'confidence': confidence,
      },
    );
  }
}
```

## Security Configuration

### Production Security

```dart
class SecurityConfig {
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && 
           key.length >= 32 && 
           !key.contains('test');
  }
}
```

## Performance Optimization

### Production Performance

```dart
class ProductionImageProcessor {
  static Future<File> optimizeForClassification(File originalFile) async {
    final image = img.decodeImage(await originalFile.readAsBytes());
    if (image == null) throw Exception('Invalid image format');
    
    final optimized = img.copyResize(image, width: 512, height: 512);
    final compressed = img.encodeJpg(optimized, quality: 85);
    
    final tempDir = await getTemporaryDirectory();
    final optimizedFile = File('${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await optimizedFile.writeAsBytes(compressed);
    
    return optimizedFile;
  }
}
```

## Rollback Procedures

### Emergency Rollback Plan

```bash
#!/bin/bash
# rollback_web.sh
echo "Starting web platform rollback..."
PREVIOUS_DEPLOYMENT=$(firebase hosting:versions --limit 2 --json | jq -r '.[1].name')
firebase hosting:clone $PREVIOUS_DEPLOYMENT
echo "Web platform rollback completed"
```

## Maintenance and Updates

### Regular Maintenance Tasks

```dart
class MonthlyMaintenance {
  static Future<void> performMaintenance() async {
    await _updateAnalyticsReports();
    await _optimizeDatabase();
    await _reviewSecurityLogs();
  }
}
```

## Deployment Checklist

### Pre-Deployment Checklist
- [ ] All tests passing
- [ ] Security scan completed
- [ ] Performance benchmarks met
- [ ] API keys configured
- [ ] App store metadata prepared

### Post-Deployment Checklist
- [ ] App successfully deployed
- [ ] Analytics active
- [ ] Performance monitoring active
- [ ] Team notified

This deployment guide provides the foundation for reliable production deployment of the Waste Segregation App.