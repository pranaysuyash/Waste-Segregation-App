# Versioning Strategy - Waste Segregation App

## Overview
This document outlines the versioning strategy for managing internal development builds and Play Store releases.

## Version Format
We use the format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Example: `0.1.5+97`

## Internal Development Strategy

### Build Numbers (Internal)
- **Continuous Increment**: Build numbers increment for every internal build
- **Current**: 0.1.5+97 (December 26, 2024 - Cloud storage implementation)
- **Next Internal Builds**: 0.1.5+98, 0.1.5+99, 0.1.5+100, 0.1.5+101...
- **Purpose**: Track all development iterations and testing builds

### Version Numbers (Internal)
- Keep the same MINOR version during development cycle
- Only increment when ready for Play Store release
- Example development cycle:
  - `0.1.5+97` ← Current (Cloud storage implementation)
  - `0.1.5+98` ← Next internal build (bug fixes)
  - `0.1.5+99` ← Another internal build (features)
  - `0.1.5+100` ← Continue internal development
  - `0.1.5+101` ← More internal builds...

## Play Store Release Strategy

### When to Increment Version for Play Store
- **Significant Feature Releases**: Major new functionality
- **Major Bug Fixes**: Critical fixes worth highlighting
- **Marketing Moments**: When we want to show progress to users
- **User-Facing Changes**: UI overhauls, new screens, etc.

### Play Store Version Pattern
- **Increment Minor Version**: 0.1.5 → 0.1.6 → 0.1.7
- **Jump Build Number**: Use a higher build number to show progress
- **Examples**:
  - Internal: 0.1.5+97 → 0.1.5+98 → ... → 0.1.5+119
  - Play Store: 0.1.6+120 (significant update ready)
  - Internal continues: 0.1.6+121 → 0.1.6+122 → ... → 0.1.6+149
  - Play Store: 0.1.7+150 (next major update)

## Example Workflow

### Current State (December 26, 2024)
```
0.1.5+97 - Play Store ready (Cloud storage implementation)
```

### Continued Development
```
0.1.5+98 - Internal (Fix history duplication bug)
0.1.5+99 - Internal (Add sync status indicators)  
0.1.5+100 - Internal (UI improvements)
0.1.5+101 - Internal (Performance optimizations)
0.1.5+102 - Internal (Admin dashboard foundations)
...
0.1.5+119 - Internal (Ready for next Play Store release)
```

### Next Play Store Release
```
0.1.6+120 - Play Store (Major UI overhaul + admin features)
```

### Benefits of This Strategy

#### For Development
- **Clear Tracking**: Every internal build has unique identifier
- **No Conflicts**: Version numbers never conflict during development
- **Continuous Development**: Can develop without worrying about version bumps
- **Easy Testing**: Testers can identify exact build they're testing

#### For Play Store
- **Marketing Control**: Choose when to increment public-facing version
- **Clear Progress**: Build number jump shows significant development
- **User Communication**: Version increments signal meaningful updates
- **Rollback Safety**: Always have internal builds between public releases

#### For Business
- **Internal vs External**: Clear separation of development and marketing releases
- **Stakeholder Communication**: Can show progress without confusing public versioning
- **Quality Control**: Time to polish between internal completion and public release

## Release Naming Convention

### Internal Builds
- `0.1.5+98` - "Internal Build 98: History bug fixes"
- `0.1.5+99` - "Internal Build 99: Sync improvements"
- `0.1.5+100` - "Internal Build 100: UI enhancements"

### Play Store Releases
- `0.1.6+120` - "Major Update: Enhanced UI & Admin Features"
- `0.1.7+150` - "Community Release: Social Features & Real-time Sync"
- `0.1.8+180` - "AI Enhancement: Improved Classification & Voice Support"

## Implementation in Code

### pubspec.yaml Updates
```yaml
# Internal development
version: 0.1.5+98  # Just increment build number

# Play Store release
version: 0.1.6+120  # Increment version + jump build number
```

### Git Tagging Strategy
```bash
# Internal builds
git tag v0.1.5+98-internal
git tag v0.1.5+99-internal

# Play Store releases  
git tag v0.1.6+120-playstore
git tag v0.1.7+150-playstore
```

## Documentation Updates

### When Version Changes
- Update CHANGELOG.md with clear sections for internal vs Play Store releases
- Update README.md with current stable and development versions
- Update any API documentation with version compatibility notes

### Release Notes Template

#### Internal Build Release Notes
```
## Internal Build 0.1.5+98 - Bug Fixes
- Fixed history duplication issue
- Improved sync status indicators  
- Enhanced error handling
- Performance optimizations
```

#### Play Store Release Notes
```
## Version 0.1.6+120 - Major UI & Feature Update
- Completely redesigned user interface
- New admin dashboard for data recovery
- Enhanced cloud synchronization
- Improved performance and stability
- Advanced analytics and insights
```

---

**Current Status**: 0.1.5+97 (Cloud Storage Implementation Complete)  
**Next Internal**: 0.1.5+98 (Bug fixes and improvements)  
**Next Play Store Target**: 0.1.6+120 (Major UI overhaul + admin features)  
**Strategy Owner**: Solo Developer (Pranay)  
**Last Updated**: December 26, 2024 