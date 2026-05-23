import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:waste_segregation_app/providers/token_providers.dart';
import '../models/token_wallet.dart';
import '../utils/routes.dart';
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
      await Clipboard.setData(ClipboardData(text: walletJson));
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
      final restored = TokenWallet.fromJson(parsed);
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
