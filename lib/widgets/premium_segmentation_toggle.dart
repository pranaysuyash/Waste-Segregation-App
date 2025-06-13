import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';

/// Premium segmentation toggle widget with visual indicators for free tier users
class PremiumSegmentationToggle extends StatelessWidget {

  const PremiumSegmentationToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.onUpgradePressed,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onUpgradePressed;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, child) {
        final hasAdvancedSegmentation = premiumService.isPremiumFeature('advanced_segmentation');
        
        return Container(
          decoration: BoxDecoration(
            color: hasAdvancedSegmentation 
                ? Colors.blue.shade50 
                : Colors.grey.shade100,
                         borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasAdvancedSegmentation 
                  ? Colors.blue.shade200 
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Advanced Segmentation',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasAdvancedSegmentation 
                              ? null 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!hasAdvancedSegmentation) ...[
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasAdvancedSegmentation 
                            ? Colors.blue.shade600 
                            : Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'Identify multiple objects in a single image',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasAdvancedSegmentation 
                        ? null 
                        : Colors.grey.shade500,
                  ),
                ),
                value: hasAdvancedSegmentation ? value : false,
                onChanged: hasAdvancedSegmentation 
                    ? onChanged
                    : (bool newValue) {
                        // Show upgrade prompt for free tier users
                        _showPremiumUpgradeDialog(context);
                      },
              ),
              // Upgrade banner for free tier users
              if (!hasAdvancedSegmentation)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                                         borderRadius: const BorderRadius.only(
                       bottomLeft: Radius.circular(8),
                       bottomRight: Radius.circular(8),
                     ),
                    border: Border(
                      top: BorderSide(color: Colors.amber.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.amber.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upgrade to Pro to unlock advanced segmentation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onUpgradePressed ?? () => _showPremiumUpgradeDialog(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade to Pro'),
          ],
        ),
        content: const Text(
          'Advanced segmentation allows you to identify multiple objects in a single image. Upgrade to Pro to unlock this powerful feature!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium features screen
              Navigator.pushNamed(context, '/premium-features');
            },
            icon: const Icon(Icons.workspace_premium),
            label: const Text('Upgrade Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 