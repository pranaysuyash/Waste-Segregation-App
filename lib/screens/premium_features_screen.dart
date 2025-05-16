import 'package:flutter/material.dart';
import '../models/premium_feature.dart';
import '../services/premium_service.dart';
import '../widgets/premium_feature_card.dart';
import 'package:provider/provider.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildComingSoonFeatures(context),
          const SizedBox(height: 24),
          _buildPremiumFeatures(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upgrade to Premium',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock all features and enjoy an ad-free experience',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonFeatures(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final comingSoonFeatures = premiumService.getComingSoonFeatures();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...comingSoonFeatures.map((feature) => PremiumFeatureCard(
              feature: feature,
              isEnabled: false,
            )),
      ],
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final premiumFeatures = premiumService.getPremiumFeatures();

    if (premiumFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...premiumFeatures.map((feature) => PremiumFeatureCard(
              feature: feature,
              isEnabled: true,
            )),
      ],
    );
  }
} 