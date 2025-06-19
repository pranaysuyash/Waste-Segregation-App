#!/bin/bash

# 🌐 Flutter Web Verification Script
# This script verifies that the web build is working correctly

echo "🔍 Verifying Flutter Web Build..."
echo "================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in Flutter project directory"
    echo "Please run this script from the project root"
    exit 1
fi

# Check Flutter installation
echo "📱 Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

flutter --version
echo ""

# Check web support
echo "🌐 Checking Flutter web support..."
flutter config --list | grep "web" || {
    echo "❌ Flutter web is not enabled"
    echo "Run: flutter config --enable-web"
    exit 1
}
echo ""

# Clean and get dependencies
echo "🧹 Cleaning and getting dependencies..."
flutter clean
flutter pub get
echo ""

# Check critical web files
echo "📂 Checking critical web files..."
critical_files=(
    "web/index.html"
    "web/manifest.json"
    "web/favicon.png"
    "lib/firebase_options.dart"
    "lib/main.dart"
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done
echo ""

# Check index.html for proper Flutter initialization
echo "🔍 Checking index.html for proper Flutter initialization..."
if grep -q "_flutter.loader.loadEntrypoint" "web/index.html"; then
    echo "✅ Proper Flutter web initialization found"
else
    echo "❌ Flutter web initialization missing in index.html"
    echo "The index.html may not be properly configured"
fi
echo ""

# Check for Firebase configuration
echo "🔥 Checking Firebase configuration..."
if grep -q "firebase.initializeApp" "web/index.html"; then
    echo "✅ Firebase initialization found in index.html"
else
    echo "⚠️  Firebase initialization not found in index.html"
fi

if grep -q "static const FirebaseOptions web" "lib/firebase_options.dart"; then
    echo "✅ Web Firebase options configured"
else
    echo "❌ Web Firebase options missing"
fi
echo ""

# Build for web
echo "🏗️  Building for web..."
flutter build web --web-renderer auto 2>&1 | tee build_output.log

# Check build success
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Web build completed successfully"
else
    echo "❌ Web build failed"
    echo "Check build_output.log for details"
    exit 1
fi
echo ""

# Check build output files
echo "📦 Checking build output..."
build_files=(
    "build/web/index.html"
    "build/web/flutter.js"
    "build/web/main.dart.js"
    "build/web/manifest.json"
)

for file in "${build_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file generated"
    else
        echo "❌ $file missing from build"
    fi
done
echo ""

# Check main.dart.js size (should not be empty)
if [ -f "build/web/main.dart.js" ]; then
    size=$(stat -f%z "build/web/main.dart.js" 2>/dev/null || stat -c%s "build/web/main.dart.js" 2>/dev/null)
    if [ "$size" -gt 10000 ]; then
        echo "✅ main.dart.js has reasonable size ($size bytes)"
    else
        echo "⚠️  main.dart.js seems too small ($size bytes)"
    fi
fi
echo ""

# Suggest testing steps
echo "🚀 Next Steps:"
echo "=============="
echo "1. Test locally:"
echo "   flutter run -d chrome"
echo ""
echo "2. Or serve the build directory:"
echo "   cd build/web"
echo "   python -m http.server 8000"
echo "   # Then open http://localhost:8000"
echo ""
echo "3. Check browser console for:"
echo "   - 'Firebase initialized successfully'"
echo "   - No JavaScript errors"
echo "   - Proper app loading"
echo ""
echo "4. Verify features work:"
echo "   - Navigation"
echo "   - Firebase authentication"
echo "   - Data storage"
echo "   - Image classification (with browser permissions)"

# Clean up
rm -f build_output.log

echo ""
echo "🎉 Verification complete!"
echo "If all checks passed, your web app should work correctly."
