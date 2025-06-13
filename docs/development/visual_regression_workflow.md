# Visual Regression Testing Workflow

## 🎯 Purpose

This workflow protects the main branch from visual regressions while allowing rapid AI-assisted development. Golden tests capture UI screenshots and compare them against approved reference images.

## 🤖 For AI Agents

When making UI changes, you may encounter golden test failures. Here's how to handle them:

### ✅ If Changes Are Intentional
```bash
# Update golden files to reflect new UI
./scripts/testing/golden_test_manager.sh update

# Commit the updated golden files
git add test/golden/
git commit -m "Update golden files for intentional UI changes"
```

### ❌ If Changes Are Regressions
```bash
# Check what visual differences exist
./scripts/testing/golden_test_manager.sh diff

# Fix the UI issues in your code
# Then verify tests pass
./scripts/testing/golden_test_manager.sh run
```

## 🔄 Development Workflow

### 1. Making UI Changes
```bash
# Make your UI changes
# ...

# Test locally
./scripts/testing/golden_test_manager.sh run
```

### 2. If Golden Tests Fail
```bash
# View the differences
./scripts/testing/golden_test_manager.sh diff

# If changes are intentional:
./scripts/testing/golden_test_manager.sh update

# If changes are bugs, fix them and re-test
```

### 3. Before Pushing
```bash
# Validate all tests pass
./scripts/testing/golden_test_manager.sh validate
```

## 🛡️ Branch Protection

The main branch is protected with these rules:

- ✅ **Golden Tests Required**: All visual regression tests must pass
- ✅ **PR Reviews Required**: Code changes need approval
- ✅ **Up-to-date Required**: Branch must be current with main
- ✅ **Status Checks**: CI pipeline must complete successfully

## 📊 What Gets Tested

### Current Golden Tests:
- **Home Screen**: Light/dark themes, guest mode, responsive layouts
- **Quick Action Cards**: Various states and themes
- **Recent Classifications**: Different data states
- **Settings Screen**: All configuration options
- **Stats Cards**: Progress indicators and badges

### Adding New Golden Tests:
```dart
testWidgets('my component golden test', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: MyComponent()),
  );
  
  await tester.pumpAndSettle();
  
  await expectLater(
    find.byType(MyComponent),
    matchesGoldenFile('my_component.png'),
  );
});
```

## 🚨 CI/CD Integration

### Automated Checks:
- **PR Creation**: Golden tests run automatically
- **Failure Detection**: PR is blocked if visual regressions found
- **Artifact Upload**: Diff images uploaded for review
- **PR Comments**: Automated feedback with next steps

### Manual Override:
If you need to merge despite golden test failures (emergency fixes):
1. Get admin approval
2. Use "Merge without waiting for requirements"
3. Fix golden tests in immediate follow-up PR

## 🎨 Visual Diff Analysis

### Understanding Failures:
- **Pixel Differences**: Exact pixel-by-pixel comparison
- **Layout Shifts**: Changes in component positioning
- **Color Changes**: Theme or styling modifications
- **Font Rendering**: Text appearance differences

### Common Causes:
- **Intentional Design Changes**: Update goldens
- **Dependency Updates**: May affect rendering
- **Platform Differences**: CI vs local environment
- **Animation Timing**: Use `pumpAndSettle()`

## 🔧 Troubleshooting

### Golden Tests Won't Update:
```bash
# Clean old artifacts
./scripts/testing/golden_test_manager.sh clean

# Force update
flutter test test/golden/ --update-goldens --verbose
```

### CI Fails But Local Passes:
```bash
# Use same Flutter version as CI
flutter --version

# Run in CI-like environment
flutter test test/golden/ --reporter=json
```

### Large Golden File Sizes:
- Keep test widgets focused and small
- Use specific finders instead of full screen captures
- Consider testing components in isolation

## 📈 Benefits for AI Development

### 🤖 **Rapid Development Safety**
- AI agents can make sweeping changes confidently
- Visual regressions caught automatically
- No need for manual UI review on every change

### 🔍 **Regression Prevention**
- Catches subtle layout shifts
- Detects unintended color/theme changes
- Prevents broken responsive layouts

### 📊 **Development Confidence**
- Clear pass/fail criteria for UI changes
- Visual evidence of what changed
- Easy rollback if issues found

### 🚀 **Faster Iteration**
- Automated visual validation
- No manual screenshot comparison
- Immediate feedback on UI changes

## 🎯 Best Practices

### For AI Agents:
1. **Always run golden tests** before pushing UI changes
2. **Update goldens intentionally** when design changes are planned
3. **Check diff artifacts** when tests fail to understand changes
4. **Document UI changes** in commit messages

### For Developers:
1. **Review golden updates** carefully before approving
2. **Test on multiple screen sizes** when adding new goldens
3. **Keep golden tests focused** on specific components
4. **Update documentation** when adding new visual tests

---

> 💡 **Remember**: Golden tests are your safety net for UI changes. They catch what unit tests miss and give you confidence in rapid development cycles. 