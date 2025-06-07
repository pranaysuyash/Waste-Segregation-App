#!/bin/bash

echo "🔧 Switching to stable Flutter channel..."

# Check current channel
echo "📋 Current Flutter channel:"
flutter channel

# Switch to stable channel
echo "🔄 Switching to stable channel..."
flutter channel stable

# Upgrade Flutter
echo "⬆️ Upgrading Flutter..."
flutter upgrade

# Clean everything
echo "🧹 Cleaning project..."
flutter clean
rm -rf .dart_tool
rm -rf build

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

echo "✅ Switched to stable Flutter channel!"
echo ""
echo "🎯 Try running the app now:"
echo "flutter run --dart-define-from-file=.env"
