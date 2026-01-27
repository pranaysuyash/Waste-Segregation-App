# Image Quality Gate & Offline Queue — Integration Guide

**Date:** 2026-01-27  
**Status:** ✅ Implemented, ready for integration

---

## Track 1: Image Quality Gate Integration

### Quick Start

Add quality check before AI classification:

```dart
import 'package:waste_segregation_app/services/image_quality_gate.dart';

Future<void> onImageCaptured(Uint8List imageBytes) async {
  // Show checking indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking image quality...'),
        ],
      ),
    ),
  );
  
  final quality = await ImageQualityGate.check(imageBytes);
  
  Navigator.pop(context); // Hide checking indicator
  
  if (!quality.isValid) {
    // Show quality warning dialog
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.warning_amber, color: Colors.orange, size: 48),
        title: Text('Image Quality Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quality.reason,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(quality.suggestion),
            if (quality.metrics != null) ...[
              SizedBox(height: 16),
              Text(
                'Details:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              ...quality.metrics!.entries.map((e) => 
                Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Retake Photo'),
          ),
          ElevatedButton(
            onPressed: () {
              AnalyticsService.log('image.quality_override', {
                'failure_type': quality.failureType?.name,
              });
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text('Use Anyway'),
          ),
        ],
      ),
    );
    
    if (proceed != true) return; // User chose to retake
  }
  
  // Quality passed or user overrode - proceed with classification
  _classifyImage(imageBytes);
}
```

### Customizing Thresholds

Adjust thresholds based on your needs:

```dart
// In app initialization (e.g., main.dart)
void configureImageQuality() {
  ImageQualityGate.minDimension = 400; // Stricter resolution
  ImageQualityGate.minVariance = 120.0; // Stricter blur threshold
  ImageQualityGate.minBrightness = 50; // Allow slightly darker
  ImageQualityGate.maxBrightness = 240; // Stricter overexposure
}
```

---

## Track 2: Offline Queue Integration

### 1. Initialize in App Startup

Add to `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... other initialization
  
  // Initialize offline queue service
  await OfflineQueueService().init();
  
  runApp(MyApp());
}
```

### 2. Check Connectivity Before Classification

In your capture/classification flow:

```dart
import 'package:waste_segregation_app/services/offline_queue_service.dart';

Future<void> onCapturePressed(Uint8List imageBytes) async {
  final queueService = OfflineQueueService();
  
  // Check if offline
  if (await queueService.isOffline) {
    // Queue for later processing
    await queueService.queue(
      imageBytes: imageBytes,
      region: userRegion,
      userId: currentUser?.uid,
      imageName: 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.offline_bolt, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Offline - Classification queued (${queueService.pendingCount} pending)',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => _showQueueDialog(context),
        ),
        duration: Duration(seconds: 5),
        backgroundColor: Colors.orange,
      ),
    );
    
    return;
  }
  
  // Online - proceed normally
  _classifyImage(imageBytes);
}
```

### 3. Add Queue Status UI

Show queue count in AppBar or drawer:

```dart
StreamBuilder<int>(
  stream: OfflineQueueService().queueCountStream,
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    if (count == 0) return SizedBox.shrink();
    
    return Badge(
      label: Text('$count'),
      backgroundColor: Colors.orange,
      child: IconButton(
        icon: Icon(Icons.cloud_off),
        tooltip: 'Offline Queue',
        onPressed: () => _showQueueDialog(context),
      ),
    );
  },
)
```

### 4. Queue Management Dialog

```dart
void _showQueueDialog(BuildContext context) {
  final queueService = OfflineQueueService();
  final items = queueService.getPendingItems();
  
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.offline_bolt, color: Colors.orange),
          SizedBox(width: 8),
          Text('Offline Queue'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${items.length} classification${items.length == 1 ? '' : 's'} waiting to be processed',
          ),
          if (items.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Items will be processed automatically when you\'re back online.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(Icons.image, size: 32),
                    title: Text(item.imageName ?? 'Image ${index + 1}'),
                    subtitle: Text(
                      'Queued ${_formatTimeAgo(item.queuedAt)}',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: item.retryCount > 0
                        ? Chip(
                            label: Text('Retry ${item.retryCount}'),
                            backgroundColor: Colors.orange.shade100,
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (items.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              queueService.clearQueue();
            },
            child: Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            queueService.forceRetry();
          },
          child: Text('Retry Now'),
        ),
      ],
    ),
  );
}

String _formatTimeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
```

---

## Testing Checklist

### Image Quality Gate
- [ ] Test with good quality image (800x600, well-lit, sharp) → should pass
- [ ] Test with small image (200x150) → should show "too small" warning
- [ ] Test with blurry image → should show "too blurry" warning
- [ ] Test with dark image → should show "too dark" warning
- [ ] Test with overexposed image → should show "overexposed" warning
- [ ] Test "Use Anyway" override → should proceed to classification
- [ ] Verify analytics events are logged correctly
- [ ] Test with invalid image data → should fail-open and allow

### Offline Queue
- [ ] Turn off WiFi/cellular → capture should queue instead of fail
- [ ] Verify queue count badge appears and updates
- [ ] Turn on connectivity → queue should process automatically
- [ ] Test force retry button → should reprocess queued items
- [ ] Test clear queue button → should remove all pending items
- [ ] Verify queue persists across app restarts
- [ ] Test max 3 retries → items should be removed after 3 failures
- [ ] Verify stream updates UI in real-time

---

## Performance Notes

- **Quality Gate:** Runs in ~200-500ms for typical images (sampling optimization)
- **Queue Processing:** Processes items serially to avoid overwhelming API
- **Memory:** Queue stores compressed images to minimize storage

---

## Analytics Events

Track these events for monitoring:

```dart
// Quality Gate
'image.quality_passed' — Image passed all checks
'image.quality_rejected' — Image failed quality check
'image.quality_override' — User chose "Use Anyway"
'image.quality_check_error' — Quality check crashed (fail-open)

// Offline Queue
'classification.queued_offline' — Item added to queue
'classification.queue_processed' — Queue processing completed
'classification.queue_permanent_fail' — Item failed 3 retries
'classification.queue_cleared' — User cleared queue
```
