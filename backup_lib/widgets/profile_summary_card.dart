import 'package:flutter/material.dart';
import '../models/gamification.dart';
import '../utils/constants.dart';

/// Displays user's level, rank, and points progress in a card.
class ProfileSummaryCard extends StatelessWidget {
  final UserPoints points;
  const ProfileSummaryCard({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.level,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.military_tech,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${points.level}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      AppStrings.rank,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      points.rankName,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            // Points progress bar and details
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppStrings.points}: ${points.total}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                    Text(
                      '${points.pointsToNextLevel} ${AppStrings.pointsEarned} to ${AppStrings.level} ${points.level + 1}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  child: LinearProgressIndicator(
                    value: (points.total % 100) / 100,
                    minHeight: 8,
                    color: AppTheme.primaryColor,
                    backgroundColor: AppTheme.textSecondaryColor.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}