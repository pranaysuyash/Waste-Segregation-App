#!/bin/bash

# Waste Segregation App - Production Build Script
# This script builds the app for production with environment variables

set -e  # Exit on any error

echo "🏗️  Building Waste Segregation App for Production..."

# Check if production environment variables are set
if [ -z "$PROD_OPENAI_API_KEY" ] || [ -z "$PROD_GEMINI_API_KEY" ]; then
    echo "❌ Error: Production API keys not set!"
    echo "Please set the following environment variables:"
    echo "  export PROD_OPENAI_API_KEY='your_production_openai_key'"
    echo "  export PROD_GEMINI_API_KEY='your_production_gemini_key'"
    echo ""
    echo "Or create a .env.production file with:"
    echo "  OPENAI_API_KEY=your_production_openai_key"
    echo "  GEMINI_API_KEY=your_production_gemini_key"
    echo "  OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano"
    echo "  OPENAI_API_MODEL_SECONDARY=gpt-4o-mini"
    echo "  OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini"
    echo "  GEMINI_API_MODEL=gemini-2.0-flash"
    echo ""
    echo "Then run: flutter build apk --release --dart-define-from-file=.env.production"
    exit 1
fi

# Set default models if not provided
PROD_OPENAI_MODEL_PRIMARY=${PROD_OPENAI_MODEL_PRIMARY:-"gpt-4.1-nano"}
PROD_OPENAI_MODEL_SECONDARY=${PROD_OPENAI_MODEL_SECONDARY:-"gpt-4o-mini"}
PROD_OPENAI_MODEL_TERTIARY=${PROD_OPENAI_MODEL_TERTIARY:-"gpt-4.1-mini"}
PROD_GEMINI_MODEL=${PROD_GEMINI_MODEL:-"gemini-2.0-flash"}

echo "✅ Production environment variables validated"
echo "🔧 Using models:"
echo "  Primary: $PROD_OPENAI_MODEL_PRIMARY"
echo "  Secondary: $PROD_OPENAI_MODEL_SECONDARY"
echo "  Tertiary: $PROD_OPENAI_MODEL_TERTIARY"
echo "  Gemini: $PROD_GEMINI_MODEL"

# Determine build type
BUILD_TYPE=${1:-"apk"}

case $BUILD_TYPE in
    "apk")
        echo "📱 Building Android APK..."
        flutter build apk --release \
          --dart-define=OPENAI_API_KEY="$PROD_OPENAI_API_KEY" \
          --dart-define=GEMINI_API_KEY="$PROD_GEMINI_API_KEY" \
          --dart-define=OPENAI_API_MODEL_PRIMARY="$PROD_OPENAI_MODEL_PRIMARY" \
          --dart-define=OPENAI_API_MODEL_SECONDARY="$PROD_OPENAI_MODEL_SECONDARY" \
          --dart-define=OPENAI_API_MODEL_TERTIARY="$PROD_OPENAI_MODEL_TERTIARY" \
          --dart-define=GEMINI_API_MODEL="$PROD_GEMINI_MODEL"
        echo "✅ APK built successfully: build/app/outputs/flutter-apk/app-release.apk"
        ;;
    "aab")
        echo "📱 Building Android App Bundle..."
        flutter build appbundle --release \
          --dart-define=OPENAI_API_KEY="$PROD_OPENAI_API_KEY" \
          --dart-define=GEMINI_API_KEY="$PROD_GEMINI_API_KEY" \
          --dart-define=OPENAI_API_MODEL_PRIMARY="$PROD_OPENAI_MODEL_PRIMARY" \
          --dart-define=OPENAI_API_MODEL_SECONDARY="$PROD_OPENAI_MODEL_SECONDARY" \
          --dart-define=OPENAI_API_MODEL_TERTIARY="$PROD_OPENAI_MODEL_TERTIARY" \
          --dart-define=GEMINI_API_MODEL="$PROD_GEMINI_MODEL"
        echo "✅ App Bundle built successfully: build/app/outputs/bundle/release/app-release.aab"
        ;;
    "ios")
        echo "🍎 Building iOS..."
        flutter build ios --release \
          --dart-define=OPENAI_API_KEY="$PROD_OPENAI_API_KEY" \
          --dart-define=GEMINI_API_KEY="$PROD_GEMINI_API_KEY" \
          --dart-define=OPENAI_API_MODEL_PRIMARY="$PROD_OPENAI_MODEL_PRIMARY" \
          --dart-define=OPENAI_API_MODEL_SECONDARY="$PROD_OPENAI_MODEL_SECONDARY" \
          --dart-define=OPENAI_API_MODEL_TERTIARY="$PROD_OPENAI_MODEL_TERTIARY" \
          --dart-define=GEMINI_API_MODEL="$PROD_GEMINI_MODEL"
        echo "✅ iOS build completed. Open ios/Runner.xcworkspace in Xcode to archive."
        ;;
    *)
        echo "❌ Unknown build type: $BUILD_TYPE"
        echo "Usage: $0 [apk|aab|ios]"
        echo "  apk - Build Android APK (default)"
        echo "  aab - Build Android App Bundle for Play Store"
        echo "  ios - Build iOS for App Store"
        exit 1
        ;;
esac

echo "🎉 Production build completed successfully!" 