import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatelessWidget {
  final double height;
  final bool showAtBottom;

  const BannerAdWidget({
    Key? key,
    this.height = 50,
    this.showAtBottom = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context, listen: false);
    
    if (showAtBottom) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: adService.getBannerAd(),
      );
    }
    
    return adService.getBannerAd();
  }
}