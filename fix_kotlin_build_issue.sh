#!/bin/bash

# Fix Kotlin Compatibility Issue for Production Builds
# This script resolves the critical PMF blocker preventing app deployment
# Uses last known good configuration (Kotlin 1.9.10, Firebase BOM 32.8.0, AGP 8.5.0)

echo "🔧 Fixing Kotlin compatibility issue for production builds..."

# Step 1: Clean all caches
echo "📦 Cleaning build caches..."
flutter clean
rm -rf android/.gradle
rm -rf ~/.gradle/caches/transforms-3
rm -rf android/app/build

# Step 2: Update Kotlin version to last known good
echo "🔄 Setting Kotlin to version 1.9.10..."
sed -i '' 's/ext.kotlin_version = .*/ext.kotlin_version = '\''1.9.10'\''/g' android/build.gradle

# Step 3: Update Firebase BOM to last known good
echo "🔥 Setting Firebase BOM to version 32.8.0..."
sed -i '' 's/firebase-bom:[0-9.]*/firebase-bom:32.8.0/g' android/app/build.gradle

# Step 4: Update Android Gradle Plugin to stable version (8.5.0)
echo "🤖 Setting Android Gradle Plugin to stable version 8.5.0..."
sed -i '' 's/com.android.tools.build:gradle:[0-9.]*/com.android.tools.build:gradle:8.5.0/g' android/build.gradle

# Step 5: Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Step 6: Test build
echo "🏗️ Testing release build..."
flutter build apk --release --target-platform android-arm64

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS: Production build completed! (May have Kotlin metadata warnings)"
    echo "📱 APK location: build/app/outputs/flutter-apk/"
    echo "🚀 App is now ready for deployment with thorough testing!"
    echo "⚠️ IMPORTANT: Test all Firebase/Play Services functionality due to Kotlin metadata warnings."
else
    echo "❌ Build failed. Check the error messages above."
    echo "💡 Try running: flutter doctor -v"
fi

echo "🎉 Kotlin compatibility fix attempt completed!" 