# Structured JSONL Logging

The Waste Segregation App now includes a comprehensive structured logging system using JSONL (JSON Lines) format. This enables better debugging, analysis, and LLM-based error investigation.

## Overview

The `WasteAppLogger` utility provides structured logging with waste-specific context and event types. All logs are written to `waste_app_logs.jsonl` in the project root and mirrored to the console during development.

## Key Features

- **Structured JSONL Format**: Each log entry is a JSON object on a single line
- **Waste-Specific Context**: Built-in methods for common waste app events
- **Session Tracking**: Automatic session IDs and app version tracking
- **Performance Monitoring**: Built-in timing and performance logging
- **Error Context**: Rich error information with stack traces
- **Real-time Analysis**: Easy to parse and analyze with command-line tools

## Log Entry Structure

Each log entry contains:

```json
{
  "timestamp": "2025-01-16T10:30:45.123Z",
  "level": "INFO",
  "logger": "WasteApp",
  "message": "User action: camera_capture_started",
  "session_id": "session_1737022245123",
  "app_version": "0.1.6+99",
  "current_action": "camera_capture_started",
  "current_screen": "camera_screen",
  "user_context": {
    "user_type": "household",
    "location": "Mumbai"
  }
}
```

## Capturing Logs via Flutter CLI

### Method 1: Machine Mode (Recommended)

Run your app in machine mode and extract app.log events:

```bash
flutter run --machine | jq -c 'select(.event == "app.log") | .params' > waste_app_logs.jsonl
```

### Method 2: Direct File Reading

The logger also writes directly to `waste_app_logs.jsonl`:

```bash
# Real-time monitoring
tail -f waste_app_logs.jsonl

# Real-time error monitoring
tail -f waste_app_logs.jsonl | jq 'select(.level=="SEVERE" or .level=="WARNING")'
```

### Method 3: Development Mode

During development, logs are also mirrored to the console with `debugPrint()`.

## Log Analysis Commands

### View Errors Only

```bash
jq 'select(.level == "SEVERE" or .level == "WARNING")' waste_app_logs.jsonl
```

### Count Errors by Message

```bash
jq -r 'select(.level == "SEVERE") | .message' waste_app_logs.jsonl | sort | uniq -c
```

### Gamification Events

```bash
jq 'select(.user_context.event_type == "gamification")' waste_app_logs.jsonl
```

### Performance Analysis

```bash
jq 'select(.user_context.event_type == "performance")' waste_app_logs.jsonl | jq '.user_context.duration_ms'
```

### User Actions Timeline

```bash
jq 'select(.user_context.event_type == "user_interaction")' waste_app_logs.jsonl | jq -r '[.timestamp, .message] | @tsv'
```

### Cache Performance

```bash
jq 'select(.user_context.event_type == "cache_operation")' waste_app_logs.jsonl | jq '.user_context.cache_hit'
```

### AI Processing Events

```bash
jq 'select(.user_context.event_type == "ai_processing")' waste_app_logs.jsonl
```

### Session Analysis

```bash
# Get all events for a specific session
jq 'select(.session_id == "session_1737022245123")' waste_app_logs.jsonl

# Count events per session
jq -r '.session_id' waste_app_logs.jsonl | sort | uniq -c
```

## Event Types

The logger includes specialized methods for different event types:

### User Actions
```dart
WasteAppLogger.userAction('camera_capture_started', context: {
  'platform': 'android'
});
```

### Waste Processing Events
```dart
WasteAppLogger.wasteEvent('classification_completed', 'plastic_bottle', context: {
  'confidence': 0.95,
  'processing_time_ms': 1200
});
```

### Performance Monitoring
```dart
WasteAppLogger.performanceLog('image_processing', 1500, context: {
  'image_size_mb': 2.3,
  'model_version': 'v2.1'
});
```

### AI Processing
```dart
WasteAppLogger.aiEvent('classification_request', 
  model: 'gpt-4-vision',
  tokensUsed: 1250,
  context: {'image_type': 'camera_capture'}
);
```

### Cache Operations
```dart
WasteAppLogger.cacheEvent('cache_hit', 'classification',
  hit: true,
  key: 'phash_abc123',
  context: {'match_type': 'exact'}
);
```

### Navigation Events
```dart
WasteAppLogger.navigationEvent('screen_change', 'home', 'camera', context: {
  'navigation_method': 'bottom_nav'
});
```

### Gamification Events
```dart
WasteAppLogger.gamificationEvent('points_earned',
  pointsEarned: 10,
  context: {'action': 'classification', 'total_points': 150}
);
```

## Context Management

Set global context that will be included in all log entries:

```dart
// Set user context
WasteAppLogger.setUserContext({
  'user_type': 'household',
  'location': 'Mumbai',
  'premium_user': true
});

// Update specific context values
WasteAppLogger.updateUserContext('current_challenge', 'daily_classifier');

// Set current screen
WasteAppLogger.setCurrentScreen('camera_screen');

// Set current action
WasteAppLogger.setCurrentAction('taking_photo');
```

## LLM Analysis Workflows

### Error Investigation

1. **Extract recent errors:**
   ```bash
   jq 'select(.level == "SEVERE" and (.timestamp | fromdateiso8601) > (now - 3600))' waste_app_logs.jsonl > recent_errors.jsonl
   ```

2. **Get error context:**
   ```bash
   jq 'select(.level == "SEVERE") | {message, error, stackTrace, user_context}' waste_app_logs.jsonl
   ```

### Performance Analysis

1. **Slow operations:**
   ```bash
   jq 'select(.user_context.event_type == "performance" and .user_context.duration_ms > 2000)' waste_app_logs.jsonl
   ```

2. **Cache performance:**
   ```bash
   jq 'select(.user_context.event_type == "cache_operation") | .user_context.cache_hit' waste_app_logs.jsonl | jq -s 'group_by(.) | map({hit: .[0], count: length})'
   ```

### User Behavior Analysis

1. **User journey mapping:**
   ```bash
   jq 'select(.user_context.event_type == "user_interaction" or .user_context.event_type == "navigation") | {timestamp, message, current_screen}' waste_app_logs.jsonl
   ```

2. **Feature usage:**
   ```bash
   jq 'select(.user_context.event_type == "user_interaction") | .message' waste_app_logs.jsonl | sort | uniq -c | sort -nr
   ```

## Integration with Development Workflow

### CI/CD Integration

Add log analysis to your CI pipeline:

```yaml
# .github/workflows/log-analysis.yml
- name: Analyze Logs
  run: |
    if [ -f waste_app_logs.jsonl ]; then
      echo "Error count: $(jq 'select(.level == "SEVERE")' waste_app_logs.jsonl | wc -l)"
      echo "Warning count: $(jq 'select(.level == "WARNING")' waste_app_logs.jsonl | wc -l)"
    fi
```

### Development Best Practices

1. **Replace debugPrint() calls** with appropriate WasteAppLogger methods
2. **Add context** to log entries for better analysis
3. **Use specific event types** rather than generic info() calls
4. **Include performance metrics** for critical operations
5. **Log user actions** for UX analysis

## File Management

### Log Rotation

The log file can grow large over time. Consider implementing log rotation:

```bash
# Rotate logs daily
mv waste_app_logs.jsonl waste_app_logs_$(date +%Y%m%d).jsonl
touch waste_app_logs.jsonl
```

### Cleanup

```bash
# Remove logs older than 7 days
find . -name "waste_app_logs_*.jsonl" -mtime +7 -delete
```

## Security Considerations

- **PII Filtering**: The logger automatically filters sensitive information
- **Log Sanitization**: User IDs are hashed, file paths are relative
- **Local Storage**: Logs are stored locally and not transmitted automatically
- **Debug Mode**: Detailed logging only occurs in debug builds

## Troubleshooting

### Logger Not Initializing

```dart
// Check if logger is initialized
try {
  WasteAppLogger.info('Test message');
} catch (e) {
  debugPrint('Logger not initialized: $e');
  await WasteAppLogger.initialize();
}
```

### Missing Log Entries

1. Ensure `WasteAppLogger.initialize()` is called in `main()`
2. Check file permissions for `waste_app_logs.jsonl`
3. Verify the app has write access to the project directory

### Large Log Files

1. Implement log rotation as shown above
2. Consider filtering log levels in production
3. Use log analysis tools to process large files efficiently

## Examples

### Complete User Journey

```json
{"timestamp":"2025-01-16T10:30:00.000Z","level":"INFO","message":"Navigation: screen_change","user_context":{"event_type":"navigation","from_screen":"home","to_screen":"camera"}}
{"timestamp":"2025-01-16T10:30:05.000Z","level":"INFO","message":"User action: camera_capture_started","user_context":{"event_type":"user_interaction","platform":"android"}}
{"timestamp":"2025-01-16T10:30:07.000Z","level":"INFO","message":"User action: camera_capture_success","user_context":{"event_type":"user_interaction","image_path":"images/capture_123.jpg"}}
{"timestamp":"2025-01-16T10:30:08.000Z","level":"INFO","message":"AI event: classification_request","user_context":{"event_type":"ai_processing","model":"gpt-4-vision"}}
{"timestamp":"2025-01-16T10:30:12.000Z","level":"INFO","message":"Waste event: classification_completed for plastic_bottle","user_context":{"event_type":"waste_processing","confidence":0.95}}
{"timestamp":"2025-01-16T10:30:12.000Z","level":"INFO","message":"Gamification event: points_earned","user_context":{"event_type":"gamification","points_earned":10,"total_points":160}}
```

This structured approach enables powerful analysis and debugging capabilities while maintaining performance and security. 