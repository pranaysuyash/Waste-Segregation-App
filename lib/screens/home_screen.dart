import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'dart:typed_data';

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
import '../services/storage_service.dart';
import '../services/educational_content_service.dart';
import '../services/gamification_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/safe_collection_utils.dart';
import '../widgets/capture_button.dart';
import '../widgets/enhanced_gamification_widgets.dart';
import '../widgets/gamification_widgets.dart';
import '../widgets/responsive_text.dart';
import 'history_screen.dart';
import 'image_capture_screen.dart';
import 'result_screen.dart';
import 'educational_content_screen.dart';
import 'content_detail_screen.dart';
import 'achievements_screen.dart';
// import 'settings_screen.dart';
import 'waste_dashboard_screen.dart';
// import '../services/premium_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.isGuestMode = false,
  });

  final bool isGuestMode;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  List<WasteClassification> _recentClassifications = [];
  bool _isLoading = false;
  String? _userName;

  // Gamification state
  GamificationProfile? _gamificationProfile;
  List<Challenge> _activeChallenges = [];
  bool _isLoadingGamification = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentClassifications();
    _loadGamificationData();

    // Initialize camera access
    _ensureCameraAccess();
  }

  Future<void> _loadGamificationData() async {
    setState(() {
      _isLoadingGamification = true;
    });

    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      // Sync gamification data to ensure everything is up to date
      await gamificationService.syncGamificationData();

      // Update streak for today's app usage
      await gamificationService.updateStreak();

      // Get gamification profile
      final profile = await gamificationService.getProfile();

      // Get active challenges
      final challenges = await gamificationService.getActiveChallenges();

      setState(() {
      _gamificationProfile = profile;
      _activeChallenges = challenges;
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

  Future<void> _loadUserData() async {
    if (widget.isGuestMode) {
      setState(() {
        _userName = 'Guest';
      });
      return;
    }

    final storageService = Provider.of<StorageService>(context, listen: false);
    final userProfile = await storageService.getCurrentUserProfile();

    if (userProfile != null && userProfile.displayName != null && userProfile.displayName!.isNotEmpty) {
      setState(() {
        _userName = userProfile.displayName!;
      });
    } else if (userProfile != null && userProfile.email != null && userProfile.email!.isNotEmpty) {
      // Fallback to email if displayName is null or empty but email is available
      setState(() {
        _userName = userProfile.email!.split('@').first;
      });
    } else {
      setState(() {
        // Default if no valid name or email in profile (e.g. freshly created guest profile converted to full)
        _userName = 'User'; 
      });
    }
  }

  Future<void> _loadRecentClassifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final classifications = await storageService.getAllClassifications();

      setState(() {
        _recentClassifications = classifications.safeTake(5); // Show only 5 most recent using safe collection
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

  Future<void> _takePicture() async {
    try {
      debugPrint('Starting camera capture process...');

      // Web platform handling
      if (kIsWeb) {
        debugPrint('Web platform detected, using image_picker directly');

        // For web, we'll use the standard image_picker
        final image = await _imagePicker.pickImage(
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
            final imageBytes =
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
      // Camera setup successful, proceed
      if (mounted) {
        debugPrint('Camera setup completed successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Emulator camera support may be limited. Try using the gallery option instead.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Setup camera if needed
      final cameraSetupSuccess = await PlatformCamera.setup();
      debugPrint('Camera setup result: $cameraSetupSuccess');

      // Try using our enhanced platform camera implementation
      debugPrint('Opening camera picker...');
      final image = await PlatformCamera.takePicture();

      debugPrint(
          'Camera picker result: ${image != null ? 'Image captured' : 'No image'}');

      if (image != null && mounted) {
        debugPrint(
            'Navigating to image capture screen with image: ${image.path}');
        // For iOS/Android, make sure we're using File properly
        final imageFile = File(image.path);
        // Check if file exists before proceeding
        if (imageFile.existsSync()) {
          _navigateToImageCapture(imageFile);
        } else {
          debugPrint('Image file does not exist: ${image.path}');
          if (!mounted) return;
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
          unawaited(showDialog(
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
          ));
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

  Future<void> _pickImage() async {
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
      final image = await _imagePicker.pickImage(
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
            final imageBytes =
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
            final imageFile = File(image.path);

            // Verify file exists and is readable
            if (imageFile.existsSync()) {
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
  void _navigateToImageCapture(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(imageFile: imageFile),
      ),
    ).then((result) async {
      // Ensure all classifications are loaded in the recents list
      await _loadRecentClassifications();

      // Process classification for gamification if available
      if (result != null && result is WasteClassification) {
      // Track classification completion for ad frequency
      if (!mounted) return;
      final adService = Provider.of<AdService>(context, listen: false);
      adService.trackClassificationCompleted();
      
      // Check if we should show an interstitial ad
      if (adService.shouldShowInterstitial()) {
      unawaited(adService.showInterstitialAd());
      }
      
      // Process classification with improved feedback
      if (!mounted) return;
      final gamificationService = Provider.of<GamificationService>(context, listen: false);
      
      // Get previous profile for comparison
      final oldProfile = await gamificationService.getProfile();
      if (!mounted) return;
      
        // Process the classification
        final completedChallenges = await gamificationService.processClassification(result);
        if (!mounted) return;
        
        // Get updated profile
        final newProfile = await gamificationService.getProfile();
        if (!mounted) return;
        
        // Calculate points difference
        final pointsEarned = newProfile.points.total - oldProfile.points.total;
        
        // Show points earned popup if any
        if (pointsEarned > 0) {
          _showPointsEarnedPopup(pointsEarned, 'classification');
        }
        
        // Show completed challenge notification if any
        if (completedChallenges.isNotEmpty) {
          _showChallengeCompletedPopup(completedChallenges.first);
        }
        
        // Check for new achievements
        final oldAchievementIds = oldProfile.achievements
            .where((a) => a.isEarned)
            .map((a) => a.id)
            .toSet();
            
        final newlyEarnedAchievements = newProfile.achievements
            .where((a) => a.isEarned && !oldAchievementIds.contains(a.id))
            .toList();
            
        // Show achievement notifications
        for (final achievement in newlyEarnedAchievements) {
          _showAchievementNotification(achievement);
        }
        
        // Refresh gamification data
        await _loadGamificationData();
      }
    });
  }

  // Navigate to image capture for web platforms with XFile and bytes
  void _navigateToWebImageCapture(XFile xFile, Uint8List imageBytes) {
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
    ).then((result) async {
      // Ensure all classifications are loaded in the recents list
      await _loadRecentClassifications();

      // Process classification for gamification if available
      if (result != null && result is WasteClassification) {
        // Track classification completion for ad frequency
        if (!mounted) return;
        final adService = Provider.of<AdService>(context, listen: false);
        adService.trackClassificationCompleted();
        
        // Check if we should show an interstitial ad
        if (adService.shouldShowInterstitial()) {
          unawaited(adService.showInterstitialAd());
        }
        
        unawaited(_processClassificationForGamification(result).then((newAchievements) {
          if (!mounted) return;
          // Show achievement notifications
          for (final achievement in newAchievements) {
            _showAchievementNotification(achievement);
          }
        }));
      }
    });
  }

  // Show an achievement notification
  void _showAchievementNotification(Achievement achievement) {
    unawaited(showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: EnhancedAchievementNotification(
            achievement: achievement,
            onDismiss: () {
              Navigator.of(context).pop();
            },
          ),
        );
      },
    ));
  }

  void _showClassificationDetails(WasteClassification classification) {
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
  Future<List<Achievement>> _processClassificationForGamification(
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

  Widget _buildDailyTip() {
    // Get daily tip from the service
    final educationalService =
        Provider.of<EducationalContentService>(context, listen: false);
    final dailyTip = educationalService.getDailyTip();

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log the length of the daily tip title and content
          FutureBuilder(
            future: Future.microtask(() { // Ensure it runs after build
              debugPrint('Daily Tip Title Length: ${dailyTip.title.length}');
              debugPrint('Daily Tip Content Length: ${dailyTip.content.length}');
            }),
            builder: (_, __) => const SizedBox.shrink(), // No UI impact
          ),
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
            maxLines: 3, // Add maxLines
            overflow: TextOverflow.ellipsis, // Add overflow handling
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

  Widget _buildEducationalSection() {
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
                color: AppTheme.textPrimaryColor,
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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(AppStrings.viewAll), // Using AppStrings constant
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

  Widget _buildCategoryCard(String title, IconData icon, Color color) {
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildContentCard(EducationalContent content) {
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
                                    .withValues(alpha: 0.1),
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

  // Build the gamification section of the home screen
  Widget _buildGamificationSection() {
    if (_isLoadingGamification) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gamificationProfile == null) {
      return const SizedBox.shrink(); // Don't show anything if profile isn't loaded
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
        if (_activeChallenges.isNotNullOrEmpty) ...[
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
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(AppStrings.viewAll), // Using AppStrings constant
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          EnhancedChallengeCard(
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
    // Set the ad context
    final adService = Provider.of<AdService>(context, listen: false);
    adService.setInClassificationFlow(false);
    adService.setInEducationalContent(false);
    adService.setInSettings(false);
    
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveAppBarTitle(title: AppStrings.appName),
        actions: [
          // Points indicator in app bar
          if (_gamificationProfile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                              child: LifetimePointsIndicator(
                points: _gamificationProfile!.points,
                showLifetimePoints: true,
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
          // Analytics button
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Analytics Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WasteDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message - Fixed with responsive text
            LayoutBuilder(
              builder: (context, constraints) {
                final fullText = 'Hello, ${_userName ?? 'User'}!';
                const textStyle = TextStyle(
                  fontSize: AppTheme.fontSizeExtraLarge,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                );
                
                // Check if text will overflow
                final textPainter = TextPainter(
                  text: TextSpan(text: fullText, style: textStyle),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                );
                
                textPainter.layout(maxWidth: constraints.maxWidth);
                
                var displayText = fullText;
                if (textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) {
                  // Try shorter greeting
                  displayText = 'Hi, ${_userName ?? 'User'}!';
                  textPainter.text = TextSpan(text: displayText, style: textStyle);
                  textPainter.layout(maxWidth: constraints.maxWidth);
                  
                  if (textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) {
                    displayText = 'Hi!';
                  }
                }
                
                return Text(
                  displayText,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
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

                // Gamification section - Re-enabled for proper points/achievements display
                _buildGamificationSection(),

                const SizedBox(height: AppTheme.paddingLarge),

                // Analytics Card (Commented out for debugging)
                // Card(
                //   elevation: 3,
                //   child: InkWell(
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(
                //           builder: (context) => const WasteDashboardScreen(),
                //         ),
                //       );
                //     },
                //     child: Padding(
                //       padding: const EdgeInsets.all(AppTheme.paddingRegular),
                //       child: Row(
                //         children: [
                //           Container(
                //             padding: const EdgeInsets.all(8),
                //             decoration: BoxDecoration(
                //               color: AppTheme.primaryColor.withValues(alpha: 0.1),
                //               borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                //             ),
                //             child: const Icon(
                //               Icons.analytics,
                //               color: AppTheme.primaryColor,
                //               size: 36,
                //             ),
                //           ),
                //           const SizedBox(width: AppTheme.paddingRegular),
                //           const Expanded(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   'Waste Analytics Dashboard',
                //                   style: TextStyle(
                //                     fontSize: AppTheme.fontSizeMedium,
                //                     fontWeight: FontWeight.bold,
                //                     color: AppTheme.textPrimaryColor,
                //                   ),
                //                 ),
                //                 SizedBox(height: 4),
                //                 Text(
                //                   'View insights and statistics about your waste classifications',
                //                   style: TextStyle(
                //                     fontSize: AppTheme.fontSizeSmall,
                //                     color: AppTheme.textPrimaryColor,
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //           const Icon(Icons.chevron_right),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                const SizedBox(height: AppTheme.paddingLarge),

                // Daily tip
                _buildDailyTip(),

                const SizedBox(height: AppTheme.paddingLarge),

                // Educational content section
                _buildEducationalSection(),

                const SizedBox(height: AppTheme.paddingLarge),

                // Recent classifications
                if (_recentClassifications.isNotNullOrEmpty) ...[
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
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text(AppStrings.viewAll), // Using AppStrings constant
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  if (_isLoading)
                    const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                  else
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentClassifications.length,
                        itemBuilder: (context, index) {
                          final classification = _recentClassifications[index];
                          // Log lengths for recent identification fields
                          debugPrint('Recent Item: ${classification.itemName}, Length: ${classification.itemName.length}');
                          debugPrint('Recent Category: ${classification.category}, Length: ${classification.category.length}');
                          if (classification.subcategory != null) {
                            debugPrint('Recent Subcategory: ${classification.subcategory}, Length: ${classification.subcategory!.length}');
                          }
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
                                      // Thumbnail - with improved cross-platform handling
                                      if (classification.imageUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.borderRadiusSmall),
                                          child: SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: _buildClassificationImage(classification),
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
                                            // Replace nested Row with Column and Flexible Wrap
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // First row with category badges - Fixed with Flexible and constraints
                                                ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.6, // Limit to 60% of screen width
                                                  ),
                                                  child: Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: [
                                                      // Main category badge
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: _getCategoryColorCase(
                                                              classification.category)
                                                              .withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(
                                                              AppTheme.borderRadiusSmall),
                                                          ),
                                                          child: FittedBox( // Added FittedBox
                                                            fit: BoxFit.scaleDown,
                                                            child: Text(
                                                              classification.category,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: AppTheme.fontSizeSmall,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              // maxLines: 1, // Removed based on avoid_redundant_argument_values lint
                                                            ),
                                                          ),
                                                        ),
                                                        
                                                        // Subcategory badge if available
                                                        if (classification.subcategory != null)
                                                          Container(
                                                            constraints: BoxConstraints(
                                                              maxWidth: MediaQuery.of(context).size.width * 0.25, // Limit subcategory width
                                                            ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withValues(alpha: 0.05),
                                                              borderRadius: BorderRadius.circular(
                                                                  AppTheme.borderRadiusSmall),
                                                              border: Border.all(
                                                                color: _getCategoryColorCase(
                                                                    classification.category)
                                                                .withValues(alpha: 0.5),
                                                              ),
                                                            ),
                                                            child: FittedBox( // Added FittedBox
                                                              fit: BoxFit.scaleDown,
                                                              child: Text(
                                                                classification.subcategory!,
                                                                style: TextStyle(
                                                                  color: _getCategoryColorCase(
                                                                      classification.category),
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Second row with date
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDate(classification.timestamp),
                                                  style: const TextStyle(
                                                    fontSize: AppTheme.fontSizeSmall,
                                                    color: AppTheme.textSecondaryColor,
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

            // Add padding at the bottom for navigation
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColorCase(String category) {
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
        return AppTheme.secondaryColor;
    }
  }

  String _formatDate(DateTime date) {
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
  Future<void> _ensureCameraAccess() async {
    try {
      // Use our enhanced platform camera implementation
      final cameraSetupSuccess = await PlatformCamera.setup();
      debugPrint('Camera setup completed. Success: $cameraSetupSuccess');

      // If setup failed on a real device (not emulator), show error message
              if (!cameraSetupSuccess && mounted) {
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
  
  /// Builds a classification image with cross-platform support
  Widget _buildClassificationImage(WasteClassification classification) {
    if (classification.imageUrl == null) {
      return _buildImagePlaceholder();
    }
    
    // For web platform
    if (kIsWeb) {
      // Handle web image formats (data URLs)
      if (classification.imageUrl!.startsWith('web_image:')) {
        try {
          // Extract the data URL
          final dataUrl = classification.imageUrl!.substring('web_image:'.length);
          
          // Check if it's a valid data URL
          if (dataUrl.startsWith('data:image')) {
            // Create Image widget from data URL
            return Image.network(
              dataUrl,
              fit: BoxFit.cover,
              // Fade-in animation for smoother loading
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: child,
                );
              },
              // Handle errors better
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading web image: $error');
                return _buildImagePlaceholder();
              },
              // Cache images for better performance
              cacheWidth: 120, // 2x display size for high-DPI displays
              cacheHeight: 120,
            );
          }
        } catch (e) {
          debugPrint('Error processing web image data: $e');
          return _buildImagePlaceholder();
        }
      }
      
      // Handle regular URLs
      if (classification.imageUrl!.startsWith('http:') || 
          classification.imageUrl!.startsWith('https:')) {
        return Image.network(
          classification.imageUrl!,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading network image: $error');
            return _buildImagePlaceholder();
          },
          cacheWidth: 120,
          cacheHeight: 120,
        );
      }
      
      // If we got here, it's an unsupported image format for web
      return _buildImagePlaceholder();
    } 
    
    // For mobile platforms - handle file existence check properly
    try {
      final file = File(classification.imageUrl!);
      
      // Use FutureBuilder to check if the file exists before rendering
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          // Show placeholder while checking
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder();
          }
          
          // If file exists, show it
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error rendering image file: $error');
                return _buildImagePlaceholder();
              },
              cacheWidth: 120,
              cacheHeight: 120,
            );
          } 
          
          // File doesn't exist or check failed
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      debugPrint('Error handling image file: $e');
      return _buildImagePlaceholder();
    }
  }
  
  /// Builds a loading placeholder while checking file existence
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }
  
  /// Builds a placeholder for missing images
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 24,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Show a points earned popup
  void _showPointsEarnedPopup(int points, String action) {
    // Create an overlay entry
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 0,
        right: 0,
        child: Center(
          child: PointsEarnedPopup(
            points: points,
            action: action,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-dismiss after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        try {
          overlayEntry.remove();
        } catch (e) {
          // Overlay may have already been removed
        }
      }
    });
  }

  // Show a challenge completed popup
  void _showChallengeCompletedPopup(Challenge challenge) {
    // Display an overlay notification
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.fromString(challenge.iconName),
                      color: challenge.color,
                      size: 28,
                    ),
                    const SizedBox(width: AppTheme.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Challenge Completed!',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          Text(
                            challenge.title,
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                Text(
                  challenge.description,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingRegular,
                    vertical: AppTheme.paddingSmall,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${challenge.pointsReward} Points', // Ensure Challenge model has pointsReward
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeRegular,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: challenge.color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Great!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
