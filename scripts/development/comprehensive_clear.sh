#!/bin/bash

# Comprehensive Data Clearing Script for WasteWise App
# This script provides multiple methods to clear all app data when automated methods fail

echo "🧹 WasteWise Comprehensive Data Clearing Script"
echo "=============================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to clear Flutter build artifacts
clear_flutter_artifacts() {
    echo "🔧 Clearing Flutter build artifacts..."
    flutter clean
    rm -rf .dart_tool
    rm -rf build
    rm -rf ios/build
    rm -rf android/build
    rm -rf macos/build
    rm -rf web/build
    echo "✅ Flutter artifacts cleared"
}

# Function to clear device app data (Android)
clear_android_app_data() {
    if command_exists adb; then
        echo "📱 Clearing Android app data..."
        adb shell pm clear com.pranaysuyash.wastewise
        echo "✅ Android app data cleared"
    else
        echo "⚠️ ADB not found. Install Android SDK tools to use this feature."
    fi
}

# Function to clear iOS simulator data
clear_ios_simulator_data() {
    if command_exists xcrun; then
        echo "📱 Clearing iOS Simulator data..."
        xcrun simctl uninstall booted com.pranaysuyash.wastewise
        echo "✅ iOS Simulator data cleared"
    else
        echo "⚠️ Xcode tools not found. This feature is only available on macOS with Xcode."
    fi
}

# Function to reinstall dependencies
reinstall_dependencies() {
    echo "📦 Reinstalling dependencies..."
    flutter pub get
    echo "✅ Dependencies reinstalled"
}

# Function to clear local storage directories
clear_local_storage() {
    echo "🗂️ Clearing local storage directories..."
    
    # Clear common Flutter storage locations
    if [ -d "$HOME/.flutter" ]; then
        rm -rf "$HOME/.flutter/logs"
        echo "  - Cleared Flutter logs"
    fi
    
    # Clear Hive storage (if accessible)
    if [ -d "storage" ]; then
        rm -rf storage/*
        echo "  - Cleared local storage directory"
    fi
    
    echo "✅ Local storage cleared"
}

# Main menu
show_menu() {
    echo ""
    echo "Select clearing method:"
    echo "1) Quick Clear (Flutter artifacts + dependencies)"
    echo "2) Android Device Clear (requires ADB)"
    echo "3) iOS Simulator Clear (requires Xcode)"
    echo "4) Complete Clear (all methods)"
    echo "5) Local Storage Only"
    echo "6) Exit"
    echo ""
    read -p "Enter your choice (1-6): " choice
}

# Process user choice
process_choice() {
    case $choice in
        1)
            echo ""
            echo "🚀 Starting Quick Clear..."
            clear_flutter_artifacts
            reinstall_dependencies
            echo ""
            echo "✅ Quick Clear completed!"
            ;;
        2)
            echo ""
            echo "🚀 Starting Android Device Clear..."
            clear_android_app_data
            clear_flutter_artifacts
            reinstall_dependencies
            echo ""
            echo "✅ Android Device Clear completed!"
            ;;
        3)
            echo ""
            echo "🚀 Starting iOS Simulator Clear..."
            clear_ios_simulator_data
            clear_flutter_artifacts
            reinstall_dependencies
            echo ""
            echo "✅ iOS Simulator Clear completed!"
            ;;
        4)
            echo ""
            echo "🚀 Starting Complete Clear..."
            clear_local_storage
            clear_android_app_data
            clear_ios_simulator_data
            clear_flutter_artifacts
            reinstall_dependencies
            echo ""
            echo "✅ Complete Clear finished!"
            echo "🎉 Your app should now behave like a fresh install!"
            ;;
        5)
            echo ""
            echo "🚀 Starting Local Storage Clear..."
            clear_local_storage
            echo ""
            echo "✅ Local Storage Clear completed!"
            ;;
        6)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please try again."
            ;;
    esac
}

# Main execution
main() {
    # Check if we're in the right directory
    if [ ! -f "pubspec.yaml" ]; then
        echo "❌ Error: This script must be run from the Flutter project root directory."
        echo "Please navigate to your WasteWise project directory and try again."
        exit 1
    fi
    
    # Check Flutter installation
    if ! command_exists flutter; then
        echo "❌ Error: Flutter is not installed or not in PATH."
        echo "Please install Flutter and try again."
        exit 1
    fi
    
    while true; do
        show_menu
        process_choice
        echo ""
        read -p "Would you like to perform another operation? (y/n): " continue_choice
        if [[ $continue_choice != "y" && $continue_choice != "Y" ]]; then
            echo "👋 Goodbye!"
            break
        fi
    done
}

# Run the script
main 