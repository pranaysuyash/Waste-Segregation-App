import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/premium_feature.dart';
import '../services/premium_service.dart';
import '../widgets/premium_feature_card.dart';
import '../utils/constants.dart';
import '../utils/developer_config.dart';
import 'package:provider/provider.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _showTestOptions = false;

  @override
  Widget build(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        actions: [
          // Only show test mode toggle when developer features are enabled
          if (DeveloperConfig.canShowPremiumToggles)
            IconButton(
              icon: Icon(
                _showTestOptions ? Icons.developer_mode : Icons.developer_mode_outlined,
                color: _showTestOptions ? Colors.yellow : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showTestOptions = !_showTestOptions;
                });
              },
              tooltip: 'Toggle Developer Mode',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Developer test options (secure debug only)
          if (DeveloperConfig.canShowPremiumToggles && _showTestOptions)
            _buildDeveloperTestOptions(context),
            
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildComingSoonFeatures(context),
          const SizedBox(height: 24),
          _buildPremiumFeatures(context),
          
          // Purchase button at the bottom
          const SizedBox(height: 32),
          _buildPurchaseButton(context),
        ],
      ),
    );
  }

  Widget _buildDeveloperTestOptions(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'DEVELOPER TESTING MODE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.orange),
                onPressed: () async {
                  await premiumService.resetPremiumFeatures();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All premium features reset')),
                    );
                  }
                },
                tooltip: 'Reset all premium features',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Use these toggles to test premium features',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...PremiumFeature.features.map((feature) => _buildFeatureToggle(feature, premiumService)),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(PremiumFeature feature, PremiumService premiumService) {
    final isEnabled = premiumService.isPremiumFeature(feature.id);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature.title,
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textPrimaryColor),
            ),
          ),
          Switch(
            value: isEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              await premiumService.setPremiumFeature(feature.id, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Get access to all premium features and enjoy an ad-free experience',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFeatureBadge(context, 'No Ads'),
              const SizedBox(width: 8),
              _buildFeatureBadge(context, 'Offline Mode'),
              const SizedBox(width: 8),
              _buildFeatureBadge(context, 'Analytics'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha:0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildComingSoonFeatures(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);
    final comingSoonFeatures = premiumService.getComingSoonFeatures();

    if (comingSoonFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Premium Features',
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
          'Your Premium Features',
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

  Widget _buildPurchaseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () {
          // This would normally launch the in-app purchase flow
          if (kDebugMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('In-app purchase flow would launch here. Use developer mode to test features.'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Premium features coming soon!'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium),
            SizedBox(width: 8),
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}