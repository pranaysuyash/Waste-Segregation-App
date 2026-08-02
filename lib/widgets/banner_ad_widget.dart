import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({
    super.key,
    this.height = 50,
    this.showAtBottom = false,
  });
  final double height;
  final bool showAtBottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adService = ref.watch(adServiceProvider);
    final premiumService = ref.watch(premiumServiceProvider);

    // Update ad service with premium status
    adService.setPremiumStatus(premiumService.hasActivePremiumPlan());

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
