# Deprecation Audit: ReLoop
**Date:** 2026-05-21  
**Scope:** Dart/Flutter APIs, packages, dependencies, and documentation  
**Status:** Comprehensive audit with remediation plan

---

## Executive Summary

This audit catalogs all deprecated APIs, packages, and code patterns in the waste segregation app. The project has already implemented mitigation strategies for most critical deprecations, but several remnants require cleanup and package updates need planning.

### Key Findings
- ✅ **Flutter API Deprecations**: Partially mitigated with helper extensions
- ⚠️ **Redundant Package Dependencies**: Stale references in pubspec.yaml  
- 🔴 **Deprecated Documentation**: 2 architecture docs marked as deprecated
- 🔄 **Package Upgrade Opportunities**: Several dependencies can be updated for better maintenance

---

## 1. Flutter/Dart API Deprecations

### 1.1 Color.withOpacity() → withValues(alpha:)

**Status**: ⚠️ Partially Mitigated

**Impact**: 13 active usages in source code, ~342 linter warnings reported

**Mitigation Strategy Already in Place**:
- ✅ Helper extension created: `lib/utils/opacity_fix_helper.dart`
- ✅ Alternative extension: `lib/utils/color_extensions.dart` with `withAlphaFraction()`
- ⚠️ Not consistently used across codebase

**Current Usages**:
```
lib/main_debug.dart:87                 Colors.blue.shade500.withOpacity(0.3)
lib/utils/app_error_handler.dart:190   Colors.red.withOpacity(0.1)
lib/widgets/manual_region_selector.dart:362, 421, 422, 437, 467  (5 usages)
lib/services/visual_feedback_service.dart:333
lib/screens/model_download_screen.dart:348
lib/screens/smart_suggestions_screen.dart:189
lib/screens/impact_dashboard_screen.dart:193, 307
```

**Recommended Action**:
1. ✅ Keep `opacity_fix_helper.dart` as stable API
2. 🔧 Replace all 13 `withOpacity()` calls with `withOpacityFixed()` 
3. 📋 Add lint rule to warn on `withOpacity` usage

**Priority**: HIGH  
**Effort**: 30 minutes  
**Files to Update**: 8 dart files

---

### 1.2 Color.value (ARGB Packed Integer)

**Status**: ⚠️ Controlled Usage

**Impact**: Used intentionally in serialization; not a breaking issue

**Current Usage**:
```
lib/models/gamification.dart:239   'color': color.value,  (in toJson)
lib/models/gamification.dart:430   'color': color.value,  (in toJson)
```

**Mitigation Already in Place**:
- ✅ `lib/utils/color_extensions.dart` provides `toARGB32()` method
- ✅ Usage is documented as intentional for serialization

**Recommended Action**:
1. ✅ Keep `color.value` usage as-is (intentional serialization pattern)
2. 📋 Add comment explaining why deprecated API is used: "Intentional: Color value serialization to ARGB32 integer format for JSON storage"
3. 🔧 Consider migrating to `toARGB32()` helper for consistency (optional, lower priority)

**Priority**: LOW  
**Effort**: 10 minutes (optional enhancement)

---

## 2. Deprecated & Replaced Packages

### 2.1 firebase_dynamic_links → app_links ✅

**Status**: ✅ Replaced (May 2025)

**Original Issue**: Firebase Dynamic Links discontinued August 25, 2025

**Current State**:
- ✅ Replacement package `app_links: ^6.3.2` installed
- ⚠️ Old package still listed in pubspec.yaml as `firebase_dynamic_links: any`
- 🔴 Creating confusion and bloating dependency tree

**Required Action**: 
```yaml
# REMOVE from pubspec.yaml (line ~81):
firebase_dynamic_links: any
```

**Priority**: HIGH (Cleanup)  
**Effort**: 2 minutes  

---

### 2.2 flutter_markdown → markdown_widget ✅

**Status**: ✅ Replaced (Already in Use)

**Original Issue**: flutter_markdown discontinued; community-maintained alternative adopted

**Current State**:
- ✅ Replacement package `markdown_widget: ^2.3.2+6` installed and used
- ⚠️ Old package still listed in pubspec.yaml as `flutter_markdown: any`
- 🔴 Still imported in one file for backward compatibility

**Current Usage**:
```dart
lib/screens/legal_document_screen.dart:3   import 'package:flutter_markdown/flutter_markdown.dart';
```

**Impact**: Maintains old import; markdown_widget provides drop-in replacement

**Required Actions**:
1. 🔧 Replace import in `legal_document_screen.dart`:
   ```dart
   // OLD: import 'package:flutter_markdown/flutter_markdown.dart';
   // NEW: import 'package:markdown_widget/markdown.dart';
   ```
2. 🗑️ Remove from pubspec.yaml: `flutter_markdown: any`

**Priority**: HIGH (Cleanup)  
**Effort**: 15 minutes  
**Files to Update**: 1 dart file + pubspec.yaml

---

### 2.3 tflite_flutter_helper → Custom Implementation ✅

**Status**: ✅ Already Replaced with Custom Code

**Original Issue**: 
- Requires `image ^3.0.2` but project uses `image ^4.0.17`
- Package is unmaintained

**Current State**:
- ✅ Custom `TFLitePreprocessingHelper` implemented
- ✅ Located at `lib/services/tflite_preprocessing_helper.dart`
- ✅ Provides: image resizing, normalization, postprocessing, batch operations
- ✅ No references to old package in source code

**Status**: ✅ Complete - No action needed

---

## 3. Deprecated Packages Still in Dependencies

### Summary Table

| Package | Current Version | Status | Notes |
|---------|-----------------|--------|-------|
| `flutter_markdown` | `any` | 🔴 Redundant | Should remove (replaced by `markdown_widget`) |
| `firebase_dynamic_links` | `any` | 🔴 Redundant | Should remove (replaced by `app_links`) |
| `flutter_image_compress` | `^2.3.0` | ✅ OK | No issues; actively maintained |
| `mobile_scanner` | ~commented~ | 🔴 Disabled | Dependency conflicts; commented in pubspec |

---

## 4. Deprecated Documentation

### 4.1 Classification Pipeline Architecture

**File**: `docs/reports/architecture/classification_pipeline.md`  
**Status**: 🔴 DEPRECATED  
**Reason**: Superseded by unified architecture documentation

**Recommendation**:
- Archive to: `docs/archive/deprecated_classification_pipeline.md`
- Keep redirect header pointing to canonical source
- Canonical source: `docs/technical/unified_architecture/comprehensive_architecture.md`

---

### 4.2 Technical Architecture (System)

**File**: `docs/reports/architecture/system/technical_architecture.md`  
**Status**: 🔴 DEPRECATED  
**Reason**: Superseded by unified architecture documentation

**Recommendation**:
- Archive to: `docs/archive/deprecated_technical_architecture.md`
- Keep redirect header pointing to canonical source
- Canonical source: `docs/technical/unified_architecture/comprehensive_architecture.md`

---

## 5. Deprecated Sub-Dependencies (npm)

### 5.1 Functions (Node.js Cloud Functions)

**File**: `functions/package-lock.json`

#### Deprecated Transitive Dependencies

| Package | Issue | Current | Recommendation |
|---------|-------|---------|-----------------|
| `glob` (transitive) | Old versions have security vulns | ~0.x | Update parent dependency |
| `async` (transitive) | Memory leak; unsupported | old versions | Use `lru-cache` instead if needed |
| `domexception` (transitive) | Deprecated DOM API usage | old | Update parent packages |

**Root Cause**: These are transitive dependencies from `firebase-admin`, `firebase-functions`, and their dependencies.

**Current Versions in package.json**:
```json
"firebase-admin": "^12.7.0",
"firebase-functions": "^5.1.1",
"openai": "^4.104.0"
```

**Recommendation**:
1. Run `npm audit` to identify vulnerable transitive deps
2. Consider updating to latest Firebase SDK versions
3. Use `npm override` to force safe versions of problematic transitive deps

**Priority**: MEDIUM (Security hygiene)

---

### 5.2 Storybook Package (JavaScript)

**File**: `package.json`

**Current Status**: ✅ No deprecated dependencies detected
- Storybook v7.6.0 is current
- All addon packages are at compatible versions
- Development dependencies are recent

---

## 6. Package Update Recommendations

### 6.1 Flutter/Dart Packages

#### HIGH PRIORITY - Update Soon

| Package | Current | Latest | Benefit | Breaking? |
|---------|---------|--------|---------|-----------|
| `flutter_riverpod` | `^2.4.9` | `^2.5.x` | Bug fixes, minor improvements | No |
| `permission_handler` | `^12.0.0+1` | `^12.1.x` | Stability fixes | No |
| `connectivity_plus` | `^6.0.5` | `^6.1.x` | Better platform support | No |

#### MEDIUM PRIORITY - Plan Upgrade

| Package | Current | Latest | Benefit | Breaking? |
|---------|---------|--------|---------|-----------|
| `camera` | `^0.11.0+2` | `^0.12.x` | Better compatibility | Possibly |
| `image_picker` | `^1.0.4` | `^1.1.x` | Enhanced features | No |
| `fl_chart` | `^0.68.0` | `^0.70.x` | Better Flutter 3.x support | Possibly |
| `flutter_localizations` | current | current | Integrated with Flutter | N/A |

#### LOW PRIORITY - Watch

| Package | Current | Notes |
|---------|---------|-------|
| `provider` | `^6.1.1` | Stable; consider `flutter_riverpod` migration |
| `hive` | `^2.2.3` | Good; no deprecation horizon |
| `firebase_*` | `^3.x-^12.x` | Recently updated; track Firebase roadmap |

---

### 6.2 Node.js/JavaScript Packages

#### HIGH PRIORITY

| Package | Current | Latest | Reason |
|---------|---------|--------|--------|
| `@types/node` | should add | `^20.x` | Type safety for Node.js 18 |
| `firebase-admin` | `^12.7.0` | `^13.x` | Latest SDKs, better support |
| `firebase-functions` | `^5.1.1` | `^5.2.x` | Stability updates |

#### MEDIUM PRIORITY

| Package | Current | Latest | Reason |
|---------|---------|--------|--------|
| `typescript` | `^4.9.0` | `^5.4.x` | Better type inference, new syntax |
| `axios` | `^1.15.2` | `^1.6.x` | Bug fixes, security patches |

---

## 7. Remediation Plan & Timeline

### Phase 1: Cleanup (Immediate - 1 week)

**Effort**: ~1-2 hours total

- [ ] Remove `flutter_markdown: any` from pubspec.yaml
- [ ] Remove `firebase_dynamic_links: any` from pubspec.yaml
- [ ] Update `legal_document_screen.dart` to use `markdown_widget`
- [ ] Replace all 13 `withOpacity()` usages with `withOpacityFixed()`
- [ ] Document `Color.value` usage as intentional
- [ ] Run `flutter pub get` and verify no build issues

**Files Changed**: ~10 files  
**Tests Required**: Widget tests for UI components using color opacity

---

### Phase 2: Package Updates (1-2 weeks)

**Effort**: ~3-4 hours

#### Part A: Dart/Flutter Minor Updates
- [ ] Update `flutter_riverpod` to latest `^2.5.x`
- [ ] Update `permission_handler` to latest `^12.1.x`
- [ ] Update `connectivity_plus` to latest `^6.1.x`
- [ ] Test on Android & iOS simulators

#### Part B: Node.js Updates
- [ ] Update `firebase-admin` to `^13.x` with compatibility testing
- [ ] Update `typescript` to `^5.4.x`
- [ ] Run `npm audit` and fix vulnerabilities
- [ ] Test Cloud Functions deployment

**Tests Required**: 
- Unit tests for all updated packages
- E2E tests for Firebase functions
- Device/simulator tests for mobile packages

---

### Phase 3: Major Updates (2-4 weeks)

**Effort**: ~5-8 hours  
**Breaking Changes Expected**: Yes

#### Packages to Evaluate
- `camera` ^0.11.0 → ^0.12.x (test compatibility first)
- `fl_chart` ^0.68.0 → ^0.70.x (API changes likely)
- `image_picker` ^1.0.4 → ^1.1.x (verify new features)

**Approach**:
1. Create feature branch per package update
2. Run full test suite (once fixed)
3. Manual testing on devices
4. Gradual rollout in staging

---

### Phase 4: Strategic Reviews (Ongoing)

**Frequency**: Monthly

- Monitor Firebase SDK roadmap for deprecations
- Track Flutter SDK changes (major versions)
- Review unused dependencies (dead code audit - separate from this)
- Evaluate alternatives to `provider` (consider `flutter_riverpod` fully)

---

## 8. Risk Assessment

### High Risk ✅ (Already Handled)
- ~~Firebase Dynamic Links discontinuation~~ → Migrated to `app_links`
- ~~flutter_markdown discontinuation~~ → Migrated to `markdown_widget`
- ~~tflite_flutter_helper incompatibility~~ → Custom implementation

### Medium Risk ⚠️ (Needs Action)
- 342 linter warnings from `withOpacity` → Use `withOpacityFixed` consistently
- Redundant dependencies in pubspec → Clean up immediately

### Low Risk (Monitor)
- Firebase SDK updates → Update to latest minor versions regularly
- Third-party package maintenance → Subscribe to vulnerability alerts

---

## 9. Verification Checklist

After completing remediation:

- [ ] All `withOpacity` calls replaced with `withOpacityFixed`
- [ ] Redundant packages removed from pubspec.yaml
- [ ] flutter_markdown imports replaced with markdown_widget
- [ ] `flutter pub get` completes successfully
- [ ] Dart linter runs with no deprecation warnings for replaced APIs
- [ ] Unit tests pass (once test infrastructure is fixed)
- [ ] UI tests pass on iOS simulator
- [ ] UI tests pass on Android emulator
- [ ] Firebase Cloud Functions deploy successfully
- [ ] No new deprecation warnings in `flutter analyze`

---

## 10. References & Resources

### Deprecation Notices
- [Flutter Deprecations: withOpacity](https://api.flutter.dev/flutter/dart-ui/Color/withOpacity.html)
- [Firebase Dynamic Links Sunset](https://firebase.google.com/support/faq/firebase_dynamic_links)
- [app_links: The Modern Replacement](https://pub.dev/packages/app_links)

### Migration Guides
- [Color API Evolution (Flutter Docs)](https://docs.flutter.dev/release/breaking-changes)
- [firebase-admin SDK Updates](https://firebase.google.com/docs/admin/setup)

### Monitoring & Alerts
- Set up dependency scanning with `dependabot` or `renovate`
- Track breaking changes in Firebase SDK releases
- Subscribe to Flutter SDK release notes

---

## 11. Owner & Status

- **Audit Date**: 2026-05-21
- **Next Review**: 2026-06-21
- **Status**: Ready for remediation planning
- **Phase 1 Target**: Complete by 2026-05-28
- **Phase 2 Target**: Complete by 2026-06-04

