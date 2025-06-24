import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/token_providers.dart';

/// Lean, personalized home header with micro-interactions
/// Replaces the verbose welcome section with essential data chips only
class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  HomeHeaderState createState() => HomeHeaderState();
}

class HomeHeaderState extends ConsumerState<HomeHeader> with SingleTickerProviderStateMixin {
  int? _prevPts;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final todayGoalAsync = ref.watch(todayGoalProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);

    return profileAsync.when(
      data: (profile) => _buildHeader(context, profile, userProfileAsync, todayGoalAsync, unreadAsync),
      loading: () => _buildLoadingHeader(context),
      error: (_, __) => _buildErrorHeader(context),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    GamificationProfile? profile,
    AsyncValue<UserProfile?> userProfileAsync,
    AsyncValue<(int, int)> todayGoalAsync,
    AsyncValue<int> unreadAsync,
  ) {
    final pts = profile?.points.total ?? 0;
    final unread = unreadAsync.valueOrNull ?? 0;
    final (done, total) = todayGoalAsync.valueOrNull ?? (0, 10);
    final userProfile = userProfileAsync.valueOrNull;

    // Get token wallet for token display
    final tokenWalletAsync = ref.watch(tokenWalletProvider);

    // Points pulse trigger
    if (_prevPts != null && pts > _prevPts!) {
      _pulse.forward(from: 0);
    }
    _prevPts = pts;

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: avatar + greeting + points + bell (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isVerySmallScreen = constraints.maxWidth < 300;

                  return Row(
                    children: [
                      Semantics(
                        label: 'User avatar for ${userProfile?.displayName ?? 'User'}',
                        child: CircleAvatar(
                          radius: isVerySmallScreen ? 20 : 28,
                          child: _buildAvatar(userProfile),
                        ),
                      ),
                      SizedBox(width: isVerySmallScreen ? 8 : 16),
                      Expanded(
                        flex: 3,
                        child: _buildGreeting(context, userProfile),
                      ),
                      if (!isVerySmallScreen) ...[
                        Semantics(
                          label: 'Current points: $pts',
                          child: _PointsPill(points: pts, pulse: _pulse),
                        ),
                        const SizedBox(width: 8),
                        // Token display
                        tokenWalletAsync.when(
                          data: (wallet) => Semantics(
                            label: 'AI tokens: ${wallet?.balance ?? 0}',
                            child: _TokenPill(tokens: wallet?.balance ?? 0),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Semantics(
                        label: unread > 0 ? '$unread unread notifications' : 'No unread notifications',
                        button: true,
                        child: _Bell(unread: unread),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              // Row 2: streak + goal (responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 350;

                  if (isSmallScreen) {
                    // Stack vertically on small screens
                    return Column(
                      children: [
                        Semantics(
                          label: 'Current streak: ${_getCurrentStreak(profile)} days',
                          child: _SmallPill(
                            icon: Icons.local_fire_department,
                            label: '${_getCurrentStreak(profile)}-day streak',
                            bg: const Color(0xFFFFF2E5), // peach
                          ),
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: 'Today\'s goal progress: $done out of $total items completed',
                          child: Column(
                            children: [
                              Text(
                                "TODAY'S GOAL",
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                '$done/$total items',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Horizontal layout for larger screens
                    return Row(
                      children: [
                        Semantics(
                          label: 'Current streak: ${_getCurrentStreak(profile)} days',
                          child: _SmallPill(
                            icon: Icons.local_fire_department,
                            label: '${_getCurrentStreak(profile)}-day streak',
                            bg: const Color(0xFFFFF2E5), // peach
                          ),
                        ),
                        const Spacer(),
                        Semantics(
                          label: 'Today\'s goal progress: $done out of $total items completed',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "TODAY'S GOAL",
                                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Text(
                                '$done/$total items',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingHeader(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Error loading profile'),
      ),
    );
  }

  Widget _buildAvatar(UserProfile? userProfile) {
    final displayName = userProfile?.displayName ?? 'User';
    final initials = displayName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

    return Text(
      initials.isNotEmpty ? initials : 'U',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, UserProfile? userProfile) {
    final h = TimeOfDay.now().hour;
    final slot = h < 12
        ? 'morning'
        : h < 18
            ? 'afternoon'
            : 'evening';
    final firstName = userProfile?.displayName?.split(' ').first ?? 'Eco-hero';

    return Text(
      'Good $slot, $firstName',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  int _getCurrentStreak(GamificationProfile? profile) {
    if (profile == null) return 0;
    final streak = profile.streaks[StreakType.dailyClassification.toString()];
    return streak?.currentCount ?? 0;
  }
}

/// Points pill with pulse animation
class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points, required this.pulse});

  final int points;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.2).animate(
        CurvedAnimation(parent: pulse, curve: Curves.elasticOut),
      ),
      child: _SmallPill(
        icon: Icons.emoji_events_rounded,
        label: _formatNumber(points),
        bg: const Color(0xFFE6F7EC), // mint green
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Token pill showing AI token balance
class _TokenPill extends StatelessWidget {
  const _TokenPill({required this.tokens});

  final int tokens;

  @override
  Widget build(BuildContext context) {
    return _SmallPill(
      icon: Icons.bolt,
      label: _formatNumber(tokens),
      bg: const Color(0xFFE3F2FD), // light blue
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Bell with wiggle animation for notifications
class _Bell extends StatefulWidget {
  const _Bell({required this.unread});

  final int unread;

  @override
  State<_Bell> createState() => _BellState();
}

class _BellState extends State<_Bell> with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: -0.1,
      upperBound: 0.1,
    );
  }

  @override
  void didUpdateWidget(_Bell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unread > 0 && widget.unread == 0) {
      _wiggle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, // Minimum touch target size
      height: 44, // Minimum touch target size
      child: RotationTransition(
        turns: _wiggle,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            if (widget.unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small pill component for data chips
class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.icon,
    required this.label,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
