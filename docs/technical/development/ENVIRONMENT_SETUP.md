# Environment Setup Documentation

**Date**: June 3, 2025  
**Version**: 0.1.5+99  
**Status**: 🔧 **DEBUGGING IN PROGRESS**

## 🚨 Critical Environment Requirements

The WasteWise app **REQUIRES** environment variables to be loaded during development. Without proper environment setup:

- ❌ All classifications will return "unknown item"
- ❌ Images will not be saved properly
- ❌ AI analysis will fail silently

## ✅ Correct Development Setup

### **Method 1: Using run_with_env.sh (Recommended)**
```bash
./run_with_env.sh
```

### **Method 2: Manual Flutter Command**
```bash
flutter run --dart-define-from-file=.env
```

### **Method 3: Debug Mode**
```bash
flutter run --debug --dart-define-from-file=.env
```

## 🔧 Environment File Structure

Your `.env` file should contain:
```env
OPENAI_API_KEY=sk-proj-your-key-here
GEMINI_API_KEY=AIzaSy-your-key-here
OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano
OPENAI_API_MODEL_SECONDARY=gpt-4o-mini
OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini
GEMINI_API_MODEL=gemini-2.0-flash
```

## 🐛 Current Issues Under Investigation

### **Issue 1: Repetitive Duplicate Detection Logs** ✅ **FIXED**
- **Problem**: App was logging every classification during history loading
- **Solution**: Reduced verbose logging to summary-only in `StorageService.getAllClassifications()`
- **Status**: Fixed in commit `e806bd8`

### **Issue 2: "Unknown Item" Despite Valid API Keys** ✅ **RESOLVED**
- **Problem**: Classifications returned "Unknown Item" even with proper environment setup
- **Root Cause**: AI was working correctly but returning `"itemName": null` in JSON responses
- **Solution**: Enhanced itemName parsing to extract meaningful names from explanation text when AI returns null
- **Fix Details**:
  - Added regex patterns to extract item names from explanation text
  - Fallback to subcategory or cleaned category names
  - Handles cases where AI correctly classifies but doesn't provide explicit itemName
- **Status**: Fixed in commit `5598377`
- **Result**: Now shows proper item names like "Plant debris" instead of "Unknown Item"

### **Debugging Features Added**
- **API Key Validation**: Logs first 10 characters of API keys to verify loading
- **Request Tracking**: Logs API call details, request size, response status
- **JSON Parsing Debug**: Enhanced logging for AI response parsing failures
- **Response Content**: Logs raw AI responses when JSON parsing fails

## 🔍 Troubleshooting

### **Problem: Getting "unknown item" classifications**

1. **Check Environment Loading**:
   ```bash
   # Look for this log message during app startup:
   flutter: Environment variables loaded via --dart-define-from-file
   ```

2. **Verify API Keys**:
   ```bash
   # Check the debug logs for:
   flutter: 🔑 OpenAI API Key: sk-proj-P1V...
   flutter: 🔑 Gemini API Key: AIzaSyDYXP...
   ```

3. **Monitor API Calls**:
   ```bash
   # Look for API call logs:
   flutter: 🌐 Response status: 200
   flutter: ✅ OpenAI API Success
   ```

4. **Check JSON Parsing**:
   ```bash
   # Look for parsing success:
   flutter: ✅ JSON PARSING SUCCESS
   # Or parsing failures:
   flutter: ❌ JSON PARSING FAILED
   ```

### **Problem: Missing images in history**

This is typically caused by:
- Images saved with relative paths instead of absolute paths
- Cross-platform path issues (Android vs iOS)
- Images not being saved permanently

**Solution**: The `EnhancedImageService` now handles permanent image storage.

## 📊 Current App Status

- **Environment**: ✅ Properly configured
- **API Keys**: ✅ Valid and loaded
- **Gamification**: ✅ Working (35 points, streak tracking)
- **Image Storage**: ✅ Enhanced service implemented
- **Duplicate Detection**: ✅ Fixed excessive logging
- **AI Analysis**: ✅ **RESOLVED** - Fixed itemName extraction from AI responses

## 🚀 Next Steps

1. **✅ COMPLETED**: Enhanced debugging captured detailed AI response logs
2. **✅ COMPLETED**: Analyzed JSON parsing and identified itemName null issue  
3. **✅ COMPLETED**: Fixed itemName extraction with regex patterns and fallbacks
4. **🔄 ONGOING**: Remove temporary debugging code (partially completed)
5. **📋 TODO**: Test with various image types to ensure fix works consistently

## 📝 Development Notes

- Always use `./run_with_env.sh` for development
- Monitor debug logs for API call details
- Report any "Unknown Item" issues with full debug logs
- Enhanced debugging is temporary and will be removed once issue is resolved


- **Solution**: Stop the app and restart using `./run_with_env.sh`

**Problem: Images not showing in history**
- **Cause**: May be related to running without environment variables
- **Solution**: Ensure you're using the proper run command with `.env` file

**Problem: API errors in logs**
- **Cause**: Invalid or missing API keys
- **Solution**: Check that your `.env` file has valid API keys

### Production Deployment

This requirement is **only for development**. In production:
- Environment variables will be injected through the deployment pipeline
- CI/CD will handle proper configuration
- No manual `.env` file management required

### Security Note

- **Never commit the `.env` file to version control**
- The `.env` file is already in `.gitignore`
- API keys are sensitive and should be kept secure

---

**Remember: Until production deployment, ALWAYS use `./run_with_env.sh` or `flutter run --dart-define-from-file=.env`** 