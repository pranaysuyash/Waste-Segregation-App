import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Displays information about a recycling code (1-7) with description.
class RecyclingCodeInfoCard extends StatelessWidget {
  final String code;
  const RecyclingCodeInfoCard({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final String description =
        WasteInfo.recyclingCodes[code] ?? 'Unknown plastic type';
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.secondaryColor),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recycling Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }
}