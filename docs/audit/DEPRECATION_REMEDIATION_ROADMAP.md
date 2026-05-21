# Deprecation Remediation Roadmap
**Reference**: See `DEPRECATION_AUDIT_2026-05-21.md` for full audit details

**Updated**: 2026-05-21  
**Status**: In progress (low-blast passes started)

---

## Quick Start: Phase 1 Cleanup (Do These First)

### ✅ Task 1: Remove Redundant Package Dependencies
**File**: `pubspec.yaml`  
**Effort**: 2 minutes  
**Impact**: Reduces dependency confusion, smaller pubspec

**Action**:
Remove lines containing:
```yaml
  flutter_markdown: any
  firebase_dynamic_links: any
```

**Why**: 
- `markdown_widget: ^2.3.2+6` is the official replacement for `flutter_markdown`
- `app_links: ^6.3.2` is the official replacement for `firebase_dynamic_links`

**Verification**:
```bash
flutter pub get  # Should succeed
```

---

### 🔧 Task 2: Update Legal Document Screen Import
**File**: `lib/screens/legal_document_screen.dart`  
**Effort**: 5 minutes  
**Impact**: Use current maintained package

**Current Code** (line 3):
```dart
import 'package:flutter_markdown/flutter_markdown.dart';
```

**New Code**:
```dart
import 'package:markdown_widget/markdown.dart';
```

**Why**: Migration to maintained package

**After Update**:
```bash
flutter pub get
flutter analyze  # Should have no errors on this file
```

---

### 🎨 Task 3: Replace withOpacity() → withOpacityFixed()
**File**: Multiple files with `.withOpacity()` calls (13 total)  
**Effort**: 30 minutes  
**Impact**: Eliminates 342 deprecation linter warnings

**Step 1**: Add import to files (if not already present)
```dart
import 'package:your_app/utils/opacity_fix_helper.dart';
```

**Step 2**: Replace all `withOpacity(` → `withOpacityFixed(`

**Files & Line Numbers**:
```
1. lib/main_debug.dart:87
   OLD: color: Colors.blue.shade500.withOpacity(0.3),
   NEW: color: Colors.blue.shade500.withOpacityFixed(0.3),

2. lib/utils/app_error_handler.dart:190
   OLD: color: Colors.red.withOpacity(0.1),
   NEW: color: Colors.red.withOpacityFixed(0.1),

3. lib/widgets/manual_region_selector.dart (5 occurrences):
   Lines: 362, 421, 422, 437, 467
   
4. lib/services/visual_feedback_service.dart:333
   OLD: color: Colors.black.withOpacity(0.1),
   NEW: color: Colors.black.withOpacityFixed(0.1),

5. lib/screens/model_download_screen.dart:348
   OLD: color: color.withOpacity(0.1),
   NEW: color: color.withOpacityFixed(0.1),

6. lib/screens/smart_suggestions_screen.dart:189
   OLD: color: textColor.withOpacity(0.8),
   NEW: color: textColor.withOpacityFixed(0.8),

7. lib/screens/impact_dashboard_screen.dart (2 occurrences):
   Lines: 193, 307
   OLD: color: Colors.green.withOpacity(0.1),
   NEW: color: Colors.green.withOpacityFixed(0.1),
```

**Verification**:
```bash
flutter analyze  # Should have no withOpacity deprecation warnings
```

---

### 📝 Task 4: Document Color.value Usage
**File**: `lib/models/gamification.dart`  
**Effort**: 10 minutes  
**Impact**: Clarifies intentional use of deprecated API

**Current Code** (lines 239, 430):
```dart
'color': color.value,
```

**Add Comment Above**:
```dart
// Intentional: Color.value serializes Color to ARGB32 integer format (0xAARRGGBB)
// for JSON storage. Deprecated API is acceptable here for serialization contract.
'color': color.value,
```

**Why**: Documents why deprecated API is used intentionally

**Verification**:
```bash
# Add lint ignore if warning still appears:
// ignore: deprecated_member_use
'color': color.value,
```

---

## Timeline & Priority

### Week 1 (May 21-28)
- [ ] Monday: Task 1 (Remove redundant deps) + Task 2 (Update import)
- [ ] Tuesday-Wednesday: Task 3 (Replace withOpacity calls)
- [ ] Thursday: Task 4 (Document Color.value)
- [ ] Friday: Full test run + verification

**Estimated Time**: 1-2 hours total

---

## Phase 2: Package Updates (1-2 weeks after Phase 1)

### Minor Updates (Low Risk)
```yaml
# Update these in pubspec.yaml and test thoroughly:
flutter_riverpod: ^2.5.1      # Was: ^2.4.9
permission_handler: ^12.1.0   # Was: ^12.0.0+1  
connectivity_plus: ^6.1.0     # Was: ^6.0.5
```

**Process**:
1. Update version in `pubspec.yaml`
2. Run `flutter pub get`
3. Run `flutter test` (once test infrastructure is fixed)
4. Run `flutter analyze`
5. Test on device/simulator

---

### Node.js Functions Updates
```json
{
  "firebase-admin": "^13.0.0",      // Was: ^12.7.0
  "firebase-functions": "^5.2.0",   // Was: ^5.1.1
  "typescript": "^5.4.0"            // Was: ^4.9.0
}
```

**Process**:
1. Update versions in `functions/package.json`
2. Run `npm install`
3. Run `npm run build`
4. Run `npm audit` to check for vulnerabilities
5. Test deployment to Firebase emulator

---

## Phase 3: Major Updates (After Phase 1+2, plan for 2-4 weeks)

### Evaluation Needed
- `camera` ^0.12.x (test compatibility first)
- `fl_chart` ^0.70.x (check API breaking changes)
- `image_picker` ^1.1.x (verify new features)

**Approach**: One package per branch, full testing cycle

---

## Success Criteria

✅ All tasks from Phase 1 complete:
- No redundant package entries in `pubspec.yaml`
- No `withOpacity()` in source code
- Legal document screen uses `markdown_widget`
- `Color.value` usage documented
- `flutter analyze` shows 0 deprecation warnings (for these APIs)
- `flutter pub get` succeeds with no errors

📈 After Phase 2:
- All minor package updates applied
- Full test suite passing (once fixed)
- Device/simulator testing successful
- `npm audit` shows no vulnerabilities

🎯 After Phase 3:
- Major packages evaluated and strategically updated
- No deprecated API usage in codebase
- Dependency tree optimized for maintenance

---

## Reference

**Full Audit**: `docs/audit/DEPRECATION_AUDIT_2026-05-21.md`  
**Helper Code**: 
- `lib/utils/opacity_fix_helper.dart` - withOpacity replacement
- `lib/utils/color_extensions.dart` - Color API compatibility layer
- `lib/services/tflite_preprocessing_helper.dart` - TFLite replacement

---

## Execution Log (Low-Blast-Radius Passes)

### Pass 1 — 2026-05-21: Remove discontinued deep-link dependency reference

**Change applied**:
- Removed `firebase_dynamic_links: any` from `pubspec.yaml` (dependency list only).

**Why this pass was low blast radius**:
- Package had already been replaced by `app_links`.
- No runtime references in `lib/**`.
- No API contract changes.

**Verification run**:
- `flutter pub get` ✅
- `flutter analyze lib/screens/legal_document_screen.dart lib/services/ai_service.dart` ✅ (warnings only, no errors)
- `rg "firebase_dynamic_links" lib pubspec*` ✅ (comment-only reference remains)

### Pass 2 — 2026-05-21: Functions dependency safety refresh (within existing major ranges)

**Change applied**:
- Ran `npm update axios firebase-admin firebase-functions openai` inside `functions/`.
- This refreshed lockfile resolution without crossing declared major-version boundaries.

**Verification run**:
- `npm audit --omit=dev` ✅ (0 vulnerabilities)
- `npm run build` ✅
- `npm run test:http-guards` ✅
- `npm run test:key-resolution` ✅

**Observed resolved versions after refresh**:
- `axios` resolved to `1.16.1`
- `firebase-admin` remained at `12.7.0`
- `firebase-functions` remained at `5.1.1`
- `openai` remained at `4.104.0`

### Residual risk (intentionally deferred for controlled migration)

- `flutter_markdown` is still used by `lib/screens/legal_document_screen.dart`; migration to `markdown_widget` is pending to avoid UI regressions from rushed renderer swap.
- Major-version upgrades in Firebase/OpenAI/Flutter stacks are intentionally deferred and should be handled in isolated, test-gated passes.

