---
name: Navigation Bug Report
about: Report navigation-related issues, double navigation, or routing problems
title: '[NAVIGATION] '
labels: ['bug', 'navigation', 'high-priority']
assignees: ''

---

## 🧭 Navigation Bug Report

### Bug Description
A clear and concise description of the navigation issue.

### Navigation Pattern
- [ ] Double navigation (same screen appears twice)
- [ ] Navigation stack corruption
- [ ] Route not found
- [ ] Back navigation issues
- [ ] Tab navigation problems
- [ ] Deep linking issues
- [ ] Other: ___________

### Steps to Reproduce
1. Go to '...'
2. Tap on '....'
3. Navigate to '....'
4. See error

### Expected Navigation Behavior
A clear description of what should happen.

### Actual Navigation Behavior
A clear description of what actually happens.

### Navigation Stack Information
If possible, provide information about the navigation stack:
- Initial route count: 
- Final route count:
- Routes in stack:

### Screenshots/Screen Recording
If applicable, add screenshots or screen recordings to help explain the problem.

### Device Information
- Device: [e.g. iPhone 15, Pixel 7]
- OS: [e.g. iOS 17.1, Android 14]
- App Version: [e.g. 2.3.2]
- Flutter Version: [e.g. 3.16.0]

### Console Logs
Please include relevant console logs, especially navigation-related logs:
```
🧭 NAVIGATION PUSH: ...
🧭 NAVIGATION POP: ...
```

### Testing Checklist
Before submitting, please verify:
- [ ] Issue is reproducible on multiple devices
- [ ] Issue occurs in both debug and release builds
- [ ] Navigation tests are failing (if applicable)
- [ ] No duplicate issues exist

### Additional Context
Add any other context about the problem here.

### Potential Fix
If you have ideas about what might be causing the issue or how to fix it, please share.

---

## For Developers

### Investigation Checklist
- [ ] Check for conflicting Navigator calls (pushReplacement + pop)
- [ ] Verify navigation guards are in place
- [ ] Review Navigator.of(context) vs Navigator.push usage
- [ ] Check for provider/stream listeners triggering navigation
- [ ] Verify proper error handling in navigation methods
- [ ] Test with DebugNavigatorObserver enabled

### Testing Requirements
- [ ] Add/update navigation unit tests
- [ ] Add/update integration tests
- [ ] Verify golden tests still pass
- [ ] Test on multiple devices and orientations
- [ ] Verify accessibility navigation works

### Code Review Focus
- [ ] Navigation method single responsibility
- [ ] Proper error handling and user feedback
- [ ] Navigation guards implemented
- [ ] Memory management (dispose controllers)
- [ ] Performance impact assessment 