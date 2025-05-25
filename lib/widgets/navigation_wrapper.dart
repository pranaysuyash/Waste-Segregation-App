import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';
import '../screens/home_screen.dart';
import '../screens/history_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/bottom_navigation/modern_bottom_nav.dart';
import '../utils/constants.dart';

/// Main navigation wrapper that manages the bottom navigation and screen switching
class MainNavigationWrapper extends StatefulWidget {
  final bool isGuestMode;

  const MainNavigationWrapper({
    super.key,
    this.isGuestMode = false,
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
      HomeScreen(isGuestMode: widget.isGuestMode),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content pages
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _getScreens(),
          ),
          
          // Bottom navigation overlay
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
                    style: ModernBottomNavStyle.glassmorphism(
                      primaryColor: AppTheme.primaryColor,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      HomeScreen(isGuestMode: widget.isGuestMode),
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
