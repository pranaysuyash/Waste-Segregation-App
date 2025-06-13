# Scripts Directory Index
## Waste Segregation App - Development & Build Scripts

*Last Updated: June 6, 2025*

This directory contains all development, build, testing, and maintenance scripts organized by category for easy access and management.

---

## 📁 **SCRIPTS STRUCTURE**

### `/scripts/testing/` - Testing & QA Scripts
- **comprehensive_test_runner.sh** - Complete test suite execution with coverage analysis
- **quick_test.sh** - Fast testing for development iterations
- **test_low_hanging_fruits.sh** - Quick wins and simple test execution
- **test_runner.sh** - Basic test runner for specific test categories
- **test_api_connectivity.sh** - API connectivity validation and troubleshooting for OpenAI and Gemini APIs

### `/scripts/build/` - Build & Deployment Scripts
- **build_production.sh** - Production builds for different platforms (APK, App Bundle, iOS)

### `/scripts/fixes/` - Problem Resolution Scripts
- **add_missing_imports.sh** - Automatically add missing import statements
- **apply_final_fixes.sh** - Apply final fixes before release
- **apply_fixes.sh** - General fix application script
- **fix_flutter_sdk.sh** - Flutter SDK issue resolution
- **fix_kotlin_build_issue.sh** - Kotlin-specific build problem fixes
- **fix_play_store_signin.sh** - Google Play Sign-In configuration fixes

### `/scripts/development/` - Development Workflow Scripts
- **run_with_env.sh** - Run app with environment validation and error checking
- **switch_flutter_channel.sh** - Switch between Flutter channels (stable, beta, dev)

### `/scripts/` - Core Scripts
- **setup_github_todos.sh** - GitHub TODO integration setup

---

## 🚀 **QUICK USAGE GUIDE**

### **Daily Development Workflow**
```bash
# 1. Test API connectivity (if having classification issues)
./scripts/testing/test_api_connectivity.sh

# 2. Run the app with environment validation
./scripts/development/run_with_env.sh

# 3. Quick testing during development
./scripts/testing/quick_test.sh

# 4. Comprehensive testing before commits
./scripts/testing/comprehensive_test_runner.sh
```

### **Build & Release Workflow**
```bash
# 1. Apply any pending fixes
./scripts/fixes/apply_final_fixes.sh

# 2. Run full test suite
./scripts/testing/comprehensive_test_runner.sh

# 3. Build for production
./scripts/build/build_production.sh aab  # Android App Bundle
./scripts/build/build_production.sh apk  # Android APK
./scripts/build/build_production.sh ios  # iOS build
```

### **Problem Resolution Workflow**
```bash
# API connectivity issues (image classification not working)
./scripts/testing/test_api_connectivity.sh

# Flutter SDK issues
./scripts/fixes/fix_flutter_sdk.sh

# Build problems
./scripts/fixes/fix_kotlin_build_issue.sh

# Missing imports
./scripts/fixes/add_missing_imports.sh

# Play Store signin issues
./scripts/fixes/fix_play_store_signin.sh
```

### **Environment Management**
```bash
# Switch Flutter channels
./scripts/development/switch_flutter_channel.sh stable
./scripts/development/switch_flutter_channel.sh beta
./scripts/development/switch_flutter_channel.sh dev
```

---

## 🔧 **SCRIPT CATEGORIES EXPLAINED**

### **Testing Scripts**
Automated testing tools for quality assurance and continuous integration.
- **Comprehensive**: Full test suite with coverage reports
- **Quick**: Fast feedback during development
- **Specific**: Targeted testing for particular components
- **API Testing**: Real-time validation of OpenAI and Gemini API connectivity with detailed diagnostics

### **Build Scripts**
Production build automation for different platforms and deployment targets.
- **Multi-platform**: Support for Android (APK, AAB) and iOS
- **Environment-aware**: Handles production vs development configurations
- **Automated**: Minimal manual intervention required

### **Fix Scripts**
Automated problem resolution for common development issues.
- **SDK Issues**: Flutter and Dart SDK problems
- **Build Problems**: Platform-specific build failures
- **Configuration**: Environment and setup issues
- **Dependencies**: Import and package problems

### **Development Scripts**
Daily development workflow automation and environment management.
- **Environment**: Validation and setup
- **Runtime**: App execution with proper configuration
- **Channel Management**: Flutter version control

---

## 📋 **SCRIPT PERMISSIONS**

Ensure all scripts have proper execution permissions:

```bash
# Make all scripts executable
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Or individual script permission
chmod +x scripts/development/run_with_env.sh
```

---

## 🎯 **DEVELOPMENT GUIDELINES**

### **Adding New Scripts**
1. **Choose appropriate category** based on script purpose
2. **Use descriptive names** that clearly indicate functionality
3. **Add to this index** with proper description
4. **Include usage examples** in script comments
5. **Test thoroughly** before committing

### **Script Best Practices**
- **Error handling**: Include proper error checking and messages
- **Documentation**: Add comments explaining complex operations
- **Validation**: Check prerequisites and environment setup
- **Logging**: Provide clear output for debugging
- **Exit codes**: Use proper exit codes for automation

### **Maintenance**
- **Regular review**: Check scripts monthly for updates needed
- **Testing**: Verify scripts work with latest Flutter/environment changes
- **Documentation**: Keep this index updated with new scripts
- **Cleanup**: Remove obsolete or unused scripts

---

## 🆘 **TROUBLESHOOTING**

### **Common Issues**

#### **Permission Denied**
```bash
# Make script executable
chmod +x scripts/category/script_name.sh
```

#### **Script Not Found**
```bash
# Run from project root directory
cd /path/to/waste_segregation_app
./scripts/category/script_name.sh
```

#### **Environment Issues**
```bash
# Verify Flutter environment
flutter doctor

# Check environment variables
echo $FLUTTER_ROOT
echo $PATH
```

#### **Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
./scripts/build/build_production.sh
```

---

## 📈 **METRICS & MONITORING**

### **Script Usage Tracking**
- Monitor script execution frequency
- Track success/failure rates
- Identify commonly used vs unused scripts
- Optimize based on usage patterns

### **Performance Monitoring**
- Measure script execution times
- Identify bottlenecks in workflows
- Optimize slow-running scripts
- Track resource usage

---

*This index ensures all team members can efficiently use the project's automation tools while maintaining a clean, organized script structure.*