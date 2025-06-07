#!/bin/bash

# Script to fix Play Store Google Sign-In issue
# Run this after updating google-services.json with Play App Signing SHA-1

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔄 Clearing Gradle cache..."
cd android
./gradlew clean
cd ..

echo "🏗️ Building release AAB..."
flutter build appbundle --release

echo "✅ Build complete! Upload the new AAB to Play Console."
echo ""
echo "📝 Important: Make sure you've added the Play App Signing SHA-1 to Firebase Console:"
echo "   1. Get SHA-1 from Play Console → App Signing"
echo "   2. Add it to Firebase Console → Project Settings → Your Android App"
echo "   3. Download new google-services.json and replace the old one"
