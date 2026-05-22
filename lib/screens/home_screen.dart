import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/educational_content.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/points_manager.dart';
import '../providers/token_providers.dart';
import '../screens/achievements_screen.dart';
import '../screens/content_detail_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/history_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/instant_analysis_screen.dart';
import '../screens/waste_dashboard_screen.dart';
import '../utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import '../models/gamification_result.dart';
import '../widgets/modern_ui/modern_buttons.dart';
import '../widgets/enhanced_gamification_widgets.dart' as widgets;
import '../widgets/advanced_ui/achievement_celebration.dart';
import '../widgets/community_impact_card.dart';
import '../widgets/platform_camera.dart';
import '../utils/permission_handler.dart';

@visibleForTesting
int homeStreakCount(GamificationProfile? profile) {
  return profile
          ?.streaks[StreakType.dailyClassification.toString()]?.currentCount ??
      0;
}

@visibleForTesting
Challenge? selectHomeChallenge(
  List<Challenge> challenges,
  DateTime now,
) {
  final active = challenges.where((challenge) {
    return challenge.isActive && !challenge.isCompleted;
  }).toList();
  if (active.isEmpty) return null;
  return active[now.day % active.length];
}

@visibleForTesting
String? dailyTipPreferredCategory(List<WasteClassification> classifications) {
  if (classifications.isEmpty) return null;
  final sorted = List<WasteClassification>.from(classifications)
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final latest = sorted.first;
  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  if (latest.timestamp.isAfter(sevenDaysAgo)) {
    return latest.category;
  }
  return null;
}

/// Canonical app home screen entrypoint.
///
/// Consolidated from the former `ultra_modern_home_screen.dart` to eliminate
/// the wrapper indirection and provide a single source of truth for the home
/// UI.  All runtime code should depend on `HomeScreen`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.isGuestMode = false});

  final bool isGuestMode;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isNavigating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  /// Show points popup overlay on home screen after classification
  void _showPointsPopup(GamificationResult result) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 50,
        left: 0,
        right: 0,
        child: Center(
          child: widgets.PointsEarnedPopup(
            points: result.pointsEarned,
            action: result.action,
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    WasteAppLogger.userAction(
      'POPUP FIX: Showing points popup on home screen',
      context: {
        'points_earned': result.pointsEarned,
        'achievements_count': result.newlyEarnedAchievements.length,
        'action': result.action,
        'ui_element': 'points_popup_home_overlay',
      },
    );

    // Show achievement celebrations if any
    if (result.newlyEarnedAchievements.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _showAchievementCelebration(result.newlyEarnedAchievements.first);
        }
      });
    }
  }

  /// Show achievement celebration overlay
  void _showAchievementCelebration(Achievement achievement) {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AchievementCelebration(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    WasteAppLogger.userAction(
      'POPUP FIX: Showing achievement celebration on home screen',
      context: {
        'achievement_title': achievement.title,
        'achievement_id': achievement.id,
        'ui_element': 'achievement_popup_home_overlay',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final profileAsync = ref.watch(profileProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(classificationsProvider)
                  ..invalidate(profileProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // Hero header with gradient
                  _buildHeroHeader(context, profileAsync, userProfileAsync),

                  // Content sections
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Mission control panel
                        _buildMissionControlPanel(
                          context,
                          profileAsync,
                          userProfileAsync,
                        ),
                        const SizedBox(height: 20),

                        // Daily progress habit loop
                        _buildDailyProgressCard(
                          context,
                          profileAsync,
                        ),
                        const SizedBox(height: 20),

                        // Horizontal scrolling action chips
                        _buildActionChips(context),
                        const SizedBox(height: 20),

                        // Near milestone nudge
                        _buildNudgeSection(context),
                        const SizedBox(height: 20),

                        // Community impact
                        _buildCommunityImpactCard(
                          context,
                          classificationsAsync,
                        ),
                        const SizedBox(height: 20),

                        // Content with padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Active Challenge section
                              _buildActiveChallengeSection(
                                context,
                                profileAsync,
                              ),
                              const SizedBox(height: 32),

                              // Daily sorting tip card
                              _buildDailyTipCard(context, classificationsAsync),
                              const SizedBox(height: 32),

                              // Recent Classifications
                              _buildRecentClassifications(
                                context,
                                classificationsAsync,
                              ),

                              // Bottom padding for navigation
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Hero header
  // ==========================================================================

  Widget _buildHeroHeader(
    BuildContext context,
    AsyncValue<GamificationProfile?> profileAsync,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    final hour = DateTime.now().hour;
    final timePhase = _getTimePhase(hour);
    final greeting = _getPersonalizedGreeting(timePhase);
    final gradientColors = _getTimeBasedGradient(hour);

    final topPadding = MediaQuery.of(context).padding.top;

    return SliverAppBar(
      expandedHeight: topPadding + 220,
      toolbarHeight: 52,
      pinned: true,
      backgroundColor: gradientColors.first,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            key: const Key('home_settings_button'),
            tooltip: 'Open settings',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting and user info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          userProfileAsync.when(
                            data: (userProfile) {
                              final firstName =
                                  userProfile?.displayName?.split(' ').first ??
                                      AppStrings.ecoHero;
                              return Text(
                                '$greeting, $firstName!',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            loading: () => Text(
                              '$greeting, ${AppStrings.ecoHero}!',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            error: (_, __) => Text(
                              '$greeting, ${AppStrings.ecoHero}!',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMotivationalMessage(timePhase),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats chips with impact info
                Row(
                  children: [
                    Expanded(child: _buildPointsChip(context)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTokensChip(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: profileAsync.when(
                        data: (profile) => _buildStatChip(
                          '${homeStreakCount(profile)}',
                          AppStrings.streak,
                          Icons.local_fire_department,
                        ),
                        loading: () => _buildStatChip(
                          '...',
                          AppStrings.streak,
                          Icons.local_fire_department,
                        ),
                        error: (_, __) => _buildStatChip(
                          '0',
                          AppStrings.streak,
                          Icons.local_fire_department,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDaysActiveChip(context)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsChip(BuildContext context) {
    final pointsAsync = ref.watch(pointsManagerProvider);

    return pointsAsync.when(
      data: (points) =>
          _buildStatChip('${points.total}', AppStrings.points, Icons.stars),
      loading: () => _buildStatChip('...', AppStrings.points, Icons.stars),
      error: (_, __) => _buildStatChip('0', AppStrings.points, Icons.stars),
    );
  }

  Widget _buildTokensChip(BuildContext context) {
    final walletAsync = ref.watch(tokenWalletProvider);

    return walletAsync.when(
      data: (wallet) =>
          _buildStatChip('${wallet?.balance ?? 0}', 'Tokens', Icons.bolt),
      loading: () => _buildStatChip('...', 'Tokens', Icons.bolt),
      error: (_, __) => _buildStatChip('0', 'Tokens', Icons.bolt),
    );
  }

  Widget _buildDaysActiveChip(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return classificationsAsync.when(
      data: (classifications) {
        return userProfileAsync.when(
          data: (userProfile) {
            final uniqueActivityDays = <String>{};
            for (final classification in classifications) {
              final dateKey =
                  '${classification.timestamp.year}-${classification.timestamp.month}-${classification.timestamp.day}';
              uniqueActivityDays.add(dateKey);
            }

            int daysActive;
            if (uniqueActivityDays.isNotEmpty) {
              daysActive = uniqueActivityDays.length;
            } else if (userProfile?.createdAt != null) {
              daysActive =
                  DateTime.now().difference(userProfile!.createdAt!).inDays + 1;
            } else {
              daysActive = 1;
            }

            return _buildStatChip('$daysActive', 'Days', Icons.eco);
          },
          loading: () => _buildStatChip('...', 'Days', Icons.eco),
          error: (_, __) => _buildStatChip('1', 'Days', Icons.eco),
        );
      },
      loading: () => _buildStatChip('...', 'Days', Icons.eco),
      error: (_, __) => _buildStatChip('1', 'Days', Icons.eco),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeRegular,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Mission control panel
  // ==========================================================================

  Widget _buildMissionControlPanel(
    BuildContext context,
    AsyncValue<GamificationProfile?> profileAsync,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0E8F69),
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
            stops: [0, 0.52, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF087D68).withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -48,
              child: Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB9F26D).withValues(alpha: 0.12),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB9F26D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF075A45),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to sort?',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scan, learn, and keep your streak alive.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.25,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        key: const Key('home_mission_scan_button'),
                        text: 'Scan',
                        icon: Icons.camera_alt,
                        onPressed: _takePhoto,
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        tooltip: 'Open camera capture',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModernButton(
                        key: const Key('home_mission_learn_button'),
                        text: 'Learn',
                        icon: Icons.school_outlined,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EducationalContentScreen(
                                showBottomAd: false,
                              ),
                            ),
                          );
                        },
                        backgroundColor:
                            const Color(0xFF075A45).withValues(alpha: 0.72),
                        foregroundColor: Colors.white,
                        tooltip: 'Open learning hub',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildMissionMetric(
                        context,
                        'Today',
                        'Fresh tips',
                        Icons.auto_awesome,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: profileAsync.when(
                        data: (profile) => _buildMissionMetric(
                          context,
                          'Streak',
                          '${homeStreakCount(profile)} days',
                          Icons.local_fire_department,
                        ),
                        loading: () => _buildMissionMetric(
                          context,
                          'Streak',
                          'Loading',
                          Icons.local_fire_department,
                        ),
                        error: (_, __) => _buildMissionMetric(
                          context,
                          'Streak',
                          '0 days',
                          Icons.local_fire_department,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: userProfileAsync.when(
                        data: (userProfile) => _buildMissionMetric(
                          context,
                          'You',
                          userProfile?.displayName?.split(' ').first ??
                              AppStrings.ecoHero,
                          Icons.person,
                        ),
                        loading: () => _buildMissionMetric(
                          context,
                          'You',
                          '...',
                          Icons.person,
                        ),
                        error: (_, __) => _buildMissionMetric(
                          context,
                          'You',
                          AppStrings.ecoHero,
                          Icons.person,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFB9F26D), size: 17),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.78),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Action chips
  // ==========================================================================

  Widget _buildActionChips(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _getActionItems().length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = _getActionItems()[index];
          return _buildActionCard(action);
        },
      ),
    );
  }

  List<ActionItem> _getActionItems() {
    return [
      ActionItem(
        key: const Key('home_action_take_photo'),
        title: AppStrings.takePhoto,
        subtitle: AppStrings.reviewAnalyze,
        icon: Icons.camera_alt,
        color: const Color(0xFF2196F3),
        onTap: () => _takePhoto(),
      ),
      ActionItem(
        key: const Key('home_action_upload_image'),
        title: AppStrings.uploadImage,
        subtitle: AppStrings.fromGallery,
        icon: Icons.photo_library,
        color: const Color(0xFF4CAF50),
        onTap: () => _pickImage(),
      ),
      ActionItem(
        key: const Key('home_action_instant_camera'),
        title: AppStrings.instantCamera,
        subtitle: AppStrings.autoAnalyze,
        icon: Icons.flash_on,
        color: const Color(0xFFFF9800),
        onTap: () => _takePhotoInstant(),
      ),
      ActionItem(
        key: const Key('home_action_instant_upload'),
        title: AppStrings.instantUpload,
        subtitle: AppStrings.autoAnalyze,
        icon: Icons.bolt,
        color: const Color(0xFF9C27B0),
        onTap: () => _pickImageInstant(),
      ),
    ];
  }

  Widget _buildActionCard(ActionItem action) {
    return Material(
      key: action.key,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.32,
          constraints: const BoxConstraints(minHeight: 96, minWidth: 96),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                action.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                action.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // Daily progress / nudge / community
  // ==========================================================================

  Widget _buildDailyProgressCard(
    BuildContext context,
    AsyncValue<GamificationProfile?> profileAsync,
  ) {
    final todayGoalAsync = ref.watch(todayGoalProvider);
    return todayGoalAsync.when(
      data: (goalData) {
        final scansToday = goalData.$1;
        final dailyGoal = goalData.$2 <= 0 ? 1 : goalData.$2;
        final progress = (scansToday / dailyGoal).clamp(0.0, 1.0);

        return profileAsync.when(
          data: (profile) {
            final streakDays = homeStreakCount(profile);
            final totalPoints = profile?.points.total ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                key: const Key('home_daily_progress_card'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.dailyProgress,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$scansToday/$dailyGoal scans today',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '$streakDays day streak · $totalPoints pts',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(6),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNudgeSection(BuildContext context) {
    final gamificationService = ref.watch(gamificationServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<NearMilestoneNudge?>(
      future: gamificationService.getNearMilestoneNudge(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final nudge = snapshot.data!;
        final nudgeColor = _nudgeColor(nudge.type, colorScheme);
        final progressValue = nudge.target > 0
            ? (nudge.progress / nudge.target).clamp(0.0, 1.0)
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            key: const Key('home_near_milestone_card'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    nudgeColor.withValues(alpha: 0.12),
                    nudgeColor.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nudgeColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(_nudgeIcon(nudge.iconName), color: nudgeColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nudge.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nudge.message,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: nudgeColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(nudgeColor),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _nudgeIcon(String? iconName) {
    switch (iconName) {
      case 'flag':
        return Icons.flag;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'stars':
        return Icons.stars;
      case 'category':
        return Icons.category;
      default:
        return Icons.near_me;
    }
  }

  Color _nudgeColor(NudgeType type, ColorScheme colorScheme) {
    switch (type) {
      case NudgeType.dailyGoal:
        return const Color(0xFF2196F3);
      case NudgeType.challengeNearComplete:
        return const Color(0xFFFF9800);
      case NudgeType.categoryAchievement:
        return const Color(0xFF4CAF50);
      case NudgeType.streakMilestone:
        return const Color(0xFFFF5722);
    }
  }

  Widget _buildCommunityImpactCard(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    return classificationsAsync.when(
      data: (classifications) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CommunityImpactCard(
          key: const Key('home_community_impact_card'),
          classifications: classifications,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WasteDashboardScreen(),
            ),
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ==========================================================================
  // Active Challenge section
  // ==========================================================================

  Widget _buildActiveChallengeSection(
    BuildContext context,
    AsyncValue<GamificationProfile?> profileAsync,
  ) {
    return profileAsync.when(
      data: (profile) {
        if (profile?.activeChallenges == null ||
            profile!.activeChallenges.isEmpty) {
          return const SizedBox.shrink();
        }

        final selected =
            selectHomeChallenge(profile.activeChallenges, DateTime.now());
        if (selected == null) {
          return const SizedBox.shrink();
        }

        final targetCount =
            int.tryParse('${selected.requirements['count'] ?? 1}') ?? 1;
        final safeTargetCount = targetCount <= 0 ? 1 : targetCount;
        final normalizedProgress = selected.progress.clamp(0.0, 1.0);
        final progressPercentage = (normalizedProgress * 100).round();
        final currentCount = (normalizedProgress * safeTargetCount).round();

        return GestureDetector(
          key: const Key('home_active_challenge_card'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AchievementsScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  selected.color.withValues(alpha: 0.1),
                  selected.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected.color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getChallengeIcon(selected.iconName),
                        color: selected.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            selected.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$progressPercentage%',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selected.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: normalizedProgress,
                        backgroundColor: selected.color.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          selected.color,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentCount/$safeTargetCount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  IconData _getChallengeIcon(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'recycling':
        return Icons.recycling;
      case 'compost':
        return Icons.eco;
      case 'warning':
        return Icons.warning;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.star;
    }
  }

  // ==========================================================================
  // Daily Tip Card
  // ==========================================================================

  Widget _buildDailyTipCard(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    final theme = Theme.of(context);

    return classificationsAsync.when(
      data: (classifications) {
        final educationalService = ref.read(educationalContentServiceProvider);

        final preferredCategory = dailyTipPreferredCategory(classifications);

        final tip = educationalService.getDailyTipForHome(
          preferredCategory: preferredCategory,
        );

        return GestureDetector(
          key: const Key('home_daily_tip_card'),
          onTap: () => _openDailyTip(context, tip),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Today's sorting tip",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(tip.category)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tip.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(tip.category),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tip.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tip.actionText ?? AppStrings.learnMore,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => _buildTipFallbackCard(context, isLoading: true),
      error: (_, __) => _buildTipFallbackCard(context),
    );
  }

  Widget _buildTipFallbackCard(
    BuildContext context, {
    bool isLoading = false,
  }) {
    final tip = DailyTip(
      id: 'fallback',
      title: 'Quick tip',
      content: isLoading
          ? 'Loading today\'s tip...'
          : 'Sort clean, dry items to improve recycling quality.',
      category: 'General',
      date: DateTime.now(),
      actionText: AppStrings.learnMore,
    );

    return GestureDetector(
      key: const Key('home_daily_tip_card'),
      onTap: () => _openDailyTip(context, tip),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isLoading ? Icons.hourglass_bottom : Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tip.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDailyTip(BuildContext context, DailyTip tip) {
    if (tip.contentId != null && tip.contentId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ContentDetailScreen(contentId: tip.contentId!),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EducationalContentScreen(
            initialCategory: tip.category,
            showBottomAd: false,
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // Recent Classifications
  // ==========================================================================

  Widget _buildRecentClassifications(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    return classificationsAsync.when(
      data: (classifications) {
        if (classifications.isEmpty) {
          return _buildEmptyState(context);
        }

        final sorted = List<WasteClassification>.from(classifications)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final recent = sorted.take(3).toList();
        return Column(
          key: const Key('home_recent_section'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.recentClassifications,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('home_recent_view_all'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  ),
                  child: const Text(AppStrings.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recent.map(
              (classification) => _buildClassificationCard(classification),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildRecentErrorState(context),
    );
  }

  Widget _buildClassificationCard(WasteClassification classification) {
    return GestureDetector(
      key: Key('home_classification_card_${classification.id}'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HistoryScreen(),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor(
                  classification.category,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(classification.category),
                color: _getCategoryColor(classification.category),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classification.itemName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    classification.category,
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${((classification.confidence ?? 0.0) * 100).round()}%',
                style: GoogleFonts.inter(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentErrorState(BuildContext context) {
    return GestureDetector(
      key: const Key('home_recent_error_state'),
      onTap: () => ref.invalidate(classificationsProvider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.tapToRetry,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      key: const Key('home_empty_state'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.startYourJourney,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.takeFirstPhoto,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take first photo'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Upload image'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Helpers
  // ==========================================================================

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
      case 'organic':
        return const Color(0xFF4CAF50);
      case 'dry waste':
      case 'recyclable':
        return const Color(0xFF2196F3);
      case 'hazardous waste':
      case 'hazardous':
        return const Color(0xFFF44336);
      case 'medical waste':
        return const Color(0xFF845EC2);
      case 'general':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
      case 'organic':
        return Icons.compost;
      case 'dry waste':
      case 'recyclable':
        return Icons.recycling;
      case 'hazardous waste':
      case 'hazardous':
        return Icons.warning;
      case 'medical waste':
        return Icons.local_hospital;
      default:
        return Icons.delete;
    }
  }

  // ==========================================================================
  // Photo capture methods
  // ==========================================================================

  Future<void> _takePhoto() async {
    await _pickAndRouteImage(source: ImageSource.camera, instant: false);
  }

  Future<void> _pickImage() async {
    await _pickAndRouteImage(source: ImageSource.gallery, instant: false);
  }

  Future<void> _takePhotoInstant() async {
    await _pickAndRouteImage(source: ImageSource.camera, instant: true);
  }

  Future<void> _pickImageInstant() async {
    await _pickAndRouteImage(source: ImageSource.gallery, instant: true);
  }

  Future<void> _pickAndRouteImage({
    required ImageSource source,
    required bool instant,
  }) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      XFile? image;
      if (source == ImageSource.camera && !kIsWeb) {
        final hasPermission = await PermissionHandler.checkCameraPermission();
        if (!hasPermission && mounted) {
          PermissionHandler.showPermissionDeniedDialog(context, 'Camera');
          return;
        }
      }

      if (source == ImageSource.camera && !kIsWeb) {
        final setupSuccess = await PlatformCamera.setup();
        if (setupSuccess) {
          image = await PlatformCamera.takePicture();
        }
      }

      image ??= await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        if (instant) {
          await _navigateToInstantAnalysis(image);
        } else {
          await _navigateToImageCapture(image);
        }
      }
    } catch (e) {
      final message = source == ImageSource.camera
          ? AppStrings.errorTakingPhoto
          : AppStrings.errorPickingImage;
      WasteAppLogger.severe('$message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$message: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _navigateToImageCapture(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        final result = await Navigator.push<GamificationResult>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ImageCaptureScreen(xFile: image, webImage: bytes),
          ),
        );

        // Show popup if gamification results are returned
        if (result != null && result.hasRewards && mounted) {
          _showPointsPopup(result);
        }
      }
    } else {
      final file = File(image.path);
      if (await file.exists() && mounted) {
        final result = await Navigator.push<GamificationResult>(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen(imageFile: file),
          ),
        );

        // Show popup if gamification results are returned
        if (result != null && result.hasRewards && mounted) {
          _showPointsPopup(result);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image file was not found.')),
        );
      }
    }
  }

  Future<void> _navigateToInstantAnalysis(XFile image) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstantAnalysisScreen(image: image),
      ),
    );
  }

  // ==========================================================================
  // Time-based personalization helpers
  // ==========================================================================

  String _getTimePhase(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _getPersonalizedGreeting(String phase) {
    switch (phase) {
      case 'morning':
        return AppStrings.goodMorning;
      case 'afternoon':
        return AppStrings.goodAfternoon;
      case 'evening':
        return AppStrings.goodEvening;
      case 'night':
        return AppStrings.goodEvening;
      default:
        return 'Welcome back';
    }
  }

  String _getMotivationalMessage(String phase) {
    switch (phase) {
      case 'morning':
        return AppStrings.keepGoingChampion;
      case 'afternoon':
        return AppStrings.energyToday;
      case 'evening':
        return AppStrings.excellentProgress;
      case 'night':
        return AppStrings.nightOwlEco;
      default:
        return AppStrings.makingDifference;
    }
  }

  List<Color> _getTimeBasedGradient(int hour) {
    if (hour >= 5 && hour < 12) {
      return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
    } else if (hour >= 12 && hour < 17) {
      return [const Color(0xFF43A047), const Color(0xFF66BB6A)];
    } else if (hour >= 17 && hour < 21) {
      return [const Color(0xFF388E3C), const Color(0xFF689F38)];
    } else {
      return [const Color(0xFF2E7D32), const Color(0xFF388E3C)];
    }
  }
}

class ActionItem {
  ActionItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final Key key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
