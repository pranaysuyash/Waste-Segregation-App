#!/bin/bash

# Quick Test Runner - Execute core tests rapidly
# For use during development when you need fast feedback

echo "🚀 Quick Test Runner - Essential Tests Only"
echo "========================================"

# Essential unit tests
echo "📋 Running Essential Unit Tests..."
flutter test test/models/models_test.dart

# Core service tests  
echo "🔧 Running Core Service Tests..."
flutter test test/services/ai_service_test.dart
flutter test test/services/storage_service_test.dart
flutter test test/services/gamification_service_test.dart

# Critical screen tests
echo "🎨 Running Critical Screen Tests..."
flutter test test/screens/home_screen_test.dart
flutter test test/screens/result_screen_test.dart

# Basic integration test
echo "🔗 Running Integration Tests..."
flutter test test/integration/

echo "✅ Quick test run completed!"
echo "Run ./comprehensive_test_runner.sh for full test suite"
