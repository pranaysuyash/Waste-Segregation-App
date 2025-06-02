# Versioning Strategy - Waste Segregation App

## Overview
This document outlines the versioning strategy for managing internal development builds and Play Store releases.

## Version Format
We use the format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Example: `0.1.5+97`

## Internal Development Strategy

### Build Numbers (Internal)
- **Continuous Increment**: Build numbers increment for every internal build
- **Current**: Started from 92, now at 97
- **Future**: Continue incrementing (98, 99, 100, 101, ...)
- **Purpose**: Track all development iterations and testing builds

### Version Numbers (Internal)
- Keep the same MINOR version during development cycle
- Only increment when ready for Play Store release
- Example development cycle:
  - `0.1.5+97` ← Current Play Store version
  - `0.1.5+98` ← Next internal build
  - `0.1.5+99` ← Another internal build
  - `0.1.5+100` ← Another internal build

## Play Store Release Strategy

### When Ready for Play Store
1. **Increment MINOR version**: `0.1.5` → `0.1.6`
2. **Use latest build number**: Whatever the current internal build number is
3. **Example transition**:
   - Last internal: `0.1.5+103`
   - Play Store release: `0.1.6+103`
   - Next internal: `0.1.6+104`

### Version Increment Rules
- **PATCH** (0.1.X): Bug fixes and minor improvements
- **MINOR** (0.X.0): New features, significant improvements
- **MAJOR** (X.0.0): Major overhauls, breaking changes

## Implementation Workflow

### For Internal Development
```bash
# Current build: 0.1.5+97
# Next internal builds:
# 0.1.5+98, 0.1.5+99, 0.1.5+100, etc.

# Update pubspec.yaml manually for each internal build
version: 0.1.5+98
```

### For Play Store Release
```bash
# If current internal is 0.1.5+120
# Play Store release becomes:
version: 0.1.6+120

# Build and upload to Play Store
flutter build appbundle --release
```

### After Play Store Release
```bash
# Continue with next internal builds:
version: 0.1.6+121
```

## Example Timeline

| Build | Version | Type | Notes |
|-------|---------|------|--------|
| 97 | 0.1.5+97 | Play Store | Current release |
| 98 | 0.1.5+98 | Internal | Bug fixes |
| 99 | 0.1.5+99 | Internal | Feature work |
| 100 | 0.1.5+100 | Internal | More features |
| 101 | 0.1.5+101 | Internal | Testing |
| 102 | 0.1.6+102 | Play Store | Ready for release |
| 103 | 0.1.6+103 | Internal | Next cycle begins |

## Benefits of This Strategy

1. **Clear Tracking**: Every build is uniquely identified
2. **Flexible Releases**: Can release to Play Store at any internal build
3. **Continuous Development**: No disruption to development workflow
4. **Version Clarity**: Play Store versions clearly indicate feature releases
5. **Rollback Capability**: Can always identify which internal build a Play Store version came from

## Commands for Quick Updates

### Update to Next Internal Build
```bash
# In pubspec.yaml, increment build number only
# 0.1.5+97 → 0.1.5+98
```

### Prepare for Play Store Release
```bash
# In pubspec.yaml, increment minor version, keep build number
# 0.1.5+120 → 0.1.6+120
```

## Release Notes Management

### Internal Builds
- Update `CHANGELOG.md` with development notes
- No formal release notes needed

### Play Store Releases
- Create comprehensive release notes in `docs/release_notes_X.X.X_XXX.md`
- Create short version in `docs/play_store_release_notes_X.X.X_XXX.txt`
- Update `CHANGELOG.md` with user-facing changes

---

**Last Updated**: 2024-01-27
**Current Strategy**: Internal builds increment build number, Play Store releases increment minor version 