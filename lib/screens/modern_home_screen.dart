import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Import the platform-agnostic web utilities
import '../utils/web_handler.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/platform_camera.dart';
import 'package:provider/provider.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/safe_collection_utils.dart';
import '../utils/permission_handler.dart';
import 'history_screen.dart';
import 'image_capture_screen.dart';
import 'result_screen.dart';
import 'educational_content_screen.dart';
import 'achievements_screen.dart';
import 'waste_dashboard_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';
import 'disposal_facilities_screen.dart';

// Import modern UI components
import '../widgets/modern_ui/modern_cards.dart';
import '../widgets/modern_ui/modern_buttons.dart';
import '../widgets/modern_ui/modern_badges.dart';
import '../widgets/responsive_text.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/data_migration_dialog.dart';
import '../services/cloud_storage_service.dart';
import '../services/community_service.dart';
import '../models/community_feed.dart';

class ModernHomeScreen extends StatefulWidget {

  const ModernHomeScreen({
    super.key,
    this.isGuestMode = false,
  });
  final bool isGuestMode;
  static VoidCallback? _refreshCallback;

  // Static method to trigger refresh from anywhere in the app
  static void triggerRefresh() {
    _refreshCallback?.call();
  }

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();
  List<WasteClassification> _recentClassifications = [];
  List<WasteClassification> _allClassifications = [];
  bool _isLoading = false;
  String? _userName;
  DateTime? _lastRefresh;

  // Gamification state
  GamificationProfile? _gamificationProfile;
  List<Challenge> _activeChallenges = [];
  bool _isLoadingGamification = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Register the refresh callback
    ModernHomeScreen._refreshCallback = () {
      if (mounted) {
        debugPrint('ModernHomeScreen: Static refresh triggered');
        _refreshDataWithTimestamp();
      }
    };
    
    _initializeAnimations();
    _loadUserData();
    _loadRecentClassifications();
    _loadGamificationData();
    _ensureCameraAccess();
    
    // Check for data migration after a short delay to let the UI settle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDataMigration();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Clean up the refresh callback
    ModernHomeScreen._refreshCallback = null;
    
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Force refresh data when app comes back to foreground
      debugPrint('App resumed - forcing data refresh');
      _refreshDataWithTimestamp();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadGamificationData() async {
    setState(() {
      _isLoadingGamification = true;
    });

    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      await gamificationService.updateStreak();
      final profile = await gamificationService.getProfile();
      final challenges = await gamificationService.getActiveChallenges();

      setState(() {
        _gamificationProfile = profile;
        _activeChallenges = challenges;
      });
    } catch (e) {
      debugPrint('Error loading gamification data: $e');
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
      setState(() {
        _userName = userProfile.email!.split('@').first;
      });
    } else {
      setState(() {
        _userName = 'User'; 
      });
    }
  }

  Future<void> _loadRecentClassifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);
      
      // Get Google sync setting
      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      
      // Load classifications with cloud sync if enabled
      final classifications = isGoogleSyncEnabled
          ? await cloudStorageService.getAllClassificationsWithCloudSync(isGoogleSyncEnabled)
          : await storageService.getAllClassifications();

      setState(() {
        _allClassifications = classifications;
        _recentClassifications = (classifications.length <= 3) 
            ? classifications 
            : classifications.sublist(0, 3);
      });
      
      debugPrint('📊 Loaded ${classifications.length} total classifications (Google sync: $isGoogleSyncEnabled)');
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

  // Made public for access from the navigation wrapper
  Future<void> takePicture() async {
    try {
      debugPrint('Starting camera capture process...');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Opening camera...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (!kIsWeb) {
        final hasPermission = await PermissionHandler.checkCameraPermission();
        if (!hasPermission && mounted) {
          PermissionHandler.showPermissionDeniedDialog(context, 'Camera');
          return;
        }
      }

      if (kIsWeb) {
        final image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (image != null && mounted) {
          try {
            final imageBytes =
                await WebImageHandler.xFileToBytes(image);

            if (imageBytes != null && imageBytes.isNotEmpty) {
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
        }
        return;
      }

      // For mobile, capture directly
      final capturedXFile = await PlatformCamera.takePicture(); 
      if (capturedXFile != null && mounted) {
        _navigateToImageCapture(File(capturedXFile.path)); 
      } else if (mounted) {
        debugPrint('Mobile camera capture cancelled or failed.');
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  // Made public for access from the navigation wrapper
  Future<void> pickImage() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Opening gallery...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      if (!kIsWeb) {
        try {
          // Try to check permission, but don't block if it fails
          final hasPermission = await PermissionHandler.checkStoragePermission();
          debugPrint('Storage/Photos permission check result: $hasPermission');
          
          // Don't block the flow - let image_picker handle it
          // Modern Android versions handle this automatically
        } catch (e) {
          debugPrint('Permission check failed, proceeding anyway: $e');
          // Continue - image_picker will handle permissions
        }
      }
      
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        if (kIsWeb) {
          try {
            final imageBytes =
                await WebImageHandler.xFileToBytes(image);

            if (imageBytes != null && imageBytes.isNotEmpty) {
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
          final imageFile = File(image.path);
          if (await imageFile.exists()) {
            final fileLength = await imageFile.length();
            if (fileLength > 0) {
              _navigateToImageCapture(imageFile);
            } else {
              throw Exception('Selected image file is empty (0 bytes)');
            }
          } else {
             throw Exception('Selected image file does not exist.');
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToImageCapture(File imageFile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(imageFile: imageFile),
      ),
    );
    
    // Force refresh data after returning from image capture flow
    if (mounted) {
      debugPrint('Returned from ImageCaptureScreen - forcing data refresh');
      await _refreshDataWithTimestamp();
    }
  }

  void _navigateToWebImageCapture(XFile xFile, Uint8List imageBytes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCaptureScreen(xFile: xFile, webImage: imageBytes),
      ),
    );
    
    // Force refresh data after returning from image capture flow
    if (mounted) {
      debugPrint('Returned from WebImageCaptureScreen - forcing data refresh');
      await _refreshDataWithTimestamp();
    }
  }

  Future<void> _processClassificationForGamification(
      WasteClassification classification) async {
    try {
      final gamificationService =
          Provider.of<GamificationService>(context, listen: false);

      await gamificationService.processClassification(classification);
      _loadGamificationData();
    } catch (e) {
      debugPrint('Error processing gamification: $e');
    }
  }

  Future<void> _ensureCameraAccess() async {
    try {
      final setupSuccess = await PlatformCamera.setup();
      debugPrint('Camera setup completed. Success: $setupSuccess');
    } catch (e) {
      debugPrint('Error ensuring camera access: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adService = Provider.of<AdService>(context, listen: false);
    adService.setInClassificationFlow(false);
    adService.setInEducationalContent(false);
    adService.setInSettings(false);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: theme.colorScheme.primary,
                    size: AppTheme.iconSizeMd,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                                  Expanded(
                    child: ResponsiveAppBarTitle(
                      title: 'WasteWise',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          // Achievement points badge
          if (_gamificationProfile != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AchievementsScreen(initialTabIndex: 2),
                    ),
                  );
                },
                child: ModernBadge(
                  text: '${_gamificationProfile!.points.total}',
                  icon: Icons.stars,
                  style: ModernBadgeStyle.soft,
                  backgroundColor: Colors.amber,
                ),
              ),
            ),
          // Settings menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.onSurface,
            ),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  // FIXED: Use direct navigation instead of named routes
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
                case 'profile':
                  // Navigate to profile/account screen - you can create this or redirect to settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                  break;
                case 'help':
                  // Show help dialog or navigate to help screen
                  _showHelpDialog(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(theme),
                const SizedBox(height: AppTheme.spacingMd),
                _buildTodaysImpactGoal(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildStatsSection(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildGlobalImpactMeter(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildCommunityFeedPreview(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildGamificationSection(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickAccessSection(),
                const SizedBox(height: AppTheme.spacingMd),
                _buildRecentClassifications(),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (timeOfDay < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nights_stay;
    }

    return ModernCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withOpacity(0.8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                greetingIcon,
                color: Colors.white,
                size: AppTheme.iconSizeLg,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: GreetingText(
                  greeting: greeting,
                  userName: _userName ?? 'User',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'What waste would you like to identify today?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Action buttons for camera and gallery
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Take Photo',
                  icon: Icons.camera_alt,
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  onPressed: takePicture,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: ModernButton(
                  text: 'Upload',
                  icon: Icons.photo_library,
                  style: ModernButtonStyle.outlined,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  onPressed: pickImage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ActionCard(
          title: 'Take Photo',
          subtitle: 'Take a photo to identify',
          icon: Icons.camera_alt,
          onTap: takePicture,
          color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: ActionCard(
            title: 'Upload Image',
            subtitle: 'Choose from gallery',
            icon: Icons.photo_library,
            onTap: pickImage,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Classifications',
            value: '${_allClassifications.length}',
            icon: Icons.analytics,
            color: AppTheme.infoColor,
            trend: '+12%',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: StatsCard(
            title: 'Streak',
            value: '${_gamificationProfile?.streak.current ?? 0}',
            icon: Icons.local_fire_department,
            color: Colors.orange,
            subtitle: 'days',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: StatsCard(
            title: 'Points',
            value: '${_gamificationProfile?.points.total ?? 0}',
            icon: Icons.stars,
            color: Colors.amber,
            trend: '+24',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationSection() {
    if (_isLoadingGamification || _gamificationProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        if (_activeChallenges.isNotNullOrEmpty) ...[
          FeatureCard(
            icon: Icons.emoji_events,
            title: 'Active Challenge',
            subtitle: _activeChallenges.first.description,
            trailing: ProgressBadge(
              progress: _activeChallenges.first.progress,
              text: '${(_activeChallenges.first.progress * 100).toInt()}%',
            ),
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
          const SizedBox(height: AppTheme.spacingMd),
        ],
        
        // Recent achievements
        if (_gamificationProfile!.achievements.where((a) => a.isEarned).isNotEmpty)
          FeatureCard(
            icon: Icons.military_tech,
            title: 'Latest Achievement',
            subtitle: _gamificationProfile!.achievements
                .where((a) => a.isEarned)
                .last
                .title,
            trailing: const ModernBadge(
              text: 'NEW',
              backgroundColor: Colors.green,
              size: ModernBadgeSize.small,
              showPulse: true,
            ),
            onTap: () {
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

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        FeatureCard(
          icon: Icons.analytics,
          title: 'Analytics Dashboard',
          subtitle: 'View detailed insights and statistics',
          iconColor: AppTheme.infoColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WasteDashboardScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.school,
          title: 'Learn About Waste',
          subtitle: 'Educational content and tips',
          iconColor: AppTheme.successColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EducationalContentScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.location_on,
          title: 'Disposal Facilities',
          subtitle: 'Find nearby waste disposal locations',
          iconColor: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DisposalFacilitiesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentClassifications() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentClassifications.isEmpty) {
      return ModernCard(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: AppTheme.iconSizeXl,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No classifications yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Take a photo or upload an image to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Classifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                ViewAllButton(
                  text: 'View All (${_allClassifications.length})',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        ..._recentClassifications.map((classification) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: RecentClassificationCard(
              itemName: classification.itemName,
              category: classification.category,
              subcategory: classification.subcategory,
              timestamp: classification.timestamp,
              imageUrl: classification.imageUrl,
              isRecyclable: classification.isRecyclable,
              isCompostable: classification.isCompostable,
              requiresSpecialDisposal: classification.requiresSpecialDisposal,
              categoryColor: _getCategoryColor(classification.category),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      classification: classification,
                      showActions: false,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return Icons.eco;
      case 'dry waste':
        return Icons.recycling;
      case 'hazardous waste':
        return Icons.warning;
      case 'medical waste':
        return Icons.medical_services;
      case 'non-waste':
        return Icons.check_circle;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
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
        return AppTheme.neutralColor;
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to use WasteWise:'),
            SizedBox(height: 8),
            Text('1. Take a photo or upload an image of waste'),
            Text('2. Get AI-powered classification'),
            Text('3. Follow disposal instructions'),
            Text('4. Earn points and achievements'),
            SizedBox(height: 16),
            Text('Need more help? Check the Settings for tutorials and guides.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About WasteWise'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WasteWise - Smart Waste Classification'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 8),
            Text('An AI-powered app to help you classify and manage waste properly.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysImpactGoal() {
    final now = DateTime.now();
    final todayClassifications = _allClassifications 
        .where((c) => _isToday(c.timestamp))
        .toList();
    
    // Debug logging
    debugPrint('=== Today\'s Impact Debug ===');
    debugPrint('Current date: ${now.year}-${now.month}-${now.day}');
    debugPrint('Total classifications: ${_allClassifications.length}');
    debugPrint('Today\'s classifications: ${todayClassifications.length}');
    for (final classification in todayClassifications) {
      debugPrint('  - ${classification.itemName} at ${classification.timestamp}');
    }
    debugPrint('========================');

    return TodaysImpactGoal(
      currentClassifications: todayClassifications.length,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AchievementsScreen(),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    
    debugPrint('Checking if $date is today ($today): ${today == checkDate}');
    
    return today == checkDate;
  }

  Widget _buildGlobalImpactMeter() {
    return const GlobalImpactMeter(
      globalCO2Saved: 2.5, // Sample data - would come from backend
      globalItemsClassified: 50000, // Sample data
      activeUsers: 10500, // Sample data
    );
  }

  Widget _buildCommunityFeedPreview() {
    return FutureBuilder<List<CommunityFeedItem>>(
      future: CommunityService().getFeedItems(limit: 3),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final feedItems = snapshot.data ?? [];
        if (feedItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No community activity yet',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to share your progress!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }
        final activities = feedItems.map((item) => CommunityActivity(
          userName: item.displayName,
          action: item.title.isNotEmpty ? item.title : item.description,
          timeAgo: item.relativeTime,
          achievement: item.activityType == CommunityActivityType.achievement ? '🏆' : null,
        )).toList();
        return CommunityFeedPreview(
          activities: activities,
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SocialScreen(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Refresh data when returning to this screen from any navigation
    // But only if it's been more than 2 seconds since last refresh to avoid excessive calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final now = DateTime.now();
        if (_lastRefresh == null || now.difference(_lastRefresh!).inSeconds > 2) {
          debugPrint('ModernHomeScreen: didChangeDependencies - refreshing data');
          _refreshDataWithTimestamp();
        }
      }
    });
  }

  Future<void> _refreshDataWithTimestamp() async {
    _lastRefresh = DateTime.now();
    await _loadRecentClassifications();
    await _loadGamificationData();
  }

  // Public method to refresh data - can be called from other screens
  Future<void> refreshData() async {
    await _refreshDataWithTimestamp();
  }

  void _checkDataMigration() async {
    if (!widget.isGuestMode) {
      try {
        await DataMigrationDialog.showIfNeeded(context);
        // Refresh data after potential migration
        await _loadRecentClassifications();
      } catch (e) {
        debugPrint('Error checking data migration: $e');
      }
    }
  }
}
