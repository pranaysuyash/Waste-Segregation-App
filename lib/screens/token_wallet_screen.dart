import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/token_providers.dart';
import '../models/token_wallet.dart';
import '../utils/routes.dart';

class TokenWalletScreen extends ConsumerWidget {
  const TokenWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(tokenWalletProvider);
    final transactionsAsync = ref.watch(tokenTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Token Wallet')),
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
