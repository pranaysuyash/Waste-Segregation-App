## 📋 Pull Request Summary

### Description
<!-- Provide a clear and concise description of what this PR accomplishes -->

### Related Issues
<!-- Link related issues using "Closes #123" or "Fixes #123" -->
- Closes #<!-- issue number -->

### Type of Change
<!-- Mark with an x the type of change this PR represents -->
- [ ] 🐛 Bug fix (non-breaking change that fixes an issue)
- [ ] ✨ New feature (non-breaking change that adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📝 Documentation update
- [ ] 🎨 UI/UX improvement
- [ ] 🔧 Refactoring (no functional changes)
- [ ] ⚡ Performance improvement
- [ ] 🧪 Test coverage improvement
- [ ] 🤖 AI/ML model update

### 🧪 Testing Checklist

#### Automated Testing
- [ ] All unit tests pass (`flutter test --exclude-tags=golden`)
- [ ] Golden tests pass or updated if UI changes are intentional
- [ ] Integration tests pass
- [ ] Code coverage maintained or improved

#### Manual Testing
- [ ] Tested on Android device/emulator
- [ ] Tested on iOS device/simulator (if applicable)
- [ ] Tested in both light and dark modes
- [ ] Tested with different screen sizes
- [ ] Tested offline functionality (if applicable)
- [ ] Tested with real camera/waste classification (if applicable)

#### Code Quality
- [ ] Code follows project style guidelines (`dart format`)
- [ ] Static analysis passes (`flutter analyze --fatal-infos`)
- [ ] No new warnings or errors introduced
- [ ] Performance impact assessed (if applicable)

### 🎨 UI/UX Changes
<!-- If this PR includes UI changes, provide details -->

#### Visual Changes
- [ ] No visual changes
- [ ] Minor visual adjustments
- [ ] Significant UI redesign
- [ ] New screens or components

#### Golden Tests
- [ ] No golden test updates needed
- [ ] Golden tests updated with `./scripts/testing/golden_test_manager.sh update`
- [ ] Visual regression intentionally introduced (explain below)

<!-- If golden tests were updated, explain why the visual changes were necessary -->
**Golden Test Update Justification:**
<!-- Explain why the visual changes were necessary and intentional -->

### 🤖 AI/ML Changes
<!-- If this PR affects AI classification or machine learning features -->
- [ ] No AI/ML changes
- [ ] AI model parameters updated
- [ ] New classification categories added
- [ ] Training data modifications
- [ ] Accuracy improvements validated

**AI Changes Details:**
<!-- Provide details about AI/ML modifications and their impact -->

### 🔄 Migration Guide
<!-- If this is a breaking change, provide migration instructions -->
- [ ] No breaking changes
- [ ] Breaking changes documented in MIGRATION_GUIDE.md
- [ ] Backward compatibility maintained

### 📱 Platform-Specific Changes
<!-- Mark platforms affected by this change -->
- [ ] Android
- [ ] iOS  
- [ ] Web
- [ ] macOS
- [ ] Windows
- [ ] All platforms

### 📊 Performance Impact
<!-- Assess performance implications -->
- [ ] No performance impact expected
- [ ] Performance improvements included
- [ ] Potential performance regression (explain below)
- [ ] Performance testing completed

**Performance Notes:**
<!-- Explain any performance considerations -->

### 🔒 Security Considerations
<!-- Security implications of this change -->
- [ ] No security implications
- [ ] Security improvements included
- [ ] New permissions required (document below)
- [ ] Data handling changes (document below)

### 📸 Screenshots/Videos
<!-- Include screenshots or videos demonstrating the changes -->

#### Before
<!-- Screenshots/videos of the current behavior -->

#### After  
<!-- Screenshots/videos of the new behavior -->

### 📝 Documentation Updates
- [ ] README.md updated
- [ ] CHANGELOG.md updated
- [ ] API documentation updated
- [ ] Code comments added/updated
- [ ] Architecture documentation updated (if applicable)

### 🚀 Deployment Notes
<!-- Any special deployment considerations -->
- [ ] No special deployment requirements
- [ ] Database migrations required
- [ ] Environment variables updated
- [ ] Third-party service configuration changes

### ✅ Final Checklist
<!-- Final verification before merge -->
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

### 🎯 Reviewer Guidelines
<!-- Help reviewers focus on what matters most -->

#### Focus Areas
<!-- What should reviewers pay special attention to? -->
- [ ] Logic correctness
- [ ] Performance implications  
- [ ] Security considerations
- [ ] UI/UX consistency
- [ ] Test coverage
- [ ] Documentation clarity

#### Testing Instructions
<!-- Specific steps for reviewers to test this change -->
1. 
2. 
3. 

---

**Additional Notes:**
<!-- Any other information that would be helpful for reviewers -->

<!-- 
💡 **Tip for Contributors:**
- Link related issues using "Closes #123" syntax
- Update golden tests if you made intentional UI changes
- Ensure all CI checks pass before requesting review
- Test on physical devices when possible
-->