import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/points_manager.dart';
import '../providers/token_providers.dart';
import '../screens/history_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/instant_analysis_screen.dart';
import '../screens/educational_content_screen.dart';
import '../screens/content_detail_screen.dart';
import '../screens/waste_dashboard_screen.dart';
import '../utils/constants.dart';
import '../utils/waste_theme.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import '../models/gamification_result.dart';
import '../models/educational_content.dart';
import '../widgets/enhanced_gamification_widgets.dart' as widgets;
import '../widgets/advanced_ui/achievement_celebration.dart';
import '../widgets/community_impact_card.dart';


/// Deprecated compatibility screen.
///
/// Canonical home surface is `HomeScreen` in lib/screens/home_screen.dart.
/// Keep this only for backward compatibility until routed references are
/// fully removed.
@Deprecated(
  'Use HomeScreen (lib/screens/home_screen.dart). UltraModernHomeScreen is '
  'kept only as a compatibility surface and is not canonical.',
)
class UltraModernHomeScreen extends ConsumerStatefulWidget {
  const UltraModernHomeScreen({super.key, this.isGuestMode = false});

  final bool isGuestMode;

  @override
  ConsumerState<UltraModernHomeScreen> createState() =>
      _UltraModernHomeScreenState();
}

class _UltraModernHomeScreenState extends ConsumerState<UltraModernHomeScreen>
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
    WasteAppLogger.warning(
      'UltraModernHomeScreen is deprecated and non-canonical. Prefer HomeScreen.',
      context: {
        'screen': 'UltraModernHomeScreen',
        'canonical_screen': 'HomeScreen',
      },
    );
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
      '🎯 POPUP FIX: Showing points popup on home screen',
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
      '🎯 POPUP FIX: Showing achievement celebration on home screen',
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
                ref.invalidate(classificationsProvider);
                ref.invalidate(profileProvider);
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

                        // Primary scan CTA
                        _buildPrimaryScanCTA(context),
                        const SizedBox(height: 20),

                        // Daily progress card
                        _buildDailyProgressCard(
                            context, classificationsAsync, profileAsync),
                        const SizedBox(height: 20),

                        // Near-milestone nudge (one at a time, anti-spam)
                        _buildNudgeSection(context),

                        // Community Impact Card (local stats, empty-state CTA)
                        _buildCommunityImpactCard(
                            context, classificationsAsync),

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

                              // Daily Tip
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

  Widget _buildHeroHeader(
    BuildContext context,
    AsyncValue<GamificationProfile?> profileAsync,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    final hour = DateTime.now().hour;
    final timePhase = _getTimePhase(hour);
    final greeting = _getPersonalizedGreeting(timePhase);
    final gradientColors = _getTimeBasedGradient(hour);

    return SliverAppBar(
      expandedHeight: 220,
      toolbarHeight: 0,
      pinned: true,
      backgroundColor: Colors.transparent,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                                maxLines: 1,
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
                              maxLines: 1,
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
                              maxLines: 1,
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
                    const SizedBox(width: 12),
                    // Time-aware animated icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTimeBasedIcon(timePhase),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats chips with impact info
                Row(
                  children: [
                    Flexible(child: _buildPointsChip(context)),
                    const SizedBox(width: 8),
                    Flexible(child: _buildTokensChip(context)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: profileAsync.when(
                        data: (profile) => _buildStatChip(
                          '${profile?.streaks[StreakType.dailyClassification.toString()]?.currentCount ?? 0}',
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
                    Flexible(child: _buildDaysActiveChip(context)),
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
            // Calculate unique days with activity (classifications)
            final uniqueActivityDays = <String>{};
            for (final classification in classifications) {
              final dateKey =
                  '${classification.timestamp.year}-${classification.timestamp.month}-${classification.timestamp.day}';
              uniqueActivityDays.add(dateKey);
            }

            // If user has activity days, use that count
            // Otherwise, fall back to days since account creation (logged-in days)
            int daysActive;
            if (uniqueActivityDays.isNotEmpty) {
              daysActive = uniqueActivityDays.length;
            } else if (userProfile?.createdAt != null) {
              daysActive =
                  DateTime.now().difference(userProfile!.createdAt!).inDays + 1;
            } else {
              daysActive = 1;
            }

            return _buildStatChip('$daysActive', 'Days Active', Icons.eco);
          },
          loading: () => _buildStatChip('...', 'Days Active', Icons.eco),
          error: (_, __) => _buildStatChip('1', 'Days Active', Icons.eco),
        );
      },
      loading: () => _buildStatChip('...', 'Days Active', Icons.eco),
      error: (_, __) => _buildStatChip('1', 'Days Active', Icons.eco),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Flexible(
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
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryScanCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main scan button
          FilledButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt, size: 28),
            label: Text(
              AppStrings.scanWaste,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary actions row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.openGallery,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _takePhotoInstant,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.instantMode,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
    AsyncValue<GamificationProfile?> profileAsync,
  ) {
    return classificationsAsync.when(
      data: (classifications) {
        final today = DateTime.now();
        final todayClassifications = classifications.where((c) {
          return c.timestamp.year == today.year &&
              c.timestamp.month == today.month &&
              c.timestamp.day == today.day;
        }).toList();

        final scansToday = todayClassifications.length;
        const dailyGoal = 10;
        final progress = (scansToday / dailyGoal).clamp(0.0, 1.0);

        return profileAsync.when(
          data: (profile) {
            final totalPoints = profile?.points.total ?? 0;
            final streakDays = profile
                    ?.streaks[StreakType.dailyClassification.toString()]
                    ?.currentCount ??
                0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AchievementsScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.dailyProgress,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$scansToday / $dailyGoal',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  AppStrings.scansToday,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        size: 20, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$streakDays',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.emoji_events,
                                        size: 20, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalPoints',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.loadingYourData,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: () {
            ref.invalidate(classificationsProvider);
            ref.invalidate(profileProvider);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.errorLoadingData,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Text(
                        AppStrings.tapToRetry,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer
                              .withValues(alpha: 0.7),
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
    );
  }

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

        // Find active challenges with progress > 0
        final activeChallenges = profile.activeChallenges.where((challenge) {
          return challenge.isActive &&
              !challenge.isCompleted &&
              challenge.progress > 0;
        }).toList();

        if (activeChallenges.isEmpty) {
          return const SizedBox.shrink();
        }

        // Pick a random active challenge based on day
        final randomChallenge =
            activeChallenges[DateTime.now().day % activeChallenges.length];
        final progressPercentage = (randomChallenge.progress * 100).round();
        final currentCount = (randomChallenge.progress *
                (randomChallenge.requirements['count'] ?? 1))
            .round();
        final targetCount = randomChallenge.requirements['count'] ?? 1;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AchievementsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  randomChallenge.color.withValues(alpha: 0.1),
                  randomChallenge.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: randomChallenge.color.withValues(alpha: 0.3),
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
                        color: randomChallenge.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getChallengeIcon(randomChallenge.iconName),
                        color: randomChallenge.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            randomChallenge.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            randomChallenge.description,
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
                        color: randomChallenge.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: randomChallenge.progress,
                        backgroundColor: randomChallenge.color.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          randomChallenge.color,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentCount/$targetCount',
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

  Widget _buildDailyTipCard(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    final educationalService = ref.read(educationalContentServiceProvider);

    String? preferredCategory;
    classificationsAsync.whenData((classifications) {
      if (classifications.isNotEmpty) {
        final recent = classifications.first;
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        if (recent.timestamp.isAfter(sevenDaysAgo)) {
          preferredCategory = recent.category;
        }
      }
    });

    final tip = educationalService.getDailyTipForHome(
      preferredCategory: preferredCategory,
    );

    final categoryColor = _getCategoryColor(tip.category);
    final categoryIcon = _getCategoryIcon(tip.category);

    return GestureDetector(
      onTap: () => _openDailyTip(context, tip),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.1),
              categoryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcon,
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Sorting Tip",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: categoryColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tip.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tip.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openDailyTip(BuildContext context, DailyTip tip) {
    final educationalService = ref.read(educationalContentServiceProvider);
    if (tip.contentId != null && tip.contentId!.isNotEmpty) {
      final content = educationalService.getContentById(tip.contentId!);
      if (content != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContentDetailScreen(contentId: content.id),
          ),
        );
        return;
      }
    }
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

  Widget _buildRecentClassifications(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    return classificationsAsync.when(
      data: (classifications) {
        if (classifications.isEmpty) {
          return _buildEmptyState(context);
        }

        final mostRecent = classifications.first;
        final recent = classifications.skip(1).take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Continue where you left off card
            _buildContinueCard(context, mostRecent),
            const SizedBox(height: 24),

            // Recent classifications section
            if (recent.isNotEmpty) ...[
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
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              AppStrings.loadingYourData,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      error: (error, _) => GestureDetector(
        onTap: () {
          ref.invalidate(classificationsProvider);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.errorLoadingData,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      AppStrings.tapToRetry,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueCard(
      BuildContext context, WasteClassification classification) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HistoryScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.continueWhereYouLeftOff,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(classification.category)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(classification.category),
                    color: _getCategoryColor(classification.category),
                    size: 32,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classification.category,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.viewHistory,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context)
                    .colorScheme
                    .onSecondaryContainer
                    .withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(WasteClassification classification) {
    return Container(
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
    );
  }

  /// Builds the "Almost there" nudge card when a near-milestone exists.
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: nudgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _nudgeIcon(nudge.iconName),
                      color: nudgeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nudge.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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
                          value: nudge.target > 0
                              ? nudge.progress / nudge.target
                              : 0,
                          backgroundColor: nudgeColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(nudgeColor),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) =>
      WasteTheme.categoryColor(category);

  IconData _getCategoryIcon(String category) =>
      WasteTheme.categoryIcon(category);

  // Photo capture methods
  Future<void> _takePhoto() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      WasteAppLogger.severe('${AppStrings.errorTakingPhoto}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorTakingPhoto}: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _pickImage() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      WasteAppLogger.severe('${AppStrings.errorPickingImage}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPickingImage}: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _takePhotoInstant() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null && mounted) {
        await _navigateToInstantAnalysis(image);
      }
    } catch (e) {
      WasteAppLogger.severe('${AppStrings.errorTakingPhoto}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorTakingPhoto}: $e')),
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
      }
    }
  }

  Future<void> _navigateToInstantAnalysis(XFile image) async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InstantAnalysisScreen(image: image),
        ),
      );
    }
  }

  // Time-based personalization helper methods
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
      // Morning: Fresh green with golden sunrise
      return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: Bright eco green
      return [const Color(0xFF43A047), const Color(0xFF66BB6A)];
    } else if (hour >= 17 && hour < 21) {
      // Evening: Warm green with orange sunset
      return [const Color(0xFF388E3C), const Color(0xFF689F38)];
    } else {
      // Night: Deep green with blue tones
      return [const Color(0xFF2E7D32), const Color(0xFF388E3C)];
    }
  }

  IconData _getTimeBasedIcon(String phase) {
    switch (phase) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.eco;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nights_stay;
      default:
        return Icons.eco;
    }
  }
}

class ActionItem {
  ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
