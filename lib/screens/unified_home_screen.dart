import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/points_manager.dart';
import '../providers/token_providers.dart';
import '../screens/history_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/instant_analysis_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/constants.dart';
import '../utils/service_locator.dart';
import '../utils/error_handler.dart';
import '../utils/waste_app_logger.dart';
import '../models/gamification_result.dart';
import '../widgets/enhanced_gamification_widgets.dart' as widgets;
import '../widgets/advanced_ui/achievement_celebration.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/capture_button.dart';
import '../widgets/gamification_widgets.dart';

/// Unified home screen that consolidates all home screen implementations
class UnifiedHomeScreen extends ConsumerStatefulWidget {
  const UnifiedHomeScreen({
    super.key,
    this.isGuestMode = false,
  });

  final bool isGuestMode;

  @override
  ConsumerState<UnifiedHomeScreen> createState() => _UnifiedHomeScreenState();
}

class _UnifiedHomeScreenState extends ConsumerState<UnifiedHomeScreen> 
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isNavigating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Cached data
  GamificationProfile? _gamificationProfile;
  UserProfile? _userProfile;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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

  Future<void> _loadUserData() async {
    final services = ServiceLocator.getServiceBundle(context);
    
    await ErrorHandler.handleAsync(
      () async {
        // Load user profile
        _userProfile = await services.storage.getCurrentUserProfile();
        if (_userProfile != null) {
          _userName = _userProfile!.displayName ?? _userProfile!.email ?? 'User';
        }

        // Load gamification profile
        _gamificationProfile = await services.gamification.getProfile();

        if (mounted) {
          setState(() {});
        }
      },
      context: 'Loading user data',
      service: 'home_screen',
      file: 'unified_home_screen',
    );
  }

  Future<void> _signOut() async {
    final services = ServiceLocator.getServiceBundle(context);
    
    final success = await ErrorHandler.handleAsyncVoid(
      () async {
        await services.googleDrive.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      },
      context: 'Sign out',
      service: 'home_screen',
      file: 'unified_home_screen',
      showSnackBar: true,
      buildContext: context,
      userMessage: 'Failed to sign out. Please try again.',
    );

    if (success) {
      ErrorHandler.showSuccessMessage(context, 'Signed out successfully');
    }
  }

  Future<void> _captureImage() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen.fromXFile(image),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorDialog(
          context,
          title: 'Camera Error',
          message: 'Unable to access camera. Please check permissions.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen.fromXFile(image),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorDialog(
          context,
          title: 'Gallery Error',
          message: 'Unable to access gallery. Please check permissions.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceLocator.getServiceBundle(context);
    
    // Set ad context
    services.ad.setInClassificationFlow(false);
    services.ad.setInEducationalContent(false);
    services.ad.setInSettings(false);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        AppStrings.appName,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      actions: [
        // Points indicator
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
                      builder: (context) => const AchievementsScreen(initialTabIndex: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        
        // Achievements button
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
          tooltip: 'Achievements',
        ),
        
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          tooltip: 'Settings',
        ),
        
        // Sign out button (only for authenticated users)
        if (!widget.isGuestMode)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(context),
                  const SizedBox(height: 24),
                  _buildStatsSection(context),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(context),
                  const SizedBox(height: 80), // Space for FAB and ads
                ],
              ),
            ),
          ),
        ),
        
        // Banner ad at the bottom
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BannerAdWidget(showAtBottom: true),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $_userName!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to make a difference today?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Capture waste item',
                onTap: _captureImage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.photo_library,
                title: 'From Gallery',
                subtitle: 'Select existing photo',
                onTap: _pickFromGallery,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.history,
                title: 'History',
                subtitle: 'View past classifications',
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
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.flash_on,
                title: 'Instant Analysis',
                subtitle: 'Quick classification',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InstantAnalysisScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    if (_gamificationProfile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Stats',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Points', _gamificationProfile!.points.total.toString()),
                _buildStatItem('Classifications', _gamificationProfile!.achievements.length.toString()),
                _buildStatItem('Streak', _gamificationProfile!.streaks.values.isNotEmpty 
                    ? _gamificationProfile!.streaks.values.first.current.toString() 
                    : '0'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final classificationsAsync = ref.watch(classificationsProvider);
        
        return classificationsAsync.when(
          data: (classifications) {
            final recentClassifications = classifications.take(3).toList();
            
            if (recentClassifications.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...recentClassifications.map((classification) => 
                  _buildRecentActivityItem(context, classification)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildRecentActivityItem(BuildContext context, WasteClassification classification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.recycling,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          classification.itemName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          classification.category,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Text(
          '${classification.pointsAwarded ?? 0} pts',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isNavigating ? null : _captureImage,
      icon: _isNavigating 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt),
      label: Text(
        _isNavigating ? 'Opening...' : 'Classify Waste',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}

// Providers for the unified home screen
final profileProvider = FutureProvider<GamificationProfile?>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  try {
    return await gamificationService.getProfile();
  } catch (e) {
    WasteAppLogger.severe('Error loading profile: $e');
    return null;
  }
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  try {
    return await storageService.getCurrentUserProfile();
  } catch (e) {
    WasteAppLogger.severe('Error loading user profile: $e');
    return null;
  }
});

final classificationsProvider = FutureProvider<List<WasteClassification>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAllClassifications();
});