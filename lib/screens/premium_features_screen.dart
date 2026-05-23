import 'package:flutter/material.dart';
import '../models/premium_feature.dart';
import '../services/premium_service.dart';
import '../services/purchase_service.dart';
import '../services/web_checkout_service.dart';
import '../widgets/premium_feature_card.dart';
import '../widgets/settings/premium_feature_visuals.dart';
import '../utils/dialog_helper.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/developer_config.dart';
import 'package:provider/provider.dart';

class PremiumFeaturesScreen extends StatefulWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  State<PremiumFeaturesScreen> createState() => _PremiumFeaturesScreenState();
}

class _PremiumFeaturesScreenState extends State<PremiumFeaturesScreen> {
  bool _showTestOptions = false;
  WebCheckoutService? _webCheckoutService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _webCheckoutService ??= WebCheckoutService(
      Provider.of<PremiumService>(context, listen: false),
    )..addListener(_onWebCheckoutChange);
  }

  void _onWebCheckoutChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _webCheckoutService?.removeListener(_onWebCheckoutChange);
    _webCheckoutService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Features'),
        actions: [
          // Only show test mode toggle when developer features are enabled
          if (DeveloperConfig.canShowPremiumToggles)
            IconButton(
              icon: Icon(
                _showTestOptions
                    ? Icons.developer_mode
                    : Icons.developer_mode_outlined,
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

          const SizedBox(height: 32),
          _buildPurchaseSection(context),
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
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All premium features reset')),
                  );
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
          ...PremiumFeature.features
              .map((feature) => _buildFeatureToggle(feature, premiumService)),
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
      PremiumFeature feature, PremiumService premiumService) {
    final isEnabled = premiumService.isPremiumFeature(feature.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor),
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
            color: Colors.black.withValues(alpha: 0.1),
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
              onTap: () => _showLockedFeaturePrompt(context, feature),
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

  void _showLockedFeaturePrompt(BuildContext context, PremiumFeature feature) {
    DialogHelper.showPremiumPrompt(
      context,
      featureName: feature.title,
      description: PremiumFeatureVisuals.upgradeMessage(
        context,
        featureName: feature.title,
        benefit: feature.description,
      ),
      onUpgrade: () => Navigator.pushNamed(context, Routes.premiumFeatures),
    );
  }

  Widget _buildPurchaseSection(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService?>(context);
    final premiumService = Provider.of<PremiumService>(context);
    final hasPremium = premiumService.hasActivePremiumPlan();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Already premium
          if (hasPremium) ...[
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.verified),
              label: const Text('Premium Active'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            // IAP purchase option
            if (purchaseService != null) _buildIapPurchase(context, premiumService, purchaseService),

            const SizedBox(height: 16),

            // Divider with label
            if (purchaseService != null) ...[
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // DodoPayments web checkout option
            _buildDodoPaymentsButton(context, premiumService),
          ],
        ],
      ),
    );
  }

  Widget _buildIapPurchase(BuildContext context, PremiumService premiumService, PurchaseService purchaseService) {
    final product = purchaseService.premiumProduct;

    final buttonLabel = purchaseService.isProcessingPurchase
        ? 'Processing...'
        : product == null
            ? 'Premium Unavailable'
            : 'App Store \$4.99/mo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: !purchaseService.canPurchase
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await purchaseService.buyPremium();
                  if (!mounted) return;
                  if (premiumService.hasActivePremiumPlan()) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Premium unlocked successfully.')),
                    );
                  } else if (purchaseService.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(purchaseService.errorMessage!)),
                    );
                  }
                },
          icon: const Icon(Icons.shopping_cart),
          label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: purchaseService.isProcessingPurchase
              ? null
              : () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await purchaseService.restorePurchases();
                  if (!mounted) return;
                  if (purchaseService.errorMessage != null) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(purchaseService.errorMessage!)),
                    );
                  }
                },
          child: const Text('Restore Purchases'),
        ),
        if (purchaseService.errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            purchaseService.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.red.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildDodoPaymentsButton(BuildContext context, PremiumService premiumService) {
    final webCheckout = _webCheckoutService;

    if (webCheckout == null) return const SizedBox.shrink();

    if (webCheckout.isAwaitingPayment) {
      return Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Waiting for payment...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete payment in the browser. Premium activates automatically once confirmed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => webCheckout.cancelAwaitingPayment(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: webCheckout.isCreatingSession ? null : () => webCheckout.startCheckout(),
          icon: webCheckout.isCreatingSession
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.public),
          label: Text(webCheckout.isCreatingSession ? 'Creating checkout...' : 'Pay with Card / UPI'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (webCheckout.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            webCheckout.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.red.shade600),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Pay online with credit/debit card, UPI, or net banking. No app store required.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
