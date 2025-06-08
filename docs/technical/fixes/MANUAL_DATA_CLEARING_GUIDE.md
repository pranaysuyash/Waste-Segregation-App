# Manual Data Clearing Guide

**Date**: January 8, 2025  
**Version**: 2.0.2  
**Status**: ✅ Complete  

## Overview

When the automated Firebase cleanup service gets stuck or fails to complete, use these manual methods to clear all data and achieve a fresh install state.

## 🚨 **When to Use Manual Clearing**

### Symptoms of Stuck Cleanup:
- App shows "Firebase cleanup completed" but data persists
- Cleanup process hangs indefinitely
- App becomes unresponsive during cleanup
- Data remains cached despite successful cleanup messages

### Manual Clearing Scenarios:
- Testing fresh user onboarding
- Debugging data persistence issues
- Resetting development environment
- Clearing corrupted local storage

## 🔧 **Manual Clearing Methods**

### **Method 1: Quick Script (Recommended)**

Use the automated script for comprehensive clearing:

```bash
# Run the quick clear script
./scripts/development/quick_clear.sh
```

**What it does:**
- ✅ Clears Flutter build artifacts
- ✅ Removes device app data completely
- ✅ Reinstalls dependencies
- ✅ Handles multiple device scenarios

### **Method 2: Step-by-Step Manual Commands**

#### **Step 1: Clear Flutter Build Cache**
```bash
# Complete Flutter reset
flutter clean && rm -rf .dart_tool && rm -rf build && flutter pub get
```

#### **Step 2: Clear Device App Data**
```bash
# For single device
adb shell pm clear com.pranaysuyash.wastewise

# For specific device (if multiple connected)
adb devices  # List devices first
adb -s DEVICE_ID shell pm clear com.pranaysuyash.wastewise
```

#### **Step 3: Clear Local Storage Directories**
```bash
# Remove any persistent local storage
rm -rf storage/
rm -rf temp/
rm -rf debug-symbols/
```

### **Method 3: Firebase CLI Clearing (Advanced)**

For clearing Firebase data directly:

```bash
# Run the Firebase clearing script
dart scripts/development/manual_firebase_clear.dart
```

**Prerequisites:**
- Firebase CLI installed: `npm install -g firebase-tools`
- Authenticated with Firebase: `firebase login`
- Project access permissions

## 📱 **Device-Specific Clearing**

### **Android Device Clearing**
```bash
# Clear app data (removes all local storage)
adb shell pm clear com.pranaysuyash.wastewise

# Clear app cache only (preserves user data)
adb shell pm clear-cache com.pranaysuyash.wastewise

# Uninstall and reinstall (nuclear option)
adb uninstall com.pranaysuyash.wastewise
flutter install
```

### **iOS Simulator Clearing**
```bash
# Reset iOS simulator
xcrun simctl erase all

# Or reset specific simulator
xcrun simctl erase "iPhone 16 Plus"
```

### **macOS App Clearing**
```bash
# Clear macOS app data
rm -rf ~/Library/Containers/com.pranaysuyash.wastewise/
rm -rf ~/Library/Application\ Support/com.pranaysuyash.wastewise/
```

## 🗂️ **What Gets Cleared**

### **Local Storage (Device)**
- ✅ Hive boxes (classifications, userProfile, settings, achievements)
- ✅ Shared preferences
- ✅ Cached images and files
- ✅ Local database files
- ✅ Temporary files

### **Flutter Build Artifacts**
- ✅ Build directory
- ✅ .dart_tool directory
- ✅ Generated files
- ✅ Cached dependencies
- ✅ Platform-specific builds

### **Firebase Data (if using CLI method)**
- ✅ User documents
- ✅ Community feed
- ✅ Community stats
- ✅ Family data
- ✅ Classifications
- ✅ Analytics events

## 🔍 **Verification Steps**

After manual clearing, verify the fresh state:

### **1. Check App Startup**
```bash
flutter run --dart-define-from-file=.env
```

**Expected behavior:**
- App starts on auth screen
- No cached user data visible
- Impact cards show default values
- No previous classifications in history

### **2. Check Local Storage**
```bash
# Verify no local data exists
adb shell run-as com.pranaysuyash.wastewise ls -la files/
```

**Expected result:**
- Empty or minimal file structure
- No Hive database files
- No cached images

### **3. Check Firebase Console**
- Navigate to Firebase Console
- Verify collections are empty or reset
- Check community stats show zero values

## 🛠️ **Troubleshooting**

### **"Device not found" Error**
```bash
# Check connected devices
adb devices

# Restart ADB if needed
adb kill-server && adb start-server
```

### **"Permission denied" Error**
```bash
# Enable USB debugging on device
# Grant ADB permissions when prompted
# Try with sudo if on macOS/Linux
sudo adb shell pm clear com.pranaysuyash.wastewise
```

### **Flutter Clean Fails**
```bash
# Force clean with manual deletion
rm -rf build .dart_tool
flutter clean
flutter pub get
```

### **Firebase CLI Not Found**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify project access
firebase projects:list
```

## 📋 **Quick Reference Commands**

### **Complete Reset (All Methods)**
```bash
# 1. Flutter artifacts
flutter clean && rm -rf .dart_tool && rm -rf build

# 2. Device data
adb shell pm clear com.pranaysuyash.wastewise

# 3. Dependencies
flutter pub get

# 4. Run app
flutter run --dart-define-from-file=.env
```

### **Emergency Reset (Nuclear Option)**
```bash
# Uninstall app completely
adb uninstall com.pranaysuyash.wastewise

# Clean everything
flutter clean && rm -rf .dart_tool && rm -rf build

# Reinstall fresh
flutter pub get
flutter run --dart-define-from-file=.env
```

## 🎯 **Best Practices**

### **Before Manual Clearing**
- ✅ Close the app completely
- ✅ Disconnect from debugger
- ✅ Note any important test data
- ✅ Ensure device is connected properly

### **After Manual Clearing**
- ✅ Verify fresh app startup
- ✅ Test core functionality
- ✅ Check for any residual data
- ✅ Document any issues found

### **Development Workflow**
- ✅ Use manual clearing for reliable testing
- ✅ Clear between major feature tests
- ✅ Document clearing procedures for team
- ✅ Automate clearing in CI/CD pipelines

## 📁 **Related Files**

- `scripts/development/quick_clear.sh` - Automated clearing script
- `scripts/development/manual_firebase_clear.dart` - Firebase CLI clearing
- `lib/services/firebase_cleanup_service.dart` - App-based cleanup service
- `docs/technical/fixes/FIREBASE_CLEANUP_IMPROVEMENTS.md` - Service documentation

## 🔄 **Version History**

- **v2.0.1**: Initial Firebase cleanup service
- **v2.0.2**: Enhanced service + manual clearing methods
- **v2.0.2+**: Comprehensive manual clearing guide and scripts

## ⚡ **Quick Start**

For immediate fresh install simulation:

```bash
# One-liner complete reset
./scripts/development/quick_clear.sh && flutter run --dart-define-from-file=.env
```

This will clear everything and start the app fresh in one command! 