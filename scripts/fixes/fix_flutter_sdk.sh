#!/bin/bash

echo "🔧 Fixing Flutter SDK issues..."

# Check Flutter version
echo "📋 Current Flutter version:"
flutter --version

# Clean Flutter cache
echo "🧹 Cleaning Flutter cache..."
flutter clean

# Remove .dart_tool directory
echo "🗑️ Removing .dart_tool..."
rm -rf .dart_tool

# Update Flutter
echo "⬆️ Updating Flutter..."
flutter upgrade

# Check for issues
echo "🔍 Running Flutter doctor..."
flutter doctor -v

# Recreate project dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Pre-compile dependencies
echo "⚡ Pre-compiling..."
flutter pub deps

echo "✅ Flutter SDK fix completed!"
echo ""
echo "🎯 Next steps:"
echo "1. Try running: flutter run --dart-define-from-file=.env"
echo "2. If issues persist, try Solution 2 below"
