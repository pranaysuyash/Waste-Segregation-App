#!/bin/bash
# AI Agent Development Runner - Enhanced for AI workflow

set -e

echo "🤖 AI Agent Development Runner"
echo "=============================="

# 1. Environment validation
echo "🔍 Validating environment..."
if [ ! -f ".env" ]; then
    echo "❌ .env file missing - creating template"
    if [ -f ".env.template" ]; then
        cp .env.template .env
    else
        cat > .env << 'EOF'
# AI Agent Development Configuration
# Configure with your actual values

# API Keys (Required for AI classification)
OPENAI_API_KEY=your_openai_key_here
GEMINI_API_KEY=your_gemini_key_here

# Development Settings
FLUTTER_ENV=development
DEBUG_MODE=true
AI_AGENT_MODE=true

# Testing Configuration
SKIP_SLOW_TESTS=false
AUTO_UPDATE_GOLDENS=false
ENABLE_PERFORMANCE_MONITORING=true
EOF
    fi
    echo "⚠️  Please configure .env file with your API keys"
    echo "📝 Template created at .env"
    exit 1
fi

# 2. Dependency check
echo "📦 Checking dependencies..."
flutter pub get

# 3. Code quality check
echo "🔍 Running static analysis..."
dart format .
flutter analyze --fatal-infos

# 4. Quick test validation
echo "🧪 Running quick tests..."
flutter test --exclude-tags=golden,integration

# 5. API connectivity check
echo "🌐 Checking API connectivity..."
if [ -f "scripts/testing/test_api_connectivity.sh" ]; then
    ./scripts/testing/test_api_connectivity.sh
else
    echo "⚠️  API connectivity test not found, skipping..."
fi

# 6. Start development server
echo "🚀 Starting development server..."
echo "📱 App will launch on connected device/simulator"
echo "🔥 Hot reload enabled for rapid development"
echo ""
flutter run --dart-define-from-file=.env 