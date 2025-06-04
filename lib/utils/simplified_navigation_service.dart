import 'package:flutter/material.dart';

/// Simplified navigation service to reduce settings complexity and improve UX
class SimplifiedNavigationService {
  
  // ==================== DIRECT ACCESS HELPERS ====================
  
  /// Navigate directly to specific settings sections without multiple taps
  static void navigateToAccountSettings(BuildContext context) {
    // Direct navigation to account-specific settings
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountSettingsScreen(),
      ),
    );
  }
  
  static void navigateToAppPreferences(BuildContext context) {
    // Direct navigation to app preferences
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppPreferencesScreen(),
      ),
    );
  }
  
  static void navigateToPrivacySettings(BuildContext context) {
    // Direct navigation to privacy settings
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }
  
  static void navigateToHelpAndSupport(BuildContext context) {
    // Direct navigation to help
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpAndSupportScreen(),
      ),
    );
  }
  
  // ==================== QUICK SETTINGS ACCESS ====================
  
  /// Show quick settings bottom sheet for common actions
  static void showQuickSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const QuickSettingsBottomSheet(),
    );
  }
  
  /// Show profile quick actions
  static void showProfileQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const ProfileQuickActionsSheet(),
    );
  }
  
  // ==================== SIMPLIFIED SIGN OUT ====================
  
  /// Improved sign out flow with proper confirmation
  static void showSignOutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your data will be saved and available when you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performSignOut(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  
  static Future<void> _performSignOut(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Perform sign out logic here
      // This would typically involve calling auth service
      await Future.delayed(const Duration(seconds: 1)); // Simulate async operation
      
      // Navigate to auth screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ==================== CONTEXTUAL SHORTCUTS ====================
  
  /// Create contextual navigation based on current screen
  static List<Widget> getContextualActions(BuildContext context, String currentScreen) {
    switch (currentScreen) {
      case 'home':
        return [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showQuickSettings(context),
            tooltip: 'Quick Settings',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => showProfileQuickActions(context),
            tooltip: 'Profile',
          ),
        ];
      case 'history':
        return [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showHistoryFilters(context),
            tooltip: 'Filter History',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportOptions(context),
            tooltip: 'Export Data',
          ),
        ];
      case 'achievements':
        return [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showShareAchievements(context),
            tooltip: 'Share Progress',
          ),
        ];
      default:
        return [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => showQuickSettings(context),
            tooltip: 'Settings',
          ),
        ];
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  static void _showHistoryFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const HistoryFiltersSheet(),
    );
  }
  
  static void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ExportOptionsSheet(),
    );
  }
  
  static void _showShareAchievements(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ShareAchievementsSheet(),
    );
  }
}

// ==================== BOTTOM SHEET WIDGETS ====================

/// Quick settings bottom sheet for common toggles
class QuickSettingsBottomSheet extends StatefulWidget {
  const QuickSettingsBottomSheet({super.key});

  @override
  State<QuickSettingsBottomSheet> createState() => _QuickSettingsBottomSheetState();
}

class _QuickSettingsBottomSheetState extends State<QuickSettingsBottomSheet> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quick Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quick toggles
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Get reminded about daily challenges'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Easier on the eyes'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Audio feedback for actions'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          
          const Divider(),
          
          // Quick actions
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('All Settings'),
            subtitle: const Text('Access all app settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help or report issues'),
            onTap: () {
              Navigator.pop(context);
              SimplifiedNavigationService.navigateToHelpAndSupport(context);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Profile quick actions bottom sheet
class ProfileQuickActionsSheet extends StatelessWidget {
  const ProfileQuickActionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Profile actions
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your name and photo'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to edit profile
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('View Progress'),
            subtitle: const Text('See your environmental impact'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/achievements');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.account_box),
            title: const Text('Account Settings'),
            subtitle: const Text('Privacy, security, and account'),
            onTap: () {
              Navigator.pop(context);
              SimplifiedNavigationService.navigateToAccountSettings(context);
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Sign out of your account'),
            onTap: () {
              Navigator.pop(context);
              SimplifiedNavigationService.showSignOutConfirmation(context);
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==================== PLACEHOLDER SCREENS ====================

/// Placeholder for dedicated account settings screen
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: const Center(
        child: Text('Account Settings will be implemented here'),
      ),
    );
  }
}

/// Placeholder for app preferences screen
class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preferences'),
      ),
      body: const Center(
        child: Text('App Preferences will be implemented here'),
      ),
    );
  }
}

/// Placeholder for privacy settings screen
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: const Center(
        child: Text('Privacy Settings will be implemented here'),
      ),
    );
  }
}

/// Placeholder for help and support screen
class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: const Center(
        child: Text('Help & Support will be implemented here'),
      ),
    );
  }
}

/// Placeholder bottom sheets
class HistoryFiltersSheet extends StatelessWidget {
  const HistoryFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: const Center(
        child: Text('History Filters'),
      ),
    );
  }
}

class ExportOptionsSheet extends StatelessWidget {
  const ExportOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: const Center(
        child: Text('Export Options'),
      ),
    );
  }
}

class ShareAchievementsSheet extends StatelessWidget {
  const ShareAchievementsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: const Center(
        child: Text('Share Achievements'),
      ),
    );
  }
} 