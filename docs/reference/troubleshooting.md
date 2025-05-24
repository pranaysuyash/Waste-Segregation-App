# Troubleshooting Guide

This guide covers common issues and their solutions for the Waste Segregation App.

## 🚨 **Critical Issues Recently Fixed**

### ✅ Dashboard Display Problems - RESOLVED ✅
**Issue**: Charts not displaying, recent activities blank, streak box formatting issues  
**Status**: **FIXED** in version 0.1.4+96  
**Solution**: Complete WebView chart overhaul with enhanced error handling

### ✅ Achievement Unlock Timing - RESOLVED ✅
**Issue**: Level-locked achievements not tracking progress properly  
**Status**: **FIXED** in version 0.1.4+96  
**Solution**: Modified achievement progress tracking to process all achievements

### ✅ Statistics Display Inconsistency - RESOLVED ✅  
**Issue**: Item counts inconsistent between screens ("1 item" vs "10 items")  
**Status**: **FIXED** in version 0.1.4+96  
**Solution**: Proper points-to-items conversion throughout the app

## 🛠️ **Current Known Issues**

### ⚠️ Ad Loading Errors (Non-Critical)
**Symptoms**: Console shows "Banner ad failed to load" messages  
**Cause**: Test ads in debug mode with network connection issues  
**Impact**: None - ads still work in production  
**Solution**: Normal behavior, no action needed

### ⚠️ Deprecation Warnings (Non-Critical)
**Symptoms**: Flutter analyzer shows deprecation warnings  
**Cause**: Future Flutter version compatibility  
**Impact**: None currently  
**Solution**: Will be addressed in future Flutter updates

## 🔧 **Common Development Issues**

### Build Issues

#### **Gradle Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter build apk
```

#### **Hive Database Issues**
```bash
# Reset Hive data if corrupted
rm -rf path_to_hive_boxes
flutter clean && flutter pub get
```

#### **Firebase Connection Issues**
1. Check `google-services.json` is in `android/app/`
2. Verify Firebase project configuration
3. Ensure bundle ID matches Firebase settings

### Runtime Issues

#### **Classification Not Working**
**Possible Causes:**
1. **Network connectivity** - Check internet connection
2. **API key issues** - Verify API keys in environment
3. **Image processing** - Try different image types/sizes

**Solutions:**
```dart
// Check network connectivity
if (await ConnectivityService.hasConnection()) {
  // Proceed with classification
}

// Validate image before processing
if (imageFile != null && await imageFile.exists()) {
  // Process image
}
```

#### **App Crashes on Launch**
**Common Causes:**
1. **Hive initialization** - Database corruption
2. **Service dependencies** - Missing required services
3. **Permission issues** - Camera/storage permissions

**Solutions:**
1. Clear app data and restart
2. Check console for specific error messages
3. Verify all permissions are granted

## 📱 **User Experience Issues**

### UI/UX Problems

#### **Charts Not Loading**
**Status**: ✅ **FIXED** in v0.1.4+96  
**If still experiencing issues:**
1. Check internet connection
2. Force close and restart app
3. Clear app cache

#### **Achievements Not Unlocking**
**Status**: ✅ **FIXED** in v0.1.4+96  
**If still experiencing issues:**
1. Verify you meet the requirements
2. Check that progress is being tracked
3. Restart app to refresh achievement state

#### **Statistics Not Matching**
**Status**: ✅ **FIXED** in v0.1.4+96  
**If still experiencing issues:**
1. Force refresh the statistics screen
2. Check that all classifications are properly saved
3. Restart app to reload data

### Performance Issues

#### **Slow App Performance**
**Solutions:**
1. Clear app cache in device settings
2. Restart the app completely
3. Ensure sufficient device storage (>1GB free)
4. Close other memory-intensive apps

#### **High Battery Usage**
**Causes & Solutions:**
1. **Camera usage** - Only enable when needed
2. **Background sync** - Disable if not needed
3. **Chart animations** - Reduce animation duration

## 🔍 **Debugging Tips**

### Enable Debug Logging
```dart
// Add to main.dart for detailed logging
debugPrint('Debug mode enabled');
Logger.root.level = Level.ALL;
```

### Check App State
```dart
// Verify critical services
print('Storage initialized: ${StorageService.isInitialized}');
print('User authenticated: ${AuthService.isAuthenticated}');
print('Network available: ${await NetworkService.isAvailable()}');
```

### Monitor Memory Usage
```dart
// Check memory usage in debug builds
import 'dart:developer' as developer;
developer.log('Memory usage check');
```

## 📞 **Getting Help**

### **For Development Issues:**
1. Check this troubleshooting guide first
2. Review the [Technical Documentation](../technical/README.md)
3. Check the [Developer Guide](../guides/developer_guide.md)
4. Review recent fixes in [CHANGELOG.md](../../CHANGELOG.md)

### **For Bug Reports:**
Include this information:
- App version (currently 0.1.4+96)
- Device model and OS version
- Steps to reproduce the issue
- Console error messages if available
- Screenshots/screen recordings if applicable

### **For Performance Issues:**
- Device specifications
- Available storage space
- Other apps running simultaneously
- Network connection type and speed

## 🔄 **Recovery Procedures**

### **Complete App Reset**
If experiencing persistent issues:
1. Force close the app
2. Clear app data in device settings
3. Uninstall and reinstall the app
4. Restart device
5. Reinstall app and set up again

### **Data Recovery**
If data is lost:
1. Check if user was signed in with Google (data may be backed up)
2. Look for local Hive database files
3. Check Firebase console for user data

### **Network Issues**
For connectivity problems:
1. Switch between WiFi and mobile data
2. Check firewall settings
3. Verify API endpoints are accessible
4. Test with different network environments

## ✅ **Prevention Tips**

### **For Developers:**
1. Always test on clean app installs
2. Verify all dependencies are properly initialized
3. Implement comprehensive error handling
4. Monitor performance metrics regularly

### **For Users:**
1. Keep the app updated to latest version
2. Maintain adequate device storage
3. Grant necessary permissions when requested
4. Report issues promptly with detailed information

## 📊 **Status Dashboard**

### **Current App Health** (v0.1.4+96)
- **Stability**: ✅ Excellent (0 critical bugs)
- **Performance**: ✅ Good (optimized charts and animations)
- **User Experience**: ✅ Professional (polished interface)
- **Functionality**: ✅ Complete (all features working)

### **Known Issues Count**
- **Critical**: 0 ✅
- **High**: 0 ✅  
- **Medium**: 2 ⚠️ (non-blocking deprecations)
- **Low**: 1 ℹ️ (minor linting suggestions)

**Overall Status: 🟢 HEALTHY - Ready for Production** 