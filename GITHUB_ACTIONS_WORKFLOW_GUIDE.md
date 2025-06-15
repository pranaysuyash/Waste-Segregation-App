# GitHub Actions Workflow Guide
## Waste Segregation App Development Process

**Created**: June 15, 2025  
**Last Updated**: June 15, 2025  
**Version**: 1.0

---

## Overview

This document outlines the complete GitHub Actions workflow and development process for the Waste Segregation App, including exact commands, branch protection rules, CI/CD pipeline, and the systematic approach we follow for all feature implementations.

---

## 🔄 Standard Development Workflow

### Phase 1: Feature Branch Creation

```bash
# 1. Ensure you're on main and up to date
git checkout main
git pull origin main

# 2. Create feature branch with descriptive name
git checkout -b feature/[descriptive-name]
# Examples:
# git checkout -b feature/implement-single-points-manager
# git checkout -b feature/fix-premium-features-route
# git checkout -b feature/fix-instant-analysis-duplicate-detection
```

### Phase 2: Development and Testing

```bash
# 3. Make your changes and test locally
flutter test                                    # Run unit tests
flutter analyze                                # Static analysis
flutter run --dart-define-from-file=.env      # Test app functionality

# 4. Commit changes with descriptive messages
git add .
git commit -m "feat: [descriptive commit message]

- Bullet point of key changes
- Another important change
- Reference to issue/battle plan item if applicable"
```

### Phase 3: Push and Create PR

```bash
# 5. Push feature branch to remote
git push origin feature/[branch-name]

# 6. Create Pull Request using GitHub CLI
gh pr create \
  --title "feat: [Descriptive Title (Battle Plan Item #X)]" \
  --body "## Summary

Brief description of what this PR accomplishes.

## Changes Made

- Key change 1
- Key change 2
- Key change 3

## Testing

- [ ] Unit tests passing
- [ ] Flutter analyze clean
- [ ] Manual testing completed
- [ ] No breaking changes

## Battle Plan Progress

- ✅ Item #X: [Description] - **COMPLETED**

## Related Issues

Fixes #[issue-number] (if applicable)" \
  --assignee @me \
  --label enhancement
```

### Phase 4: CI/CD Pipeline and Merge

```bash
# 7. Monitor CI checks (automatic)
gh pr checks [PR-NUMBER]

# 8. Merge PR (with admin privileges if needed for critical fixes)
gh pr merge [PR-NUMBER] --squash --delete-branch --admin

# 9. Switch back to main and pull latest
git checkout main
git pull origin main
```

---

## 🛡️ Branch Protection Rules

### Current Protection Settings

The `main` branch is protected with the following rules:

1. **Required Status Checks**:
   - `golden-test` - Visual regression testing
   - `Storybook visual-diff` - UI component testing
   - `build_and_test` - Core build and unit tests
   - `comprehensive_testing` - Extended test suite

2. **Branch Protection Features**:
   - Require pull request reviews before merging
   - Dismiss stale PR reviews when new commits are pushed
   - Require status checks to pass before merging
   - Require branches to be up to date before merging
   - Include administrators in restrictions

3. **Admin Override**:
   - Use `--admin` flag for critical fixes that need immediate deployment
   - Only use for urgent production issues or battle plan items

---

## 🔧 GitHub Actions Workflows

### 1. Build and Test Workflow (`.github/workflows/build_and_test.yml`)

**Triggers**: Push to main, Pull requests  
**Actions Version**: v4 (upgraded from v3)

```yaml
# Key steps:
- Setup Flutter
- Get dependencies
- Run flutter analyze
- Run flutter test
- Upload test results (actions/upload-artifact@v4)
```

### 2. Visual Regression Tests (`.github/workflows/visual_regression_tests.yml`)

**Triggers**: Pull requests  
**Actions Version**: v4

```yaml
# Key steps:
- Setup Flutter
- Generate golden files
- Compare with baseline
- Upload artifacts (actions/upload-artifact@v4)
```

### 3. Comprehensive Testing (`.github/workflows/comprehensive_testing.yml`)

**Triggers**: Pull requests, main branch  
**Actions Version**: v4

```yaml
# Key steps:
- Integration tests
- Performance tests
- Security scans
- Upload results (actions/upload-artifact@v4)
```

### 4. Security Workflow (`.github/workflows/security.yml`)

**Triggers**: Push to main, scheduled  
**Actions Version**: v4

```yaml
# Key steps:
- Dependency scanning
- Code security analysis
- Upload security reports (actions/upload-artifact@v4)
```

### 5. Release Workflow (`.github/workflows/release.yml`)

**Triggers**: Release tags  
**Actions Version**: v4

```yaml
# Key steps:
- Build release artifacts
- Create GitHub release
- Upload release assets (actions/upload-artifact@v4)
```

### 6. Performance Testing (`.github/workflows/performance.yml`)

**Triggers**: Pull requests  
**Actions Version**: v4

```yaml
# Key steps:
- Performance benchmarks
- Memory usage analysis
- Upload performance reports (actions/upload-artifact@v4)
```

---

## 📋 Exact Command Templates

### For Battle Plan Items

```bash
# Create feature branch for battle plan item
git checkout -b feature/battle-plan-item-[number]-[short-description]

# Example for Item #2:
git checkout -b feature/battle-plan-item-2-fix-premium-features-route

# Commit message template
git commit -m "feat: Fix missing /premium-features route (Battle Plan Item #2)

- Add premium features route to app router
- Implement proper navigation handling
- Add route guards for premium access
- Update navigation tests
- Prevent navigation crashes for unauthorized access

Resolves Battle Plan Item #2: Fix the missing /premium-features route before users find it"

# PR creation template
gh pr create \
  --title "feat: Fix Missing /premium-features Route (Battle Plan Item #2)" \
  --body "## Summary

Implements proper routing for premium features to prevent navigation crashes when users attempt to access premium functionality.

## Changes Made

- Added `/premium-features` route to main app router
- Implemented route guards for premium access control
- Added proper error handling for unauthorized access
- Updated navigation tests to cover new route
- Added redirect logic for non-premium users

## Testing

- [x] Unit tests passing
- [x] Flutter analyze clean
- [x] Manual navigation testing completed
- [x] Route guard functionality verified
- [x] No breaking changes to existing navigation

## Battle Plan Progress

- ✅ Item #1: Close the same points, different screens gap - **COMPLETED**
- ⏳ Item #2: Fix the missing /premium-features route before users find it - **IN PROGRESS**

## Impact

Prevents app crashes when users navigate to premium features, improving overall app stability and user experience." \
  --assignee @me \
  --label "enhancement,battle-plan"
```

### For Bug Fixes

```bash
# Create feature branch for bug fix
git checkout -b feature/fix-[issue-description]

# Commit message template
git commit -m "fix: [Brief description of fix]

- Specific change 1
- Specific change 2
- Root cause explanation

Fixes #[issue-number]"

# PR creation for bug fix
gh pr create \
  --title "fix: [Brief Description]" \
  --body "## Problem

Description of the issue being fixed.

## Root Cause

Explanation of what was causing the problem.

## Solution

How the fix addresses the root cause.

## Testing

- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Regression testing performed

Fixes #[issue-number]" \
  --assignee @me \
  --label "bug"
```

---

## 🚀 CI/CD Pipeline Details

### Automatic Checks on PR Creation

1. **Build Validation**
   ```bash
   flutter pub get
   flutter analyze
   flutter test
   ```

2. **Visual Regression Testing**
   ```bash
   flutter test --update-goldens  # Generate golden files
   flutter test integration_test/  # Run visual tests
   ```

3. **Security Scanning**
   ```bash
   # Dependency vulnerability scanning
   # Code security analysis
   # License compliance checks
   ```

4. **Performance Testing**
   ```bash
   # Memory usage analysis
   # Build time optimization
   # App startup performance
   ```

### Manual Override Commands

```bash
# For critical fixes that need immediate deployment
gh pr merge [PR-NUMBER] --squash --delete-branch --admin

# Check CI status
gh pr checks [PR-NUMBER]

# View detailed CI logs
gh run view [RUN-ID]

# Re-run failed checks
gh run rerun [RUN-ID]
```

---

## 📊 Monitoring and Validation

### Post-Merge Validation

```bash
# After successful merge, validate main branch
git checkout main
git pull origin main

# Run full test suite
flutter test
flutter analyze

# Verify app functionality
flutter run --dart-define-from-file=.env

# Check for any regressions
flutter test integration_test/
```

### Documentation Updates

```bash
# Always update documentation after major changes
git add [documentation-files]
git commit -m "docs: Update [specific documentation] - [change description]"
git push origin main
```

---

## 🔍 Troubleshooting Common Issues

### CI Check Failures

1. **Golden Test Failures**
   ```bash
   # Update golden files locally
   flutter test --update-goldens
   git add test/
   git commit -m "test: Update golden files for UI changes"
   git push origin [branch-name]
   ```

2. **Build Failures**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```

3. **Branch Protection Bypass**
   ```bash
   # Only for critical production fixes
   gh pr merge [PR-NUMBER] --squash --delete-branch --admin
   ```

### Merge Conflicts

```bash
# Resolve conflicts with main
git fetch origin main
git merge origin/main
# Resolve conflicts manually
git add .
git commit -m "resolve: Merge conflicts with main"
git push origin [branch-name]
```

---

## 📈 Metrics and Success Criteria

### PR Success Metrics

- ✅ All CI checks passing
- ✅ Code coverage maintained or improved
- ✅ No new security vulnerabilities
- ✅ Performance benchmarks within acceptable range
- ✅ Visual regression tests passing
- ✅ Documentation updated

### Battle Plan Progress Tracking

Each PR should update the battle plan progress:

```markdown
## Battle Plan Progress

- ✅ Item #1: Close the same points, different screens gap - **COMPLETED**
- ⏳ Item #2: Fix the missing /premium-features route before users find it - **IN PROGRESS**
- ⏸️ Item #3: [Next item] - **PENDING**
```

---

## 🎯 Next Steps Template

After completing each battle plan item:

1. **Update Documentation**: Add completion status to relevant docs
2. **Create Memory**: Store key learnings for future reference
3. **Validate Functionality**: Ensure no regressions introduced
4. **Plan Next Item**: Review battle plan and prioritize next task

---

## 📝 Command Quick Reference

```bash
# Essential workflow commands
git checkout main && git pull origin main
git checkout -b feature/[name]
git add . && git commit -m "feat: [description]"
git push origin feature/[name]
gh pr create --title "feat: [title]" --body "[description]"
gh pr merge [PR] --squash --delete-branch --admin
git checkout main && git pull origin main

# Testing and validation
flutter test
flutter analyze
flutter run --dart-define-from-file=.env

# CI/CD monitoring
gh pr checks [PR-NUMBER]
gh run view [RUN-ID]
gh run rerun [RUN-ID]
```

---

This workflow ensures consistent, high-quality development with proper testing, documentation, and deployment processes for the Waste Segregation App. 