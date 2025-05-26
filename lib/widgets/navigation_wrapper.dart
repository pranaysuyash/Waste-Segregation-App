import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../services/navigation_settings_service.dart';
import '../screens/modern_home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/family_dashboard_screen.dart';
import '../widgets/bottom_navigation/modern_bottom_nav.dart';
import '../widgets/animated_fab.dart';
import '../utils/constants.dart';
import '../models/user_profile.dart';

/// Main navigation wrapper that manages the bottom navigation and screen switching
class MainNavigationWrapper extends StatefulWidget {
  final bool isGuestMode;
  final UserProfile? userProfile;

  const MainNavigationWrapper({
    super.key,
    this.isGuestMode = false,
    this.userProfile,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;

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
        icon: Icons.emoji_events_outlined,
        selectedIcon: Icons.emoji_events,
        label: 'Rewards',
      ),
    ];
  }

  // Camera/upload actions
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
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to capture image'),
              onTap: () {
                // Get instance of ModernHomeScreen
                Navigator.pop(context);
                // Access the home screen widget and call its public method
                final homeScreen = _getScreens()[0] as ModernHomeScreen;
                homeScreen.takePicture();
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
                // Get instance of ModernHomeScreen
                Navigator.pop(context);
                // Access the home screen widget and call its public method
                final homeScreen = _getScreens()[0] as ModernHomeScreen;
                homeScreen.pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
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
            icon: Icons.camera_alt,
            tooltip: 'Scan Waste',
            isPulsing: true,
            showCelebration: false,
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
  final bool isGuestMode;
  final NavigationStyle style;

  const AlternativeNavigationWrapper({
    super.key,
    this.isGuestMode = false,
    this.style = NavigationStyle.material3,
  });

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
