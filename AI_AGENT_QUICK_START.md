# 🤖 AI Agent Quick Start Guide

**For**: AI agents like Claude working with solo developer  
**Goal**: Maximum efficiency with zero friction development

---

## 🚀 **INSTANT SETUP**

### **1. Environment Check**
```bash
# Quick environment validation
flutter doctor -v
flutter --version

# Start AI-optimized development
./scripts/development/ai_dev_runner.sh
```

### **2. API Configuration**
```bash
# Check if APIs are working
./scripts/testing/test_api_connectivity.sh

# If APIs fail, configure .env file:
# OPENAI_API_KEY=your_key_here
# GEMINI_API_KEY=your_key_here
```

---

## ⚡ **DEVELOPMENT WORKFLOW**

### **Standard AI Agent Workflow**
```bash
# 1. Create feature branch
git checkout -b feat/ai-$(date +%s)

# 2. Make changes (code, tests, docs)
# ... AI implements features ...

# 3. Validate everything
./scripts/testing/ai_test_validator.sh

# 4. Commit and deploy
git add .
git commit -m "feat: AI implementation with tests"
git push origin HEAD

# 5. Create PR (auto-merges when CI passes)
gh pr create --title "AI: Feature Implementation" --body "Automated implementation"
```

### **Quick Commands**
```bash
# Development
flutter run --dart-define-from-file=.env

# Testing
flutter test --coverage --exclude-tags=golden
./scripts/testing/comprehensive_test_runner.sh

# Golden tests (UI changes)
flutter test test/golden/
./scripts/testing/golden_test_manager.sh update  # if intentional

# Build
flutter build apk --release
```

---

## 🧪 **TESTING STRATEGY**

### **Test Categories**
- **Unit Tests**: `flutter test --exclude-tags=golden,integration`
- **Golden Tests**: `flutter test test/golden/` (visual regression)
- **Integration**: `flutter test test/integration/`
- **API Tests**: `./scripts/testing/test_api_connectivity.sh`

### **AI-Friendly Test Updates**
```bash
# When golden tests fail:
./scripts/testing/golden_test_manager.sh diff    # See changes
./scripts/testing/golden_test_manager.sh update  # Accept if intentional
git add test/golden/ && git commit -m "test: update golden files"
```

---

## 🔧 **COMMON TASKS**

### **Adding New Features**
1. **Create tests first** (TDD approach)
2. **Implement feature** with proper error handling
3. **Update documentation** if needed
4. **Run validation**: `./scripts/testing/ai_test_validator.sh`

### **Fixing Bugs**
1. **Write regression test** to reproduce bug
2. **Fix the issue** 
3. **Verify fix** with tests
4. **Update docs** if behavior changed

### **UI Changes**
1. **Make UI changes**
2. **Run golden tests**: `flutter test test/golden/`
3. **Update goldens if intentional**: `./scripts/testing/golden_test_manager.sh update`
4. **Commit with golden files**

---

## 🚨 **TROUBLESHOOTING**

### **Common Issues & Solutions**

#### **API Connectivity Issues**
```bash
# Test APIs
./scripts/testing/test_api_connectivity.sh

# Common fixes:
# 1. Check .env file has correct API keys
# 2. Verify internet connection
# 3. Check API rate limits
```

#### **Golden Test Failures**
```bash
# See what changed
./scripts/testing/golden_test_manager.sh diff

# If changes are intentional:
./scripts/testing/golden_test_manager.sh update
git add test/golden/
git commit -m "test: update golden files for UI changes"
```

#### **Build Failures**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk

# Check for dependency issues
flutter pub deps
```

#### **Navigation Issues**
- Check for double navigation patterns (`pushReplacement` + `pop`)
- Ensure navigation guards are in place
- Review `lib/utils/navigation_observer.dart`

---

## 📊 **QUALITY GATES**

### **Automated Checks (CI)**
- ✅ **Build Success** - Code compiles
- ✅ **Unit Tests** - Logic validation
- ✅ **Golden Tests** - Visual regression protection
- ✅ **Static Analysis** - Code quality
- ✅ **Security Scans** - Vulnerability detection
- ✅ **Performance** - No regressions

### **Manual Checks (AI Agent)**
- ✅ **Feature completeness** - Requirements met
- ✅ **Error handling** - Edge cases covered
- ✅ **Documentation** - Updated if needed
- ✅ **User experience** - Intuitive and accessible

---

## 🎯 **AI AGENT BEST PRACTICES**

### **Code Quality**
- **Follow existing patterns** in the codebase
- **Add comprehensive tests** for new features
- **Handle errors gracefully** with user feedback
- **Maintain documentation** alongside code changes

### **Testing**
- **Run tests before committing** - `./scripts/testing/ai_test_validator.sh`
- **Update golden tests** when UI changes are intentional
- **Add integration tests** for critical user flows
- **Test on multiple screen sizes** when relevant

### **Git Workflow**
- **Use conventional commits** - `feat:`, `fix:`, `docs:`, etc.
- **Create focused PRs** - one feature/fix per PR
- **Include tests** in the same commit as features
- **Update documentation** when behavior changes

---

## 📚 **KEY FILES & DIRECTORIES**

### **Core Application**
- `lib/main.dart` - App entry point
- `lib/screens/` - UI screens
- `lib/services/` - Business logic
- `lib/models/` - Data models
- `lib/utils/` - Utilities and helpers

### **Testing**
- `test/` - Unit and widget tests
- `test/golden/` - Visual regression tests
- `test/integration/` - End-to-end tests
- `scripts/testing/` - Test automation scripts

### **Configuration**
- `.env` - Environment variables (API keys)
- `pubspec.yaml` - Dependencies
- `analysis_options.yaml` - Static analysis rules

### **Documentation**
- `docs/` - Comprehensive documentation
- `CHANGELOG.md` - Version history
- `README.md` - Project overview

---

## 🔗 **QUICK LINKS**

- **[Full AI Optimization Guide](docs/development/AI_AGENT_SOLO_DEV_OPTIMIZATION.md)**
- **[DevOps Quick Reference](docs/DEVOPS_QUICK_REFERENCE.md)**
- **[Visual Regression Workflow](docs/development/visual_regression_workflow.md)**
- **[Contributing Guidelines](.github/CONTRIBUTING.md)**

---

## 🎉 **SUCCESS INDICATORS**

### **You're doing great if:**
- ✅ Tests pass consistently
- ✅ Golden tests update smoothly when needed
- ✅ CI pipeline stays green
- ✅ Features work as expected
- ✅ Documentation stays current
- ✅ No breaking changes introduced

### **Development Velocity Targets:**
- 🎯 **Feature implementation**: < 1 hour
- 🎯 **Bug fixes**: < 30 minutes  
- 🎯 **Test coverage**: > 80%
- 🎯 **CI feedback**: < 5 minutes

---

*This guide gets you productive immediately while maintaining high quality standards. The existing infrastructure handles the complexity - you focus on building great features!* 