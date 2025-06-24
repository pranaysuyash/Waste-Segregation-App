import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../services/ad_service.dart';

/// Helper utility to synchronize premium and ad services
class ServiceSync {
  /// Update the ad service based on premium status
  static void syncAdServiceWithPremium(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context, listen: false);
    final adService = Provider.of<AdService>(context, listen: false);

    // Update ad service with premium status
    adService.setPremiumStatus(premiumService.isPremiumFeature('remove_ads'));
  }

  /// Set context for showing ads appropriately
  static void setAdContext(
    BuildContext context, {
    required bool inClassificationFlow,
    required bool inEducationalContent,
    required bool inSettings,
  }) {
    final adService = Provider.of<AdService>(context, listen: false);
    adService.setInClassificationFlow(inClassificationFlow);
    adService.setInEducationalContent(inEducationalContent);
    adService.setInSettings(inSettings);
  }
}
