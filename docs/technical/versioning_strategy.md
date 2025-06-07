# Versioning Strategy - Waste Segregation App

## Overview
This document outlines the versioning strategy for managing internal development builds and Play Store releases.

## Version Format
We use the format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Example: `0.1.5+97`

## Current State
- **Play Store Release**: 0.1.5+97 (December 26, 2024 - Cloud storage implementation)
- **Next Internal Development**: 0.1.6+98, 0.1.6+99, 0.1.6+100...

## Versioning Strategy

### Internal Development Builds
- **Increment Minor Version**: When starting new development cycle after Play Store release
- **Increment Build Number**: For each internal build
- **Current Development Cycle**: 0.1.6+98, 0.1.6+99, 0.1.6+100, 0.1.6+101...
- **Purpose**: Track all development iterations and testing builds

### Play Store Release Strategy
- **Release Whatever Internal Build is Ready**: Could be 0.1.6+98, 0.1.6+99, 0.1.6+102, etc.
- **No Version Change Needed**: The internal build becomes the Play Store release as-is
- **Marketing Timing**: Release when features are complete and tested, regardless of build number

### Post-Release Development
- **Start Next Cycle**: After Play Store release, increment minor version for next development
- **Example**: If 0.1.6+102 goes to Play Store, next internal development starts with 0.1.7+103

## Example Workflow

### Current Situation (December 26, 2024)
```
✅ Play Store: 0.1.5+97 (Cloud storage implementation - LIVE)
```

### Next Development Cycle
```
🔄 Internal Development:
0.1.6+98  - Internal (History bug fixes + default sync enabled)
0.1.6+99  - Internal (UI improvements)  
0.1.6+100 - Internal (Admin dashboard foundations)
0.1.6+101 - Internal (Performance optimizations)
0.1.6+102 - Internal (Ready for Play Store? Or continue...)
0.1.6+103 - Internal (More features...)
```

### Play Store Release Decision
```
📱 When Ready for Play Store:
- Could be 0.1.6+99 (if features complete early)
- Could be 0.1.6+102 (if more development needed)  
- Could be 0.1.6+105 (if extensive testing required)
- Release: Whatever internal build is ready ✅
```

### Next Development Cycle After Play Store
```
🚀 After Play Store Release (e.g., 0.1.6+102 shipped):
0.1.7+103 - Internal (New features for next cycle)
0.1.7+104 - Internal (Continue development)
0.1.7+105 - Internal (More features...)
```

## Real Example Timeline

### Phase 1: Current (Done)
- `0.1.5+97` → **Play Store** (Cloud storage implementation)

### Phase 2: Next Development (Starting Now)
- `0.1.6+98` → Internal (Default sync enabled + bug fixes)
- `0.1.6+99` → Internal (Enhanced UI components)
- `0.1.6+100` → Internal (Admin dashboard foundations)
- `0.1.6+101` → Internal (Real-time sync improvements)
- `0.1.6+102` → Internal (Testing and polish)

### Phase 3: Play Store Decision
- **Option A**: Ship `0.1.6+99` if UI improvements are enough
- **Option B**: Ship `0.1.6+102` if admin features are needed
- **Option C**: Continue to `0.1.6+105` if more development required

### Phase 4: Next Cycle
- `0.1.7+XXX` → Start next development cycle (whatever comes after Play Store release)

## Benefits of This Strategy

### For Development
- **Flexible Release Timing**: Can release whenever features are ready
- **No Version Pressure**: Don't need to plan exact version numbers in advance
- **Clear Development Tracking**: Every internal build has unique identifier
- **Simple Process**: Just increment build number for each internal build

### For Play Store
- **Release When Ready**: Ship when quality is right, not when version is "pretty"
- **Marketing Flexibility**: Choose optimal timing for releases
- **User Communication**: Version increments show meaningful progress
- **Quality Focus**: No pressure to release just to bump version number

### For Business
- **Agile Development**: Can pivot and adjust timeline as needed
- **Quality Control**: Release when actually ready, not on version schedule
- **Clear Progress**: Stakeholders see continuous development in build numbers
- **Planning Flexibility**: Can adjust scope based on development progress

## Implementation in Code

### Current Development
```yaml
# pubspec.yaml - Next internal builds
version: 0.1.6+98   # ← Next internal build
version: 0.1.6+99   # ← Following internal build  
version: 0.1.6+100  # ← Continue incrementing
```

### Play Store Release
```yaml
# pubspec.yaml - When ready for Play Store
version: 0.1.6+102  # ← Whatever internal build is ready
# Ship this version to Play Store as-is
```

### After Play Store Release  
```yaml
# pubspec.yaml - Next development cycle
version: 0.1.7+103  # ← Start next cycle with incremented minor version
```

## Git Tagging Strategy

### Internal Builds
```bash
git tag v0.1.6+98-internal
git tag v0.1.6+99-internal
git tag v0.1.6+100-internal
```

### Play Store Releases
```bash
git tag v0.1.6+102-playstore  # Whatever build goes to store
git tag v0.1.7+108-playstore  # Next Play Store release
```

## Release Notes Template

### Internal Build Notes
```
## Internal Build 0.1.6+98
- Default cloud sync enabled for new users
- Fixed history duplication bug  
- Improved sync status indicators
- Enhanced error handling
```

### Play Store Release Notes (When Ready)
```
## Version 0.1.6+102 - Enhanced Sync & Admin Features
- Cloud sync now enabled by default for better data security
- New admin dashboard for user support
- Improved performance and reliability
- Enhanced user interface with modern components
```

## Key Principles

1. **Release When Ready**: Quality over version number aesthetics
2. **Continuous Development**: Always increment build numbers
3. **Flexible Timing**: No fixed version release schedule
4. **Clear Tracking**: Every build is uniquely identifiable
5. **Simple Process**: Minimal version management overhead

---

**Current Status**: 0.1.5+97 (Play Store - Cloud Storage Implementation)  
**Next Internal**: 0.1.6+98 (Default sync enabled + bug fixes)  
**Release Strategy**: Ship whatever 0.1.6+XXX build is ready for Play Store  
**Post-Release**: Start 0.1.7+XXX cycle after Play Store ship  
**Last Updated**: December 26, 2024 