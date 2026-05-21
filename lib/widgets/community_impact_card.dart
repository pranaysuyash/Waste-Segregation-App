import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import '../widgets/modern_ui/modern_cards.dart';
import '../screens/waste_dashboard_screen.dart';

/// A compact "Your Impact" card for the home screen.
///
/// MVP rules:
/// - Uses local classification history only.
/// - No fake global/community totals.
/// - Empty state prompts first scan.
/// - Tap navigates to [WasteDashboardScreen].
class CommunityImpactCard extends StatelessWidget {
  const CommunityImpactCard({
    super.key,
    required this.classifications,
    this.onTap,
  });

  final List<WasteClassification> classifications;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (classifications.isEmpty) {
      return _buildEmptyState(context);
    }

    final stats = _computeStats(classifications);

    return ModernCard(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WasteDashboardScreen(),
                ),
              ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppTheme.primaryColor,
                  size: AppTheme.iconSizeMd,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Impact',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.totalItems} items classified',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _ImpactRow(
            icon: Icons.cloud_off_outlined,
            label: 'Est. CO₂ saved',
            value: '${stats.estimatedCO2Saved.toStringAsFixed(1)} kg',
            color: Colors.green,
          ),
          if (stats.waterSavedLiters > 0) ...[
            const SizedBox(height: AppTheme.spacingSm),
            _ImpactRow(
              icon: Icons.water_drop_outlined,
              label: 'Water saved',
              value: '${stats.waterSavedLiters.round()} L',
              color: Colors.blue,
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          _ImpactRow(
            icon: Icons.category_outlined,
            label: 'Most common',
            value: stats.mostCommonCategory,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _ImpactRow(
            icon: Icons.calendar_view_week_outlined,
            label: "This week's progress",
            value: '${stats.thisWeekCount} items',
            color: AppTheme.rewardGold,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: AppTheme.neutralColor,
                  size: AppTheme.iconSizeMd,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Impact',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No scans yet',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSizeRegular,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Start classifying waste to see your personal environmental impact. Every item sorted makes a difference!',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSizeRegular,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              const Icon(
                Icons.camera_alt,
                size: AppTheme.iconSizeSm,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                'Tap to scan your first item',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static _ImpactStats _computeStats(List<WasteClassification> list) {
    final totalItems = list.length;

    // CO2: prefer explicit co2Impact when available; fallback to simple heuristic
    var estimatedCO2Saved = 0.0;
    for (final c in list) {
      if (c.co2Impact != null) {
        estimatedCO2Saved += c.co2Impact!;
      } else if (c.isRecyclable == true) {
        estimatedCO2Saved += 0.5;
      }
    }

    // Water: prefer explicit waterPollutionLevel inverse proxy (1-5 scale)
    // If we don't have real water data, show 0 so the row is hidden.
    var waterSavedLiters = 0.0;
    for (final c in list) {
      if (c.waterPollutionLevel != null) {
        // rough proxy: higher pollution prevented = more water "saved"
        waterSavedLiters += c.waterPollutionLevel! * 20;
      }
    }

    // Most common category
    final categoryCounts = <String, int>{};
    for (final c in list) {
      categoryCounts.update(c.category, (v) => v + 1, ifAbsent: () => 1);
    }
    final mostCommonCategory =
        categoryCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // This week = since Monday of current week
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final thisWeekCount = list.where((c) {
      final d = DateTime(
        c.timestamp.year,
        c.timestamp.month,
        c.timestamp.day,
      );
      return d.isAtSameMomentAs(weekStart) || d.isAfter(weekStart);
    }).length;

    return _ImpactStats(
      totalItems: totalItems,
      estimatedCO2Saved: estimatedCO2Saved,
      waterSavedLiters: waterSavedLiters,
      mostCommonCategory: mostCommonCategory,
      thisWeekCount: thisWeekCount,
    );
  }
}

class _ImpactStats {
  _ImpactStats({
    required this.totalItems,
    required this.estimatedCO2Saved,
    required this.waterSavedLiters,
    required this.mostCommonCategory,
    required this.thisWeekCount,
  });

  final int totalItems;
  final double estimatedCO2Saved;
  final double waterSavedLiters;
  final String mostCommonCategory;
  final int thisWeekCount;
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeSm, color: color),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSizeRegular,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSizeRegular,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
