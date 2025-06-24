import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({
    super.key,
    this.height = 50,
    this.showAtBottom = false,
  });
  final double height;
  final bool showAtBottom;

  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context);
    final premiumService = Provider.of<PremiumService>(context);

    // Update ad service with premium status
    adService.setPremiumStatus(premiumService.isPremiumFeature('remove_ads'));

    if (showAtBottom) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: adService.getBannerAd(),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      child: adService.getBannerAd(),
    );
  }
}
