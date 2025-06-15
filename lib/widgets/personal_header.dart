import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gamification.dart';
import '../models/waste_classification.dart';

/// Personal header widget with time-of-day awareness and dynamic greetings
/// Requires profileProvider and classificationsProvider to be available in the widget tree
class PersonalHeader extends ConsumerWidget {
  const PersonalHeader({
    super.key,
    required this.profileAsync,
    required this.classificationsAsync,
  });

  final AsyncValue<GamificationProfile?> profileAsync;
  final AsyncValue<List<WasteClassification>> classificationsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    
    // Determine time phase
    final phase = _getTimePhase(hour);
    
    // Get dynamic gradient colors based on time of day
    final gradient = _getPhaseGradient(theme, phase);
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Time-of-day illustration placeholder
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(44),
            ),
            child: Icon(
              _getPhaseIcon(phase),
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamic greeting
                profileAsync.when(
                  data: (profile) => Text(
                    'Good $phase, ${profile?.userId ?? 'Eco-hero'}!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  loading: () => Text(
                    'Good $phase, Eco-hero!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Good $phase, Eco-hero!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Dynamic impact message
                classificationsAsync.when(
                  data: (classifications) {
                    final totalItems = classifications.length;
                    final estimatedWeight = totalItems * 45; // Rough estimate: 45g per item
                    return Text(
                      'You\'ve diverted ${estimatedWeight}g of waste from landfill 💚',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                    );
                  },
                  loading: () => Text(
                    'Building a sustainable future, one item at a time 🌱',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  error: (_, __) => Text(
                    'Every small action makes a big difference 🌍',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Optional progress ring (for future gamification enhancement)
          profileAsync.when(
            data: (profile) {
              if (profile?.points.total != null && profile!.points.total > 0) {
                final progress = (profile.points.total % 100) / 100.0;
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation(
                          theme.colorScheme.onPrimary,
                        ),
                        backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                      ),
                      Center(
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Determine time phase based on hour
  String _getTimePhase(int hour) {
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'night';
  }

  /// Get appropriate icon for time phase
  IconData _getPhaseIcon(String phase) {
    switch (phase) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_cloudy;
      case 'night':
        return Icons.nights_stay;
      default:
        return Icons.wb_sunny;
    }
  }

  /// Get gradient colors based on time phase
  LinearGradient _getPhaseGradient(ThemeData theme, String phase) {
    final baseColor = theme.colorScheme.primary;
    
    switch (phase) {
      case 'morning':
        return LinearGradient(
          colors: [
            _blendWithPhase(baseColor, const Color(0xFFFFD54F)), // Warm yellow
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'afternoon':
        return LinearGradient(
          colors: [
            _blendWithPhase(baseColor, const Color(0xFF4FC3F7)), // Sky blue
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'night':
        return LinearGradient(
          colors: [
            _blendWithPhase(baseColor, const Color(0xFFB39DDB)), // Cool lavender
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [theme.colorScheme.primaryContainer, baseColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Blend base color with phase-specific tint
  Color _blendWithPhase(Color base, Color phaseTint) {
    return Color.alphaBlend(phaseTint.withValues(alpha: 0.20), base);
  }
} 