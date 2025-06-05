import 'package:flutter/material.dart';
import '../models/premium_feature.dart';
import '../utils/constants.dart';

class PremiumFeatureCard extends StatelessWidget {

  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.isEnabled,
    this.onTap,
  });
  final PremiumFeature feature;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Get icon using the AppIcons utility to prevent errors from invalid icon data
    final iconData = AppIcons.fromString(feature.icon);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Subtle gradient background based on feature status
            gradient: LinearGradient(
              colors: isEnabled
                  ? [
                      Theme.of(context).primaryColor.withValues(alpha:0.05),
                      Theme.of(context).primaryColor.withValues(alpha:0.15),
                    ]
                  : [
                      Colors.grey.withValues(alpha:0.05),
                      Colors.grey.withValues(alpha:0.1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Theme.of(context).primaryColor.withValues(alpha:0.1)
                      : Colors.grey.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  size: 28,
                  color: isEnabled ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              
              // Feature details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        color: isEnabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: isEnabled
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                    : const Icon(Icons.lock, color: Colors.grey, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}