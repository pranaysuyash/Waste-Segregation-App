import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:waste_segregation_app/providers/app_providers.dart';
import 'package:waste_segregation_app/providers/token_providers.dart';
import '../models/token_wallet.dart';
import '../utils/routes.dart';
import '../utils/wallet_encryption.dart';
import '../utils/waste_app_logger.dart';

class TokenWalletScreen extends ConsumerWidget {
  const TokenWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(tokenWalletProvider);
    final transactionsAsync = ref.watch(tokenTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Wallet'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Export Wallet'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Restore Wallet'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tokenWalletProvider);
          ref.invalidate(tokenTransactionsProvider);
          await Future.wait([
            ref.read(tokenWalletProvider.future),
            ref.read(tokenTransactionsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            walletAsync.when(
              data: (wallet) => _WalletSummary(wallet: wallet),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load wallet: $e'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Need faster analysis?'),
                subtitle: const Text(
                    'Premium users get discounted instant token cost.'),
                trailing: const Icon(Icons.workspace_premium),
                onTap: () => Navigator.pushNamed(context, Routes.premium),
              ),
            ),
            const SizedBox(height: 16),
            _TokenStorefront(),
            const SizedBox(height: 16),
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (txns) {
                if (txns.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No transactions yet.'),
                    ),
                  );
                }
                return Column(
                  children: txns.take(20).map((txn) {
                    final isCredit = txn.delta >= 0;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isCredit
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                        title: Text(txn.description),
                        subtitle: Text(txn.timestamp.toLocal().toString()),
                        trailing: Text(
                          '${isCredit ? '+' : ''}${txn.delta}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load transactions: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'export':
        _exportWallet(context, ref);
      case 'import':
        _importWallet(context, ref);
    }
  }

  Future<void> _exportWallet(BuildContext context, WidgetRef ref) async {
    try {
      final wallet = await ref.read(tokenWalletProvider.future);
      if (wallet == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No wallet to export')),
          );
        }
        return;
      }
      final walletJson = jsonEncode(wallet.toJson());
      final userProfile = await ref.read(userProfileProvider.future);
      final userId = userProfile?.id ?? 'unknown';
      final integrityHash = WalletEncryption.computeIntegrityHash(
        walletJson: walletJson,
        userId: userId,
      );
      final exportPayload = jsonEncode({
        'v': 1,
        'wallet': wallet.toJson(),
        'integrity_hash': integrityHash,
      });
      await Clipboard.setData(ClipboardData(text: exportPayload));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet data copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      WasteAppLogger.severe('Wallet export failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importWallet(BuildContext context, WidgetRef ref) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.trim().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clipboard is empty')),
          );
        }
        return;
      }
      final parsed = jsonDecode(data.text!) as Map<String, dynamic>;
      Map<String, dynamic> walletData;
      if (parsed.containsKey('v') && parsed.containsKey('wallet')) {
        walletData = parsed['wallet'] as Map<String, dynamic>;
        if (parsed.containsKey('integrity_hash')) {
          final expectedHash = parsed['integrity_hash'] as String;
          final walletJson = jsonEncode(walletData);
          final userProfile = await ref.read(userProfileProvider.future);
          final userId = userProfile?.id ?? 'unknown';
          final valid = WalletEncryption.verifyIntegrity(
            expectedHash: expectedHash,
            walletJson: walletJson,
            userId: userId,
          );
          if (!valid) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wallet integrity check failed - data may be tampered'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      } else {
        walletData = parsed;
      }
      final restored = TokenWallet.fromJson(walletData);
      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.restoreWallet(restored);
      ref.invalidate(tokenWalletProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      WasteAppLogger.severe('Wallet import failed', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed - invalid wallet data')),
        );
      }
    }
  }
}

class _WalletSummary extends StatelessWidget {
  const _WalletSummary({required this.wallet});

  final TokenWallet? wallet;

  @override
  Widget build(BuildContext context) {
    final w = wallet;
    if (w == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Wallet not initialized yet.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Balance', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('${w.balance} tokens',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Earned: ${w.totalEarned}')),
                Expanded(child: Text('Spent: ${w.totalSpent}')),
              ],
            ),
            const SizedBox(height: 8),
            Text('Last updated: ${w.lastUpdated.toLocal()}'),
          ],
        ),
      ),
    );
  }
}

class _TokenStorefront extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TokenStorefront> createState() => _TokenStorefrontState();
}

class _TokenStorefrontState extends ConsumerState<_TokenStorefront> {
  bool _loading = false;
  String? _error;

  static const _tokenPacks = <String, int>{
    'token_pack_small': 25,
    'token_pack_medium': 100,
    'token_pack_large': 500,
  };

  static const _packLabels = <String, String>{
    'token_pack_small': 'Small Pack',
    'token_pack_medium': 'Medium Pack',
    'token_pack_large': 'Large Pack',
  };

  static const _packPrices = <String, String>{
    'token_pack_small': '\$0.99',
    'token_pack_medium': '\$2.99',
    'token_pack_large': '\$9.99',
  };

  Future<void> _buyPack(String packId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _error = 'Sign in to purchase tokens.');
        return;
      }

      final functions = FirebaseFunctions.instanceFor(
        region: 'asia-south1',
      );
      final result = await functions.httpsCallable('createTokenPurchaseSession')
          .call(<String, dynamic>{'pack_id': packId});

      final data = result.data as Map<String, dynamic>;
      final checkoutUrl = data['checkout_url'] as String;

      final uri = Uri.tryParse(checkoutUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() => _error = 'Could not open checkout page.');
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? 'Purchase failed.');
    } catch (e) {
      setState(() => _error = 'Purchase failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buy Tokens',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ..._tokenPacks.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.token_outlined),
                  title: Text(_packLabels[entry.key]!),
                  subtitle: Text('${entry.value} tokens'),
                  trailing: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _packPrices[entry.key]!,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  onTap: _loading ? null : () => _buyPack(entry.key),
                ),
              ),
            )),
      ],
    );
  }
}
