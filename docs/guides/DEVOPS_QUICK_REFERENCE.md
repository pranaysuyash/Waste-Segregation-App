# 🎯 DevOps Quick Reference Guide

*Essential commands and procedures for your enhanced Waste Segregation App repository*

## 🚀 **Daily Development Workflow**

### Starting New Work

```bash
# Always start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feat/new-feature-name
```

### Before Committing

```bash
# Format code
dart format .

# Run static analysis  
flutter analyze --fatal-infos

# Run tests locally
flutter test --coverage --exclude-tags=golden

# If UI changes made, update golden tests
./scripts/testing/golden_test_manager.sh update
```

### Committing Changes

```bash
# Use conventional commits
git add .
git commit -m "feat(classification): add new plastic detection algorithm"

# Push and create PR
git push origin feat/new-feature-name
```

---

## 🧪 **Testing Commands**

### Unit Tests

```bash
# Run all unit tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/ai_classification_test.dart

# Run tests excluding golden tests
flutter test --exclude-tags=golden
```

### Golden Tests (Visual Regression)

```bash
# Run golden tests
flutter test test/golden/

# Update golden files (only if changes are intentional)
./scripts/testing/golden_test_manager.sh update

# View golden test failures
open test/golden/failures/
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run with performance profiling
flutter test integration_test/ --profile
```

---

## 🔒 **Security Operations**

### Manual Security Scans

```bash
# Check for secrets locally
grep -r "api_key\|password\|secret" . --exclude-dir=.git --exclude-dir=build

# Check dependencies for vulnerabilities
flutter pub outdated

# Analyze dependency tree
flutter pub deps --json
```

### Reviewing Security Alerts

1. Go to **Security** tab in GitHub
2. Review **Dependabot alerts**
3. Check **Code scanning alerts**
4. Monitor **Secret scanning alerts**

---

## 📦 **Dependency Management**

### Manual Dependency Updates

```bash
# Check for outdated packages
flutter pub outdated

# Update specific package
flutter pub add package_name:^latest_version

# Update all dependencies (careful!)
flutter pub upgrade
```

### Dependabot PR Review Process

1. **Review Dependabot PRs weekly**
2. **Check change logs** for breaking changes
3. **Test locally** before merging:

   ```bash
   git checkout dependabot/pub/package_name
   flutter test
   flutter build apk --debug
   ```

4. **Merge if tests pass**

---

## 🚀 **Release Management**

### Creating a Release

```bash
# 1. Update version in pubspec.yaml
# 2. Update CHANGELOG.md with new version
# 3. Commit changes
git add .
git commit -m "chore: bump version to v2.2.5"

# 4. Create and push tag
git tag v2.2.5
git push origin v2.2.5

# 5. Automated release will trigger
# 6. Check GitHub Releases for artifacts
```

### Emergency Hotfix Release

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-bug-fix

# Make minimal fix
# Test thoroughly
# Create PR to main
# After merge, tag immediately
git tag v2.2.6
git push origin v2.2.6
```

---

## 📊 **Performance Monitoring**

### Local Performance Testing

```bash
# Build with size analysis
flutter build apk --release --analyze-size

# Run performance tests
flutter test integration_test/performance_test.dart

# Profile memory usage
flutter test integration_test/ --profile
```

### Monitoring CI Performance

1. Check **Actions** tab for performance workflow
2. Download **performance-analysis** artifacts
3. Review performance trends over time
4. Act on recommendations in performance reports

---

## 🎨 **UI/UX Development**

### Golden Test Workflow

```bash
# 1. Make UI changes
# 2. Run golden tests to see differences
flutter test test/golden/

# 3. If changes are intentional:
./scripts/testing/golden_test_manager.sh update

# 4. If changes are NOT intentional:
# Fix the regression before continuing
```

### Dark Mode Testing

```bash
# Test in both themes
flutter test test/golden/ --tags=theme-light
flutter test test/golden/ --tags=theme-dark
```

### Accessibility Testing

```bash
# Run accessibility tests
flutter test test/accessibility/

# Check semantic labels
flutter test --tags=accessibility
```

---

## 🔧 **Troubleshooting**

### CI Pipeline Failures

#### Build Job Fails

```bash
# Common solutions:
flutter clean
flutter pub get
dart format .
flutter analyze --fatal-infos
```

#### Golden Tests Fail

```bash
# If changes are intentional:
./scripts/testing/golden_test_manager.sh update
git add test/golden/
git commit -m "test: update golden files for UI changes"

# If changes are NOT intentional:
# Review visual diff in test/golden/failures/
# Fix the regression
```

#### Security Scan Fails

1. Review security tab in GitHub
2. Address vulnerabilities in dependencies
3. Fix any exposed secrets
4. Re-run security workflow

#### Performance Issues

1. Check performance artifacts
2. Review build size and timing
3. Optimize based on recommendations
4. Profile on physical devices

### Local Development Issues

#### Flutter Doctor Issues

```bash
flutter doctor -v
# Fix any issues shown
```

#### Dependency Conflicts

```bash
flutter pub deps
flutter pub cache repair
flutter clean
flutter pub get
```

#### Git Workflow Issues

```bash
# Reset to clean state
git reset --hard origin/develop
git clean -fd

# Fix merge conflicts
git status
# Edit conflicted files
git add .
git commit
```

---

## 📋 **Weekly Maintenance Checklist**

### Monday Morning Review

- [ ] Review Dependabot PRs
- [ ] Check security alerts
- [ ] Review performance trends
- [ ] Triage new issues

### Development Quality Checks

- [ ] Review code coverage trends
- [ ] Check for outdated documentation
- [ ] Validate CI pipeline health
- [ ] Monitor build performance

### Release Planning

- [ ] Review changelog completeness
- [ ] Plan next release timeline
- [ ] Check for breaking changes
- [ ] Validate release artifacts

---

## 🎯 **Emergency Procedures**

### Critical Bug in Production

1. **Create hotfix branch** from `main`
2. **Make minimal fix** with tests
3. **Fast-track PR review**
4. **Tag and release immediately**
5. **Monitor release deployment**

### Security Vulnerability

1. **Assess severity** (Critical/High/Medium)
2. **Create private branch** if needed
3. **Fix vulnerability** with tests
4. **Security review** before merge
5. **Coordinate disclosure** if external

### CI Pipeline Down

1. **Check GitHub Status** page
2. **Run tests locally** before merge
3. **Use manual verification** temporarily
4. **Document temporary procedures**

---

## 🔗 **Quick Links**

- **Repository**: [GitHub Repo](../../)
- **Actions**: [CI/CD Pipelines](../../actions)
- **Security**: [Security Overview](../../security)
- **Releases**: [All Releases](../../releases)
- **Documentation**: [docs/](../../docs/)
- **Issues**: [Issue Tracker](../../issues)

---

## 💡 **Pro Tips**

- **Always test UI changes** with golden tests before committing
- **Review Dependabot PRs promptly** to avoid accumulation
- **Use draft PRs** for work-in-progress discussions
- **Tag releases immediately** after merging to main
- **Monitor performance trends** for gradual regressions
- **Keep changelog updated** as you develop
- **Use conventional commits** for automated processing

---

*This guide covers your sophisticated DevOps setup. Bookmark this for daily reference!*
