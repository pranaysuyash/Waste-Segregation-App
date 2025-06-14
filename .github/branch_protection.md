# Branch Protection Configuration

This document outlines the required branch protection settings to prevent navigation bugs and other critical issues from reaching the main branch.

## Required Branch Protection Rules

### Main Branch Protection

Navigate to: **Settings → Branches → Add rule**

#### Basic Settings
- **Branch name pattern**: `main`
- **Restrict pushes that create files**: ✅ Enabled
- **Restrict pushes that create files larger than**: 100 MB

#### Pull Request Requirements
- **Require a pull request before merging**: ✅ Enabled
  - **Require approvals**: ✅ Enabled (minimum 1)
  - **Dismiss stale PR approvals when new commits are pushed**: ✅ Enabled
  - **Require review from code owners**: ✅ Enabled
  - **Restrict reviews to users with write access**: ✅ Enabled
  - **Allow specified actors to bypass required pull requests**: ❌ Disabled

#### Status Check Requirements
- **Require status checks to pass before merging**: ✅ Enabled
- **Require branches to be up to date before merging**: ✅ Enabled

**Required Status Checks:**
- `unit_tests`
- `navigation_tests` 
- `golden_tests`
- `static_analysis`
- `integration_tests`
- `security_checks`

#### Additional Restrictions
- **Restrict pushes that create files**: ✅ Enabled
- **Do not allow bypassing the above settings**: ✅ Enabled
- **Allow force pushes**: ❌ Disabled
- **Allow deletions**: ❌ Disabled

### Develop Branch Protection

#### Basic Settings
- **Branch name pattern**: `develop`
- **Require a pull request before merging**: ✅ Enabled
  - **Require approvals**: ✅ Enabled (minimum 1)

#### Status Check Requirements
- **Require status checks to pass before merging**: ✅ Enabled

**Required Status Checks:**
- `unit_tests`
- `navigation_tests`
- `static_analysis`

## Navigation-Specific Protection

### Pre-commit Hooks

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: navigation-pattern-check
        name: Check for double navigation patterns
        entry: scripts/check_navigation_patterns.sh
        language: script
        files: '^lib/.*\.dart$'
        
      - id: navigation-guard-check
        name: Ensure navigation guards are present
        entry: scripts/check_navigation_guards.sh
        language: script
        files: '^lib/screens/.*\.dart$'
```

### Required Files for Protection

1. **CODEOWNERS** file:
```
# Navigation-critical files require extra review
lib/screens/ @senior-developers @navigation-experts
lib/utils/navigation_observer.dart @senior-developers
test/widgets/navigation_test.dart @qa-team
```

2. **Pull Request Template** (`.github/pull_request_template.md`):
```markdown
## Navigation Changes Checklist

- [ ] No double navigation patterns (pushReplacement + pop)
- [ ] Navigation guards implemented for user interactions
- [ ] Navigation tests updated/added
- [ ] Integration tests pass
- [ ] No memory leaks in navigation controllers
```

## Enforcement Scripts

### Navigation Pattern Checker (`scripts/check_navigation_patterns.sh`)

```bash
#!/bin/bash
set -e

echo "🔍 Checking for navigation anti-patterns..."

# Check for double navigation patterns
if grep -r "pushReplacement.*pop(" lib/; then
    echo "❌ Found pushReplacement + pop pattern!"
    exit 1
fi

# Check for missing navigation guards
if ! grep -r "_isNavigating" lib/screens/; then
    echo "⚠️ Warning: No navigation guards found"
fi

echo "✅ Navigation patterns check passed"
```

### Navigation Guard Checker (`scripts/check_navigation_guards.sh`)

```bash
#!/bin/bash
set -e

echo "🛡️ Checking navigation guards..."

# Find all screen files
screen_files=$(find lib/screens -name "*.dart" -type f)

for file in $screen_files; do
    if grep -q "Navigator\.push" "$file"; then
        if ! grep -q "_isNavigating\|navigationGuard" "$file"; then
            echo "⚠️ $file has navigation but no guard"
        fi
    fi
done

echo "✅ Navigation guard check complete"
```

## Testing Requirements

### Mandatory Tests Before Merge

1. **Navigation Unit Tests**: Must pass all navigation logic tests
2. **Integration Tests**: Must verify end-to-end navigation flows
3. **Golden Tests**: Must pass visual regression tests
4. **Performance Tests**: Must not introduce memory leaks

### Test Coverage Requirements

- **Navigation code**: 100% coverage required
- **Screen transitions**: All paths must be tested
- **Error scenarios**: Navigation failures must be handled

## Monitoring and Alerts

### Post-Merge Monitoring

1. **Crashlytics Rules**: Alert on navigation-related crashes
2. **Performance Monitoring**: Track navigation timing
3. **User Analytics**: Monitor navigation abandonment rates

### Automated Rollback Triggers

- Navigation crash rate > 1%
- Performance regression > 20%
- User abandonment rate increase > 10%

## Emergency Procedures

### Hotfix Process

1. Create hotfix branch from main
2. Apply minimal fix with tests
3. Fast-track review with navigation expert
4. Deploy with monitoring

### Rollback Process

1. Immediate revert of problematic commit
2. Post-mortem analysis
3. Enhanced testing for similar patterns
4. Process improvement implementation

## Review Guidelines

### Navigation Code Review Checklist

- [ ] Single responsibility for navigation methods
- [ ] Proper error handling and user feedback
- [ ] Navigation guards implemented
- [ ] Memory management (dispose controllers)
- [ ] Accessibility considerations
- [ ] Performance impact assessment

### Required Reviewers

- **Navigation changes**: Senior developer + QA
- **Screen additions**: UI/UX designer + developer
- **Critical paths**: Product owner + tech lead

This configuration ensures that navigation bugs like the double navigation issue cannot reach the main branch without proper review and testing. 