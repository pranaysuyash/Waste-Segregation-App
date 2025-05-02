I/flutter (15290): Image captured: /data/user/0/com.example.waste_segregation_app/cache/scaled_7a2d6a44-e843-4bfc-9404-a5764b4256774724907847499029578.jpg
I/flutter (15290): Camera picker result: Image captured
I/flutter (15290): Navigating to image capture screen with image: /data/user/0/com.example.waste_segregation_app/cache/scaled_7a2d6a44-e843-4bfc-9404-a5764b4256774724907847499029578.jpg
I/flutter (15290): Analyzing mobile image file: /data/user/0/com.example.waste_segregation_app/cache/scaled_7a2d6a44-e843-4bfc-9404-a5764b4256774724907847499029578.jpg
I/flutter (15290): Error response: [{
I/flutter (15290): "error": {
I/flutter (15290): "code": 503,
I/flutter (15290): "message": "The model is overloaded. Please try again later.",
I/flutter (15290): "status": "UNAVAILABLE"
I/flutter (15290): }
I/flutter (15290): }
I/flutter (15290): ]
I/flutter (15290): Error analyzing image: Exception: Failed to analyze image: 503
I/flutter (15290): Analysis error: Exception: Failed to analyze image: 503
I/flutter (15290): Analyzing mobile image file: /data/user/0/com.example.waste_segregation_app/cache/scaled_7a2d6a44-e843-4bfc-9404-a5764b4256774724907847499029578.jpg
I/flutter (15290): Mobile image analysis complete: Bear Water Bottle
I/flutter (15290): Navigation to results screen with classification
Another exception was thrown: A RenderFlex overflowed by 9.2 pixels on the right.
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=io.flutter.embedding.android.FlutterActivity$1@4723c77
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=io.flutter.embedding.android.FlutterActivity$1@4723c77
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=io.flutter.embedding.android.FlutterActivity$1@4723c77
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=io.flutter.embedding.android.FlutterActivity$1@4723c77
D/mali_gralloc(15290): unregister: id=245000028ee, handle=0xb400007645543c10, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028f0, handle=0xb40000764554e170, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028ed, handle=0xb400007645544bd0, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028f1, handle=0xb4000076455828b0, base=0x0, importpid=15290, count:0
I/FA (15290): Application backgrounded at: timestamp_millis: 1746194543974
Lost connection to device.
D/mali_gralloc(15290): unregister: id=245000028be, handle=0xb4000076455748d0, base=0x0, importpid=15290, count:0
I/FA (15290): Application backgrounded at: timestamp_millis: 1746194465828
W/segregation_app(15290): Cleared Reference was only reachable from finalizer (only reported once)
I/segregation_app(15290): Background concurrent mark compact GC freed 7590KB AllocSpace bytes, 61(1988KB) LOS objects, 85% free, 4102KB/28MB, paused 858us,9.140ms total 71.344ms
E/OpenGLRenderer(15290): Unable to match the desired swap behavior.
E/mali_gralloc(15290): Requested R8 format is not supported with this allocator. R8 format is only supported with the AIDL allocator
E/mali_gralloc(15290): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/mali_gralloc(15290): ERROR: Format allocation info not found for format: 3b
E/mali_gralloc(15290): ERROR: Format allocation info not found for format: 0
E/mali_gralloc(15290): Invalid base format! req_base_format = 0x0, req_format = 0x3b
E/mali_gralloc(15290): ERROR: Unrecognized and/or unsupported format 0x3b and usage 0xb00
E/mali_gralloc(15290): Requested R8 format is not supported with this allocator. R8 format is only supported with the AIDL allocator
E/mali_gralloc(15290): ERROR: Unrecognized and/or unsupported format 0x38 and usage 0xb00
E/mali_gralloc(15290): ERROR: Format allocation info not found for format: 3b
E/mali_gralloc(15290): ERROR: Format allocation info not found for format: 0
E/mali_gralloc(15290): Invalid base format! req_base_format = 0x0, req_format = 0x3b
E/mali_gralloc(15290): ERROR: Unrecognized and/or unsupported format 0x3b and usage 0xb00
The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#4c8cf relayoutBoundary=up39 OVERFLOWING:
creator: Row ← Column ← Expanded ← Row ← Padding ← Semantics ← DefaultTextStyle ←
AnimatedDefaultTextStyle ← \_InkFeatures-[GlobalKey#82b6e ink renderer] ←
NotificationListener<LayoutChangedNotification> ← CustomPaint ← \_ShapeBorderPaint ← ⋯
parentData: offset=Offset(0.0, 27.0); flex=null; fit=null (can use size)
constraints: BoxConstraints(0.0<=w<=196.0, 0.0<=h<=Infinity)
size: Size(196.0, 21.0)
direction: horizontal
mainAxisAlignment: start
mainAxisSize: max
crossAxisAlignment: center
textDirection: ltr
verticalDirection: down
spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════

I/Choreographer(15290): Skipped 85 frames! The application may be doing too much work on its main thread.
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=io.flutter.embedding.android.FlutterActivity$1@4723c77
D/mali_gralloc(15290): register: id=245000028c7, handle=0xb400007645583510, importpid=-1, gRegisteredHandles=6
A Dart VM Service on RMX3933 is available at: http://127.0.0.1:60739/yREAG58IXd0=/
I/Choreographer(15290): Skipped 78 frames!  The application may be doing too much work on its main thread.
The Flutter DevTools debugger and profiler on RMX3933 is available at: http://127.0.0.1:9103?uri=http://127.0.0.1:60739/yREAG58IXd0=/
I/Choreographer(15290): Skipped 48 frames!  The application may be doing too much work on its main thread.
D/mali_gralloc(15290): register: id=245000028be, handle=0xb4000076455748d0, importpid=-1, gRegisteredHandles=5
I/OpenGLRenderer(15290): Davey! duration=833ms; Flags=1, FrameTimelineVsyncId=3899621, IntendedVsync=23264019324849, Vsync=23264818430193, InputEventId=0, HandleInputStart=23264826314551, AnimationStart=23264826319397, PerformTraversalsStart=23264826321589, DrawStart=23264829970743, FrameDeadline=23264035991516, FrameInterval=23264825468282, FrameStartTime=16648028, SyncQueued=23264831575358, SyncStart=23264832537666, IssueDrawCommandsStart=23264834702782, SwapBuffers=23264849493820, FrameCompleted=23264853404743, DequeueBufferDuration=4605770, QueueBufferDuration=980000, GpuCompleted=23264853404743, SwapBuffersCompleted=23264852717474, DisplayPresentTime=-5476376635151192088, CommandSubmissionCompleted=23264849493820, 
D/ProfileInstaller(15290): Installing profile for com.example.waste_segregation_app
E/OpenGLRenderer(15290): Unable to match the desired swap behavior.
D/mali_gralloc(15290): register: id=245000028bf, handle=0xb400007645571990, importpid=-1, gRegisteredHandles=6
D/mali_gralloc(15290): register: id=245000028c0, handle=0xb4000076455762b0, importpid=-1, gRegisteredHandles=7
D/mali_gralloc(15290): register: id=245000028c1, handle=0xb400007645569dd0, importpid=-1, gRegisteredHandles=8
D/mali_gralloc(15290): register: id=245000028c2, handle=0xb400007645578d70, importpid=-1, gRegisteredHandles=9
I/FA      (15290): Application backgrounded at: timestamp_millis: 1746194449943
D/CompatibilityChangeReporter(15290): Compat change id reported: 78294732; UID 10326; state: ENABLED
I/flutter (15290): Checking camera availability...
I/flutter (15290): Camera setup completed. Success: true
W/WindowOnBackDispatcher(15290): sendCancelIfRunning: isInProgress=falsecallback=android.app.Activity$$ExternalSyntheticLambda0@61bbfec
D/mali_gralloc(15290): unregister: id=245000028c1, handle=0xb400007645569dd0, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028c0, handle=0xb4000076455762b0, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028bf, handle=0xb400007645571990, base=0x0, importpid=15290, count:0
D/mali_gralloc(15290): unregister: id=245000028c2, handle=0xb400007645578d70, base=0x0, importpid=15290, count:0

══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 4.8 pixels on the right.

The relevant error-causing widget was:
Row
Row:file:///Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/lib/screens/home_screen.dart:1239:43

To inspect this widget in Flutter DevTools, visit:
http://127.0.0.1:9103/#/inspector?uri=http%3A%2F%2F127.0.0.1%3A60739%2FyREAG58IXd0%3D%2F&inspectorRef=inspector-0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import the platform-agnostic web utilities
// Platform-agnostic stub
import '../utils/web_handler.dart';
import 'package:image_picker/image_picker.dart';
// Use a platform-agnostic camera interface instead
import '../widgets/platform_camera.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../models/educational_content.dart';
import '../models/gamification.dart';
import '../services/google_drive_service.dart';
import '../services/storage_service.dart';
import '../services/educational_content_service.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../widgets/capture_button.dart';
import '../widgets/gamification_widgets.dart';
import 'auth_screen.dart';
import 'history_screen.dart';
import 'image_capture_screen.dart';
import 'result_screen.dart';
import 'educational_content_screen.dart';
import 'content_detail_screen.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatefulWidget {
final bool isGuestMode;

const HomeScreen({
super.key,
this.isGuestMode = false,
});

@override
State<HomeScreen> createState() => \_HomeScreenState();
}

class \_HomeScreenState extends State<HomeScreen> {
final ImagePicker \_imagePicker = ImagePicker();
List<WasteClassification> \_recentClassifications = [];
bool \_isLoading = false;
String? \_userName;

// Gamification state
GamificationProfile? \_gamificationProfile;
List<Challenge> \_activeChallenges = [];
List<Achievement> \_recentAchievements = [];
bool \_isLoadingGamification = false;

@override
void initState() {
super.initState();
\_loadUserData();
\_loadRecentClassifications();
\_loadGamificationData();

    // Initialize camera access
    _ensureCameraAccess();

}

Future<void> \_loadGamificationData() async {
setState(() {
\_isLoadingGamification = true;
});

    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      // Update streak for today's app usage
      await gamificationService.updateStreak();

      // Get gamification profile
      final profile = await gamificationService.getProfile();

      // Get active challenges
      final challenges = await gamificationService.getActiveChallenges();

      setState(() {
        _gamificationProfile = profile;
        _activeChallenges = challenges;
        _recentAchievements = profile.achievements
            .where((a) => a.isEarned)
            .toList()
          ..sort((a, b) => b.earnedOn!.compareTo(a.earnedOn!));
      });
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load gamification data: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingGamification = false;
      });
    }

}

Future<void> \_loadUserData() async {
if (widget.isGuestMode) {
setState(() {
\_userName = 'Guest';
});
return;
}

    final storageService = Provider.of<StorageService>(context, listen: false);
    final userInfo = await storageService.getUserInfo();

    if (userInfo['displayName'] != null) {
      setState(() {
        _userName = userInfo['displayName'];
      });
    }

}

Future<void> \_loadRecentClassifications() async {
setState(() {
\_isLoading = true;
});

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final classifications = await storageService.getAllClassifications();

      setState(() {
        _recentClassifications =
            classifications.take(5).toList(); // Show only 5 most recent
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

}

Future<void> \_takePicture() async {
try {
debugPrint('Starting camera capture process...');

      // Web platform handling
      if (kIsWeb) {
        debugPrint('Web platform detected, using image_picker directly');

        // For web, we'll use the standard image_picker
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        debugPrint(
            'Camera picker result: ${image != null ? 'Image captured' : 'No image'}');

        if (image != null && mounted) {
          debugPrint('Web image captured: ${image.path}');

          // For web, we need to handle XFile differently
          try {
            // Convert XFile to bytes
            final Uint8List? imageBytes =
                await WebImageHandler.xFileToBytes(image);

            if (imageBytes != null && imageBytes.isNotEmpty) {
              // Navigate with bytes instead of File for web
              _navigateToWebImageCapture(image, imageBytes);
            } else {
              throw Exception('Failed to read image data');
            }
          } catch (webError) {
            debugPrint('Web image processing error: $webError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Error processing image. Please try again.')),
              );
            }
          }
        } else if (mounted) {
          // No image returned - user canceled or error
          debugPrint('No web image captured or user canceled');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No image captured. Please try again or use gallery option.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Mobile platform handling
      // Check if running on emulator using our enhanced detection
      final bool isEmulator = await PlatformCamera.isEmulator();

      // Show warning if using emulator
      if (isEmulator && mounted) {
        debugPrint('Detected emulator environment');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Emulator camera support may be limited. Try using the gallery option instead.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Setup camera if needed
      final bool cameraSetupSuccess = await PlatformCamera.setup();
      debugPrint('Camera setup result: $cameraSetupSuccess');

      // Try using our enhanced platform camera implementation
      debugPrint('Opening camera picker...');
      final XFile? image = await PlatformCamera.takePicture();

      debugPrint(
          'Camera picker result: ${image != null ? 'Image captured' : 'No image'}');

      if (image != null && mounted) {
        debugPrint(
            'Navigating to image capture screen with image: ${image.path}');
        // For iOS/Android, make sure we're using File properly
        final File imageFile = File(image.path);
        // Check if file exists before proceeding
        if (await imageFile.exists()) {
          _navigateToImageCapture(imageFile);
        } else {
          debugPrint('Image file does not exist: ${image.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Error accessing captured image. Please try again.')),
          );
        }
      } else if (mounted) {
        // No image returned - on emulator, this usually means the camera is not supported
        debugPrint(
            'No image returned from camera picker - likely not supported on this device/emulator');

        // Ask if user wants to try gallery instead
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Camera Unavailable'),
                content: const Text(
                    'The camera appears to be unavailable on this device or emulator. Would you like to select an image from the gallery instead?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(); // Use gallery instead
                    },
                    child: const Text('Use Gallery'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      // Log the specific error for debugging
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }

}

Future<void> \_pickImage() async {
try {
// Show loading indicator while initializing
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Opening gallery...'),
duration: Duration(seconds: 1),
),
);
}

      debugPrint('Opening gallery picker...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      debugPrint(
          'Gallery picker result: ${image != null ? 'Image selected' : 'No image'}');

      if (image != null && mounted) {
        debugPrint('Image selected: ${image.path}');

        // Handle differently for web vs mobile
        if (kIsWeb) {
          debugPrint('Processing web image from gallery');

          try {
            // For web, convert XFile to bytes
            final Uint8List? imageBytes =
                await WebImageHandler.xFileToBytes(image);

            if (imageBytes != null && imageBytes.isNotEmpty) {
              debugPrint(
                  'Web image bytes loaded successfully, size: ${imageBytes.length}');
              // Navigate with bytes instead of File for web
              _navigateToWebImageCapture(image, imageBytes);
            } else {
              throw Exception('Failed to read web image data');
            }
          } catch (webError) {
            debugPrint('Web gallery image processing error: $webError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Error processing image. Please try again.')),
              );
            }
          }
        } else {
          // For mobile platforms
          debugPrint('Processing mobile image from gallery');

          try {
            // For iOS/Android, create file handle and verify
            final File imageFile = File(image.path);

            // Verify file exists and is readable
            if (await imageFile.exists()) {
              // Check file can be read
              try {
                final fileLength = await imageFile.length();
                debugPrint('Selected image file size: $fileLength bytes');

                if (fileLength > 0) {
                  // Proceed with the valid image file
                  _navigateToImageCapture(imageFile);
                } else {
                  throw Exception('Selected image file is empty (0 bytes)');
                }
              } catch (fileError) {
                debugPrint('Error reading image file: $fileError');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Error reading selected image. Please try a different image.')),
                  );
                }
              }
            } else {
              debugPrint('Image file does not exist: ${image.path}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Error accessing selected image. Please try again.')),
                );
              }
            }
          } catch (fileError) {
            debugPrint('File error: $fileError');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Error processing selected image. Please try again.')),
              );
            }
          }
        }
      } else if (mounted) {
        // User canceled or no image was selected
        debugPrint('No image selected from gallery');
      }
    } catch (e) {
      // Log the specific error for debugging
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: ${e.toString()}')),
        );
      }
    }

}

// Navigate to image capture for mobile platforms with a File
void \_navigateToImageCapture(File imageFile) {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ImageCaptureScreen(imageFile: imageFile),
),
).then((result) {
\_loadRecentClassifications();

      // Process classification for gamification if available
      if (result != null && result is WasteClassification) {
        _processClassificationForGamification(result).then((newAchievements) {
          // Show achievement notifications
          for (final achievement in newAchievements) {
            _showAchievementNotification(achievement);
          }
        });
      }
    });

}

// Navigate to image capture for web platforms with XFile and bytes
void \_navigateToWebImageCapture(XFile xFile, Uint8List imageBytes) {
debugPrint(
'Navigating to web image capture screen with ${imageBytes.length} bytes');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(
          xFile: xFile,
          webImage: imageBytes,
        ),
      ),
    ).then((result) {
      _loadRecentClassifications();

      // Process classification for gamification if available
      if (result != null && result is WasteClassification) {
        _processClassificationForGamification(result).then((newAchievements) {
          // Show achievement notifications
          for (final achievement in newAchievements) {
            _showAchievementNotification(achievement);
          }
        });
      }
    });

}

// Show an achievement notification
void \_showAchievementNotification(Achievement achievement) {
showDialog(
context: context,
builder: (BuildContext context) {
return Dialog(
backgroundColor: Colors.transparent,
elevation: 0,
child: AchievementNotification(
achievement: achievement,
onDismiss: () {
Navigator.of(context).pop();
},
),
);
},
);
}

Future<void> \_signOut() async {
try {
final googleDriveService =
Provider.of<GoogleDriveService>(context, listen: false);
await googleDriveService.signOut();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: ${e.toString()}')),
        );
      }
    }

}

void \_showClassificationDetails(WasteClassification classification) {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ResultScreen(
classification: classification,
showActions: false,
),
),
);
}

// Process a classification through the gamification service
Future<List<Achievement>> \_processClassificationForGamification(
WasteClassification classification) async {
try {
final gamificationService =
Provider.of<GamificationService>(context, listen: false);

      // Process the classification
      await gamificationService.processClassification(classification);

      // Refresh gamification data
      await _loadGamificationData();

      // Check for newly earned achievements
      final profile = await gamificationService.getProfile();
      final earnedAchievements =
          profile.achievements.where((a) => a.isEarned).toList();

      // Find achievements earned in the last minute (new)
      final now = DateTime.now();
      final newlyEarned = earnedAchievements
          .where((a) =>
              a.earnedOn != null && now.difference(a.earnedOn!).inMinutes < 1)
          .toList();

      return newlyEarned;
    } catch (e) {
      debugPrint('Error processing gamification: $e');
      return [];
    }

}

Widget \_buildDailyTip() {
// Get daily tip from the service
final educationalService =
Provider.of<EducationalContentService>(context, listen: false);
final dailyTip = educationalService.getDailyTip();

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dailyTip.title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              // Daily badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: const Text(
                  'DAILY TIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dailyTip.content,
            style: const TextStyle(fontSize: AppTheme.fontSizeRegular),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to educational content related to this tip
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EducationalContentScreen(
                      initialCategory: dailyTip.category,
                    ),
                  ),
                );
              },
              child: const Text(AppStrings.learnMore),
            ),
          ),
        ],
      ),
    );

}

Widget \_buildEducationalSection() {
final educationalService =
Provider.of<EducationalContentService>(context, listen: false);
final featuredContent = educationalService.getFeaturedContent();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Learn About Waste',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EducationalContentScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.paddingRegular),

        // Content categories
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryCard(
                'Wet Waste',
                Icons.eco,
                AppTheme.wetWasteColor,
              ),
              _buildCategoryCard(
                'Dry Waste',
                Icons.delete_outline,
                AppTheme.dryWasteColor,
              ),
              _buildCategoryCard(
                'Hazardous',
                Icons.warning_amber,
                AppTheme.hazardousWasteColor,
              ),
              _buildCategoryCard(
                'Medical',
                Icons.medical_services,
                AppTheme.medicalWasteColor,
              ),
              _buildCategoryCard(
                'Composting',
                Icons.compost,
                Colors.green.shade800,
              ),
              _buildCategoryCard(
                'Recycling',
                Icons.recycling,
                Colors.blue.shade700,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.paddingRegular),

        // Featured content
        if (featuredContent.isNotEmpty) ...[
          const Text(
            'Featured Content',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppTheme.paddingSmall),

          // Grid of featured content
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: AppTheme.paddingRegular,
              mainAxisSpacing: AppTheme.paddingRegular,
            ),
            itemCount: featuredContent.length > 4 ? 4 : featuredContent.length,
            itemBuilder: (context, index) {
              final content = featuredContent[index];
              return _buildContentCard(content);
            },
          ),
        ],
      ],
    );

}

Widget \_buildCategoryCard(String title, IconData icon, Color color) {
return GestureDetector(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => EducationalContentScreen(
initialCategory: title,
),
),
);
},
child: Container(
width: 100,
margin: const EdgeInsets.only(right: AppTheme.paddingRegular),
decoration: BoxDecoration(
color: color.withOpacity(0.1),
borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
border: Border.all(color: color.withOpacity(0.3)),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
icon,
color: color,
size: 32,
),
const SizedBox(height: 8),
Text(
title,
style: TextStyle(
color: color,
fontWeight: FontWeight.bold,
),
textAlign: TextAlign.center,
),
],
),
),
);
}

Widget \_buildContentCard(EducationalContent content) {
return GestureDetector(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ContentDetailScreen(contentId: content.id),
),
);
},
child: Card(
clipBehavior: Clip.antiAlias,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Content image placeholder
Stack(
children: [
Container(
height: 80,
width: double.infinity,
color: Colors.grey.shade300,
child: Icon(
content.icon,
size: 32,
color: Colors.grey.shade500,
),
),

                // Content type badge
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: content.getTypeColor(),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          content.icon,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          content.type.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Category and duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // First category
                      if (content.categories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getCategoryColorCase(content.categories.first)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                          ),
                          child: Text(
                            content.categories.first,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColorCase(
                                  content.categories.first),
                            ),
                          ),
                        ),

                      // Duration
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 10,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${content.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

}

// Add missing method as a compatibility wrapper to avoid duplication errors
Color \_getCategoryColor(String category) {
return \_getCategoryColorCase(category);
}

// Build the gamification section of the home screen
Widget \_buildGamificationSection() {
if (\_isLoadingGamification) {
return const Center(
child: Padding(
padding: EdgeInsets.all(AppTheme.paddingRegular),
child: CircularProgressIndicator(),
),
);
}

    if (_gamificationProfile == null) {
      return const SizedBox
          .shrink(); // Don't show anything if profile isn't loaded
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Progress',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),

        // Streak indicator
        StreakIndicator(
          streak: _gamificationProfile!.streak,
          onTap: () {
            // Navigate to achievements screen with streak tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AchievementsScreen(initialTabIndex: 2),
              ),
            );
          },
        ),

        const SizedBox(height: AppTheme.paddingRegular),

        // Active challenges
        if (_activeChallenges.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Challenges',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AchievementsScreen(initialTabIndex: 1),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          ChallengeCard(
            challenge: _activeChallenges.first,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AchievementsScreen(initialTabIndex: 1),
                ),
              );
            },
          ),
        ],

        const SizedBox(height: AppTheme.paddingRegular),

        // Achievements grid
        AchievementGrid(
          achievements: _gamificationProfile!.achievements,
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            );
          },
        ),
      ],
    );

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(AppStrings.appName),
actions: [
// Points indicator in app bar
if (_gamificationProfile != null)
Padding(
padding: const EdgeInsets.only(right: 8.0),
child: Center(
child: PointsIndicator(
points: _gamificationProfile!.points,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) =>
const AchievementsScreen(initialTabIndex: 2),
),
);
},
),
),
),
IconButton(
icon: const Icon(Icons.emoji_events),
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const AchievementsScreen(),
),
);
},
),
IconButton(
icon: const Icon(Icons.settings),
onPressed: () {
// In a real app, this would navigate to settings
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Settings coming soon!')),
);
},
),
if (!widget.isGuestMode)
IconButton(
icon: const Icon(Icons.logout),
onPressed: _signOut,
),
],
),
body: SingleChildScrollView(
padding: const EdgeInsets.all(AppTheme.paddingRegular),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Welcome message
Text(
'Hello, $\_userName!',
style: const TextStyle(
fontSize: AppTheme.fontSizeExtraLarge,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
const Text(
'What waste would you like to identify today?',
style: TextStyle(
fontSize: AppTheme.fontSizeRegular,
color: AppTheme.textSecondaryColor,
),
),

            const SizedBox(height: AppTheme.paddingLarge),

            // Capture image button
            CaptureButton(
              type: CaptureButtonType.camera,
              onPressed: _takePicture,
            ),

            const SizedBox(height: AppTheme.paddingRegular),

            // Upload image button
            CaptureButton(
              type: CaptureButtonType.gallery,
              onPressed: _pickImage,
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Gamification section
            _buildGamificationSection(),

            const SizedBox(height: AppTheme.paddingLarge),

            // Daily tip
            _buildDailyTip(),

            const SizedBox(height: AppTheme.paddingLarge),

            // Educational content section
            _buildEducationalSection(),

            const SizedBox(height: AppTheme.paddingLarge),

            // Recent classifications
            if (_recentClassifications.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Identifications',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingSmall),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentClassifications.length,
                      itemBuilder: (context, index) {
                        final classification = _recentClassifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppTheme.paddingRegular),
                          child: InkWell(
                            onTap: () =>
                                _showClassificationDetails(classification),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusRegular),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppTheme.paddingRegular),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    if (classification.imageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.borderRadiusSmall),
                                        child: SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: Image.file(
                                            File(classification.imageUrl!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),

                                    const SizedBox(
                                        width: AppTheme.paddingRegular),

                                    // Item details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            classification.itemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme.fontSizeMedium,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    // Main category badge
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getCategoryColorCase(
                                                                classification
                                                                    .category),
                                                        borderRadius: BorderRadius
                                                            .circular(AppTheme
                                                                .borderRadiusSmall),
                                                      ),
                                                      child: Text(
                                                        classification.category,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: AppTheme
                                                              .fontSizeSmall,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    // Subcategory badge if available
                                                    if (classification
                                                            .subcategory !=
                                                        null) ...[
                                                      const SizedBox(width: 4),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withOpacity(0.05),
                                                          borderRadius: BorderRadius
                                                              .circular(AppTheme
                                                                  .borderRadiusSmall),
                                                          border: Border.all(
                                                            color: _getCategoryColorCase(
                                                                    classification
                                                                        .category)
                                                                .withOpacity(0.5),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          classification
                                                              .subcategory!,
                                                          style: TextStyle(
                                                            color:
                                                                _getCategoryColorCase(
                                                                    classification
                                                                        .category),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  _formatDate(
                                                      classification.timestamp),
                                                  style: const TextStyle(
                                                    fontSize:
                                                        AppTheme.fontSizeSmall,
                                                    color: AppTheme
                                                        .textSecondaryColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Arrow icon
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ] else if (!_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.paddingLarge),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: AppTheme.textSecondaryColor,
                      ),
                      SizedBox(height: AppTheme.paddingRegular),
                      Text(
                        'No identifications yet',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Take a photo or upload an image to get started',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

}

Color \_getCategoryColorCase(String category) {
// Convert to lowercase for case-insensitive comparison
final lowerCase = category.toLowerCase();
switch (lowerCase) {
case 'wet waste':
return AppTheme.wetWasteColor;
case 'dry waste':
return AppTheme.dryWasteColor;
case 'hazardous waste':
return AppTheme.hazardousWasteColor;
case 'medical waste':
return AppTheme.medicalWasteColor;
case 'non-waste':
return AppTheme.nonWasteColor;
default:
return AppTheme.accentColor;
}
}

String \_formatDate(DateTime date) {
final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day);
final yesterday = DateTime(now.year, now.month, now.day - 1);
final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }

}

// Platform-agnostic camera access method
Future<void> \_ensureCameraAccess() async {
try {
// Use our enhanced platform camera implementation
final bool setupSuccess = await PlatformCamera.setup();
debugPrint('Camera setup completed. Success: $setupSuccess');

      // If setup failed on a real device (not emulator), show error message
      if (!setupSuccess && !(await PlatformCamera.isEmulator()) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Camera initialization failed. You may need to grant camera permissions.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error ensuring camera access: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera setup error: ${e.toString()}')),
        );
      }
    }

}
}
