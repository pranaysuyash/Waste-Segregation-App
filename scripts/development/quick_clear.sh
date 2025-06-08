#!/bin/bash

echo "🔥 Quick Manual Clear Script"
echo "============================"

# Function to clear Flutter build artifacts
clear_flutter() {
    echo "🧹 Clearing Flutter build artifacts..."
    flutter clean
    rm -rf .dart_tool
    rm -rf build
    echo "✅ Flutter artifacts cleared"
}

# Function to clear device app data
clear_device_data() {
    echo "📱 Clearing device app data..."
    
    # Check if multiple devices are connected
    device_count=$(adb devices | grep -c "device$")
    
    if [ $device_count -eq 0 ]; then
        echo "❌ No devices connected"
        return 1
    elif [ $device_count -eq 1 ]; then
        # Single device, clear directly
        adb shell pm clear com.pranaysuyash.wastewise
        echo "✅ Device app data cleared"
    else
        # Multiple devices, show options
        echo "Multiple devices found:"
        adb devices
        echo ""
        echo "Please specify device manually:"
        echo "adb -s DEVICE_ID shell pm clear com.pranaysuyash.wastewise"
        return 1
    fi
}

# Function to reinstall dependencies
reinstall_deps() {
    echo "📦 Reinstalling dependencies..."
    flutter pub get
    echo "✅ Dependencies reinstalled"
}

# Main execution
echo ""
echo "This script will:"
echo "1. Clear Flutter build artifacts"
echo "2. Clear device app data"
echo "3. Reinstall dependencies"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    clear_flutter
    echo ""
    clear_device_data
    echo ""
    reinstall_deps
    echo ""
    echo "🎉 Manual clear completed!"
    echo ""
    echo "📱 Next steps:"
    echo "   1. Run: flutter run --dart-define-from-file=.env"
    echo "   2. App will start with fresh data"
    echo "   3. Sign in to test the clean state"
else
    echo "❌ Operation cancelled"
fi 