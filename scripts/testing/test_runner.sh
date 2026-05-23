#!/bin/bash

# ReLoop Test Runner
# This script runs all tests and generates coverage reports

echo "🧪 Starting ReLoop Test Suite..."
echo "=================================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Clean previous build artifacts
echo "🧹 Cleaning previous build artifacts..."
flutter clean
flutter pub get

# Run model tests
echo ""
echo "📊 Running Model Tests..."
flutter test test/models/models_test.dart --reporter expanded

# Run service tests  
echo ""
echo "⚙️ Running Service Tests..."
if [ -f "test/services/gamification_service_test.dart" ]; then
    flutter test test/services/gamification_service_test.dart --reporter expanded
fi

if [ -f "test/services/ai_service_test.dart" ]; then
    flutter test test/services/ai_service_test.dart --reporter expanded
fi

# Run flow tests
echo ""
echo "🔄 Running Flow Integration Tests..."
if [ -f "test/flows/classification_flow_test.dart" ]; then
    flutter test test/flows/classification_flow_test.dart --reporter expanded
fi

# Run existing regression tests
echo ""
echo "🔄 Running Regression Tests..."
if [ -f "test/regression_tests.dart" ]; then
    flutter test test/regression_tests.dart --reporter expanded
fi

# Run widget/screen tests
echo ""
echo "🖼️ Running Widget/Screen Tests..."
if [ -f "test/screens/result_screen_test.dart" ]; then
    flutter test test/screens/result_screen_test.dart --reporter expanded
fi

if [ -f "test/screens/classification_details_screen_test.dart" ]; then
    flutter test test/screens/classification_details_screen_test.dart --reporter expanded
fi

if [ -f "test/screens/family_management_screen_test.dart" ]; then
    flutter test test/screens/family_management_screen_test.dart --reporter expanded
fi

if [ -f "test/screens/family_dashboard_screen_test.dart" ]; then
    flutter test test/screens/family_dashboard_screen_test.dart --reporter expanded
fi

# Run golden tests
echo ""
echo "🏆 Running Golden Tests..."
if [ -f "test/golden/responsive_text_golden_test.dart" ]; then
    flutter test test/golden/responsive_text_golden_test.dart --reporter expanded
fi

if [ -f "test/golden/stats_card_golden_test.dart" ]; then
    flutter test test/golden/stats_card_golden_test.dart --reporter expanded
fi

# Run achievement tests
echo ""
echo "🏅 Running Achievement Tests..."
if [ -f "test/achievement_unlock_logic_test.dart" ]; then
    flutter test test/achievement_unlock_logic_test.dart --reporter expanded
fi

# Generate test coverage (optional - requires coverage package)
echo ""
echo "📈 Generating Test Coverage Report..."
if flutter test --coverage; then
    echo "✅ Coverage report generated in coverage/lcov.info"
    
    # If genhtml is available, generate HTML report
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo "📊 HTML coverage report generated in coverage/html/"
    else
        echo "💡 Install lcov (genhtml) to generate HTML coverage reports"
    fi
else
    echo "⚠️ Coverage generation failed or not supported"
fi

# Run all tests together for final summary
echo ""
echo "🚀 Running Full Test Suite..."
flutter test --reporter expanded

echo ""
echo "=================================================="
echo "✅ Test Suite Complete!"
echo ""
echo "📋 Test Categories Covered:"
echo "   - Data Models (serialization, validation)"
echo "   - Service Logic (AI, Gamification, Storage)"
echo "   - Integration Flows (Classification workflow)"
echo "   - UI Components (Screens, Widgets)"
echo "   - Golden Tests (Visual regression)"
echo "   - Error Handling & Edge Cases"
echo ""
echo "💡 Next Steps:"
echo "   - Review test results above"
echo "   - Check coverage report if generated"
echo "   - Fix any failing tests"
echo "   - Add more tests for uncovered areas"
echo "" 