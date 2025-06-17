# Automated debugPrint to WasteAppLogger Converter

## Overview

This script automatically converts `debugPrint()` calls to structured `WasteAppLogger` calls with proper imports and context.

## Usage

```bash
# Dry run to see what would be converted
dart run scripts/simple_debug_converter.dart --priority=1 --dry-run

# Actually perform conversions
dart run scripts/simple_debug_converter.dart --priority=1

# Convert different priority levels
dart run scripts/simple_debug_converter.dart --priority=2
dart run scripts/simple_debug_converter.dart --priority=3
```

## Priority Levels

### Priority 1: Critical Services (352 calls)
- `lib/services/gamification_service.dart` (154 calls)
- `lib/services/ai_service.dart` (74 calls)  
- `lib/services/cloud_storage_service.dart` (66 calls)
- `lib/services/storage_service.dart` (58 calls)

### Priority 2: User-Facing Screens
- `lib/screens/home_screen.dart`
- `lib/screens/result_screen.dart`
- `lib/screens/image_capture_screen.dart`
- `lib/screens/achievements_screen.dart`

### Priority 3: Widgets and Utilities
- `lib/widgets/history_list_item.dart`
- `lib/widgets/share_button.dart`
- `lib/providers/points_manager.dart`
- `lib/providers/gamification_provider.dart`

## What the Script Does

1. **Adds WasteAppLogger Import**: Automatically adds the correct relative import path
2. **Converts debugPrint Calls**: Replaces with appropriate WasteAppLogger methods based on content:
   - Error/Failed → `WasteAppLogger.severe()`
   - Warning → `WasteAppLogger.warning()`
   - Cache operations → `WasteAppLogger.cacheEvent()`
   - AI operations → `WasteAppLogger.aiEvent()`
   - Performance → `WasteAppLogger.performanceLog()`
   - Default → `WasteAppLogger.info()`

3. **Preserves Indentation**: Maintains original code formatting
4. **Adds Context**: Includes service type and file name in all log calls

## Example Conversion

**Before:**
```dart
debugPrint('🔥 Failed to load user data: $error');
```

**After:**
```dart
WasteAppLogger.severe('Error occurred', null, null, {'service': 'gamification', 'file': 'gamification_service'});
```

## Verification

After running the script, verify the conversions:

```bash
# Check remaining debugPrint calls
grep -R "debugPrint(" lib/services/ | wc -l

# Verify WasteAppLogger imports were added
grep -R "waste_app_logger.dart" lib/services/ | wc -l

# Test that the app still compiles
flutter analyze
```

## Safety Features

- **Dry Run Mode**: Always test with `--dry-run` first
- **Priority-Based**: Convert incrementally by priority level
- **Backup Recommended**: Git commit before running conversions
- **File Validation**: Checks if files exist before processing

## Next Steps

1. Run Priority 1 conversions (critical services)
2. Test app functionality 
3. Run Priority 2 and 3 as needed
4. Update documentation with final conversion counts 