import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../services/navigation_settings_service.dart';
import '../screens/modern_home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/social_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/image_capture_screen.dart';
import '../widgets/bottom_navigation/modern_bottom_nav.dart';
import '../widgets/animated_fab.dart';
import '../widgets/platform_camera.dart';
import '../utils/constants.dart';
import '../utils/permission_handler.dart';
import '../models/user_profile.dart';
import '../models/waste_classification.dart';

/// Main navigation wrapper that manages the bottom navigation and screen switching
class MainNavigationWrapper extends StatefulWidget {

  const MainNavigationWrapper({
    super.key,
    this.isGuestMode = false,
    this.userProfile,
  });
  final bool isGuestMode;
  final UserProfile? userProfile;

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;
  
  // ADD THESE FOR DIRECT CAMERA ACCESS:
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _getScreens() {
    return [
      ModernHomeScreen(isGuestMode: widget.isGuestMode),
      const HistoryScreen(),
      const EducationalContentScreen(),
      const SocialScreen(),
      const AchievementsScreen(),
    ];
  }

  List<BottomNavItem> _getNavItems() {
    return [
      const BottomNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      const BottomNavItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'History',
      ),
      // Center item kept empty for FAB
      const BottomNavItem(
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        label: 'Learn',
      ),
      const BottomNavItem(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Social',
      ),
      const BottomNavItem(
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        label: 'Rewards',
      ),
    ];
  }

  // FIXED: Direct camera/upload implementation
  void _showCaptureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.borderRadiusLarge),
            topRight: Radius.circular(AppTheme.borderRadiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture image'),
              onTap: () {
                Navigator.pop(context);
                _takePictureDirectly();
              },
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Upload Image'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageDirectly();
              },
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Direct camera implementation
  Future<void> _takePictureDirectly() async {
    try {
      debugPrint('Taking picture directly from navigation...');
      
      // Check camera permission first (mobile only)
      if (!kIsWeb) {
        final hasPermission = await PermissionHandler.checkCameraPermission();
        if (!hasPermission && mounted) {
          PermissionHandler.showPermissionDeniedDialog(context, 'Camera');
          return;
        }
      }

      XFile? image;
      
      if (kIsWeb) {
        image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
      } else {
        // Use platform camera for mobile
        final setupSuccess = await PlatformCamera.setup();
        if (setupSuccess) {
          image = await PlatformCamera.takePicture();
        } else {
          // Fallback to regular image picker
          image = await _imagePicker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 85,
          );
        }
      }

      if (image != null && mounted) {
        _navigateToImageCapture(image);
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

  // FIXED: Direct gallery implementation
  Future<void> _pickImageDirectly() async {
    try {
      debugPrint('Picking image directly from navigation...');
      
      // For modern Android (13+), image_picker handles permissions internally
      // Only check permissions for older Android versions
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
        _navigateToImageCapture(image);
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

  // FIXED: Navigate to image capture screen
  void _navigateToImageCapture(XFile image) async {
    try {
      if (kIsWeb) {
        // Handle web
        final bytes = await image.readAsBytes();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageCaptureScreen(
                xFile: image,
                webImage: bytes,
              ),
            ),
          ).then(_handleClassificationResult);
        }
      } else {
        // Handle mobile
        final file = File(image.path);
        if (await file.exists()) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageCaptureScreen(
                  imageFile: file,
                ),
              ),
            ).then(_handleClassificationResult);
          }
        } else {
          throw Exception('Image file not found');
        }
      }
    } catch (e) {
      debugPrint('Error navigating to image capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing image: ${e.toString()}')),
        );
      }
    }
  }

  // Handle classification result
  void _handleClassificationResult(dynamic result) {
    if (result != null && result is WasteClassification) {
      // Handle gamification and ads
      final adService = Provider.of<AdService>(context, listen: false);
      adService.trackClassificationCompleted();
      
      if (adService.shouldShowInterstitial()) {
        adService.showInterstitialAd();
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image analyzed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<NavigationSettingsService>(
      builder: (context, navSettings, child) {
        // Get navigation style
        ModernBottomNavStyle navStyle;
        switch (navSettings.navigationStyle) {
          case 'material3':
            navStyle = ModernBottomNavStyle.material3(
              primaryColor: AppTheme.primaryColor,
              isDark: isDark,
            );
            break;
          case 'floating':
            navStyle = ModernBottomNavStyle.floating(
              primaryColor: AppTheme.primaryColor,
              isDark: isDark,
            );
            break;
          default:
            navStyle = ModernBottomNavStyle.glassmorphism(
              primaryColor: AppTheme.primaryColor,
              isDark: isDark,
            );
        }
        
        return Scaffold(
          body: Stack(
            children: [
              // Main content pages
              PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _getScreens(),
              ),
              
              // Bottom navigation overlay (only if enabled)
              if (navSettings.bottomNavEnabled)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Banner ad space (if not premium)
                      if (!Provider.of<PremiumService>(context).isPremiumFeature('remove_ads'))
                        Provider.of<AdService>(context).getBannerAd(),
                      
                      // Bottom navigation
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: ModernBottomNavigation(
                          currentIndex: _currentIndex,
                          onTap: _onTabTapped,
                          items: _getNavItems(),
                          style: navStyle,
                          hasNotch: navSettings.fabEnabled, // Only add notch if FAB is enabled
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Add the animated floating action button (only if enabled)
          floatingActionButton: navSettings.fabEnabled ? AnimatedFAB(
            onPressed: () => _showCaptureOptions(context),
          ) : null,
          floatingActionButtonLocation: navSettings.fabEnabled && navSettings.bottomNavEnabled 
              ? FloatingActionButtonLocation.centerDocked 
              : FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

/// Alternative navigation wrapper with different styles
class AlternativeNavigationWrapper extends StatefulWidget {

  const AlternativeNavigationWrapper({
    super.key,
    this.isGuestMode = false,
    this.style = NavigationStyle.material3,
  });
  final bool isGuestMode;
  final NavigationStyle style;

  @override
  State<AlternativeNavigationWrapper> createState() => _AlternativeNavigationWrapperState();
}

class _AlternativeNavigationWrapperState extends State<AlternativeNavigationWrapper> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> _getScreens() {
    return [
      ModernHomeScreen(isGuestMode: widget.isGuestMode),
      const HistoryScreen(),
      const EducationalContentScreen(),
      const SocialScreen(),
      const AchievementsScreen(),
      const SettingsScreen(),
    ];
  }

  List<BottomNavItem> _getNavItems() {
    return [
      const BottomNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      const BottomNavItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'History',
      ),
      const BottomNavItem(
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        label: 'Learn',
      ),
      const BottomNavItem(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Social',
      ),
      const BottomNavItem(
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        label: 'Rewards',
      ),
      const BottomNavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
      ),
    ];
  }

  ModernBottomNavStyle _getNavigationStyle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    switch (widget.style) {
      case NavigationStyle.glassmorphism:
        return ModernBottomNavStyle.glassmorphism(
          primaryColor: AppTheme.primaryColor,
          isDark: isDark,
        );
      case NavigationStyle.material3:
        return ModernBottomNavStyle.material3(
          primaryColor: AppTheme.primaryColor,
          isDark: isDark,
        );
      case NavigationStyle.floating:
        return ModernBottomNavStyle.floating(
          primaryColor: AppTheme.primaryColor,
          isDark: isDark,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: Container(
        margin: widget.style == NavigationStyle.floating 
               ? const EdgeInsets.all(16) 
               : EdgeInsets.zero,
        child: ModernBottomNavigation(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          items: _getNavItems(),
          style: _getNavigationStyle(),
        ),
      ),
    );
  }
}

/// Navigation style options
enum NavigationStyle {
  glassmorphism,
  material3,
  floating,
}
