# Contributing to ReLoop

Thank you for your interest in contributing to our AI-powered waste segregation application! This guide will help you get started with our sophisticated development workflow.

## 🚀 Quick Start

1. **Fork & Clone**: Fork the repository and clone your fork
2. **Environment Setup**: Follow the [README.md](../README.md) setup instructions
3. **Branch Strategy**: Create feature branches from `develop` 
4. **Testing**: Our advanced CI pipeline will validate your changes

## 🏗️ Development Workflow

### Branch Strategy
- `main` - Production-ready code with releases
- `develop` - Integration branch for new features
- `feature/*` - New features and enhancements
- `fix/*` - Bug fixes and patches
- `docs/*` - Documentation updates

### Commit Guidelines
Follow conventional commits format:
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

**Examples**:
```
feat(classification): add new AI model for plastic detection
fix(ui): resolve achievement celebration animation timing
docs(contributing): update golden test procedures
test(integration): add waste classification accuracy tests
```

## 🧪 Testing Framework

We have a sophisticated testing infrastructure that you must understand:

### 1. Unit Tests
```bash
flutter test --coverage --exclude-tags=golden
```

### 2. Golden Tests (Visual Regression)
Our **advanced visual regression testing** automatically detects UI changes:

```bash
# Run golden tests
flutter test test/golden/

# Update golden files (only if changes are intentional)
./scripts/testing/golden_test_manager.sh update
```

**Important**: Golden test failures will block PRs until resolved!

#### Updating Golden Files — Policy ✅
- Keep canonical golden master images under `test/golden/golden/` only. These masters are the single source of truth and should be reviewed carefully before updating.
- DO NOT commit any generated failure artifacts (diffs, masked images, isolated diffs, temporary test images). These live under `test/golden/failures/` or `test/widgets/failures/` and are ignored by `.gitignore`.
- To intentionally update masters: run `./scripts/testing/golden_test_manager.sh update`, review the changes, and commit only the master images from `test/golden/golden/`.
- To inspect failures locally, examine `test/golden/failures/` but do not add those files to your commit.
- CI will automatically reject PRs that add files under `**/failures/**` to prevent noisy commits.


### 3. Integration Tests
```bash
flutter test integration_test/
```

### 4. AI Classification Tests
Test the AI models with various waste types:
```bash
flutter test test/ai/ --tags=ai-classification
```

## 🎨 UI/UX Guidelines

### Design System
- Follow Material Design 3 principles
- Use the established color palette and typography
- Maintain accessibility standards (WCAG 2.1 AA)
- Test in both light and dark modes

### Visual Regression Protocol
1. **Before making UI changes**: Run golden tests to establish baseline
2. **After changes**: Golden tests will automatically detect differences
3. **If intentional**: Update golden files using the script
4. **If unintentional**: Fix the regression before continuing

### Animation Standards
- Use standardized durations from `lib/utils/animation_constants.dart`
- Test animations on both high-end and low-end devices
- Ensure animations respect accessibility preferences

## 🤖 AI & Machine Learning

### Classification System
- Test with diverse waste samples
- Validate accuracy across different lighting conditions
- Ensure consistent performance across devices

### Model Updates
- Document any AI model changes thoroughly
- Include accuracy metrics and validation results
- Test backward compatibility

## 📝 Documentation

### Required Documentation
- Update relevant files in `/docs/` directory
- Follow the [Documentation Index](docs/DOCUMENTATION_INDEX.md) structure
- Include code examples for new features

### Documentation Categories
- **Status documents** → `/docs/status/`
- **Technical guides** → `/docs/technical/`
- **Feature docs** → `/docs/features/`
- **Fix summaries** → `/docs/fixes/`

### Documentation Integrity Rule

**Code wins over docs.** When a doc and the code contradict each other, trust the code.

Exception: docs explicitly marked `[CURRENT — verified YYYY-MM-DD]` have been recently
hand-verified against the codebase and can be trusted until that date expires (90 days).

Docs marked `[STALE]` or `[ASPIRATIONAL]` describe intended future state, not current reality.

When you verify a doc is accurate, add `[CURRENT — verified YYYY-MM-DD]` to its title.
When you find a doc is outdated, add the STALE banner (see `docs/implementation/ai/api_key_management_and_security.md` for example format).

The canonical source of truth for the AI pipeline is:
`docs/architecture/CURRENT_AI_ARCHITECTURE.md`

## 🔍 Code Review Process

### Before Submitting PR
1. ✅ Run all tests locally: `flutter test`
2. ✅ Check formatting: `dart format --set-exit-if-changed .`
3. ✅ Run static analysis: `flutter analyze --fatal-infos`
4. ✅ Update documentation if needed
5. ✅ Test on physical device

### PR Requirements
- [ ] All CI checks pass (build, test, golden tests, code quality)
- [ ] No visual regressions (unless intentional and documented)
- [ ] Documentation updated for new features
- [ ] Tests added for new functionality
- [ ] Breaking changes documented in PR description

### PR Review Criteria
- **Functionality**: Does it work as intended?
- **Performance**: No performance regressions
- **UI/UX**: Consistent with design system
- **Testing**: Adequate test coverage
- **Documentation**: Clear and complete

## 🏆 Quality Standards

### Code Quality
- Maintain >85% test coverage
- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add comments for complex logic

### Performance
- Profile performance-critical code
- Optimize for low-end devices
- Monitor memory usage and battery impact

### Accessibility
- Test with screen readers
- Ensure proper color contrast
- Support keyboard navigation where applicable

## 🚨 Common Issues & Solutions

### Golden Test Failures
```bash
# If you see "Golden tests failed - Visual regressions detected!"
# 1. Check if changes are intentional
# 2. If yes, update golden files:
./scripts/testing/golden_test_manager.sh update

# 3. If no, investigate the visual differences in test/golden/failures/
```

### Build Failures
- Check Flutter version matches CI (3.24.5)
- Clear build cache: `flutter clean && flutter pub get`
- Check for dependency conflicts

### CI Pipeline Issues
- **Build job**: Usually dependency or compilation issues
- **Test job**: Unit test failures or coverage issues  
- **Golden Tests**: Visual regression detection
- **Code Quality**: Formatting or analysis issues

## 📊 Metrics & Monitoring

We track several key metrics:
- Test coverage percentage
- Build success rate
- Golden test stability
- AI classification accuracy
- Performance benchmarks

## 🎯 Getting Help

### Resources
- [Project Documentation](docs/DOCUMENTATION_INDEX.md)
- [Architecture Decisions](docs/technical/architecture/DESIGN_DECISIONS.md)
- [Current Issues](docs/status/CURRENT_ISSUES_SUMMARY.md)
- [Testing Guide](docs/testing/TESTING_INFRASTRUCTURE_SUCCESS_SUMMARY.md)

### Communication
- Create issues for bugs or feature requests
- Use draft PRs for work-in-progress discussions
- Tag reviewers based on the area of change

## 🌟 Recognition

Contributors who consistently provide high-quality contributions may be invited to become maintainers with additional repository permissions.

---

**Thank you for helping make waste segregation more accessible and effective through technology!**

*This contributing guide reflects our advanced development practices and sophisticated CI/CD infrastructure.*