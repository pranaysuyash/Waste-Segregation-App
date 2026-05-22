import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/token_wallet.dart';

void main() {
  group('TokenWallet', () {
    test('newUser factory creates wallet with welcome bonus', () {
      final wallet = TokenWallet.newUser();
      expect(wallet.balance, 50);
      expect(wallet.totalEarned, 50);
      expect(wallet.totalSpent, 0);
      expect(wallet.schemaVersion, TokenWallet.currentSchemaVersion);
    });

    test('canAfford returns true when balance >= cost', () {
      final wallet = TokenWallet(
        balance: 10,
        totalEarned: 10,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );
      expect(wallet.canAfford(10), isTrue);
      expect(wallet.canAfford(5), isTrue);
      expect(wallet.canAfford(11), isFalse);
    });

    test('canAfford returns false for zero-balance wallet', () {
      final wallet = TokenWallet(
        balance: 0,
        totalEarned: 0,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );
      expect(wallet.canAfford(0), isTrue);
      expect(wallet.canAfford(1), isFalse);
    });

    test('canConvertToday returns true when no previous conversions', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );
      expect(wallet.canConvertToday(3), isTrue);
    });

    test('canConvertToday returns false when daily limit reached', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
        dailyConversionsUsed: 3,
        lastConversionDate: DateTime.now(),
      );
      expect(wallet.canConvertToday(3), isFalse);
      expect(wallet.canConvertToday(5), isTrue);
    });

    test('canConvertToday resets on new day', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        dailyConversionsUsed: 5,
        lastConversionDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(wallet.canConvertToday(3), isTrue);
    });

    test('remainingConversions returns full limit when no conversions today', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
      );
      expect(wallet.remainingConversions(3), 3);
    });

    test('remainingConversions returns partial when some used', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
        dailyConversionsUsed: 2,
        lastConversionDate: DateTime.now(),
      );
      expect(wallet.remainingConversions(3), 1);
    });

    test('remainingConversions returns 0 when limit reached', () {
      final wallet = TokenWallet(
        balance: 100,
        totalEarned: 100,
        totalSpent: 0,
        lastUpdated: DateTime.now(),
        dailyConversionsUsed: 3,
        lastConversionDate: DateTime.now(),
      );
      expect(wallet.remainingConversions(3), 0);
    });

    test('toJson and fromJson round-trip preserves all fields', () {
      final original = TokenWallet(
        balance: 42,
        totalEarned: 100,
        totalSpent: 58,
        lastUpdated: DateTime(2026, 5, 21, 10, 30, 0),
        dailyConversionsUsed: 1,
        lastConversionDate: DateTime(2026, 5, 21, 9, 0, 0),
        schemaVersion: 1,
      );
      final json = original.toJson();
      final restored = TokenWallet.fromJson(json);

      expect(restored.balance, 42);
      expect(restored.totalEarned, 100);
      expect(restored.totalSpent, 58);
      expect(restored.dailyConversionsUsed, 1);
      expect(restored.schemaVersion, 1);
    });

    test('fromJson handles null optional fields', () {
      final restored = TokenWallet.fromJson({
        'balance': 10,
        'totalEarned': 10,
        'totalSpent': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      expect(restored.balance, 10);
      expect(restored.dailyConversionsUsed, 0);
      expect(restored.lastConversionDate, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final wallet = TokenWallet(
        balance: 10,
        totalEarned: 20,
        totalSpent: 10,
        lastUpdated: DateTime.now(),
        dailyConversionsUsed: 2,
      );
      final updated = wallet.copyWith(balance: 5);
      expect(updated.balance, 5);
      expect(updated.totalEarned, 20);
      expect(updated.totalSpent, 10);
      expect(updated.dailyConversionsUsed, 2);
    });

    test('toString includes key fields', () {
      final wallet = TokenWallet(
        balance: 42,
        totalEarned: 100,
        totalSpent: 58,
        lastUpdated: DateTime.now(),
      );
      final str = wallet.toString();
      expect(str, contains('42'));
      expect(str, contains('100'));
      expect(str, contains('58'));
    });
  });

  group('TokenTransaction', () {
    test('toJson and fromJson round-trip preserves all fields', () {
      final original = TokenTransaction(
        id: 'txn_001',
        delta: -5,
        type: TokenTransactionType.spend,
        timestamp: DateTime(2026, 5, 21, 10, 0, 0),
        description: 'Instant AI analysis',
        reference: 'classification_123',
        metadata: {'model': 'gpt-4.1-nano'},
      );
      final json = original.toJson();
      final restored = TokenTransaction.fromJson(json);

      expect(restored.id, 'txn_001');
      expect(restored.delta, -5);
      expect(restored.type, TokenTransactionType.spend);
      expect(restored.description, 'Instant AI analysis');
      expect(restored.reference, 'classification_123');
      expect(restored.metadata?['model'], 'gpt-4.1-nano');
    });

    test('delta is positive for earn transactions', () {
      final txn = TokenTransaction(
        id: 'txn_002',
        delta: 10,
        type: TokenTransactionType.earn,
        timestamp: DateTime.now(),
        description: 'Daily login bonus',
      );
      expect(txn.delta, greaterThan(0));
    });

    test('delta is negative for spend transactions', () {
      final txn = TokenTransaction(
        id: 'txn_003',
        delta: -5,
        type: TokenTransactionType.spend,
        timestamp: DateTime.now(),
        description: 'AI analysis',
      );
      expect(txn.delta, lessThan(0));
    });
  });

  group('AnalysisSpeed', () {
    test('batch costs 1 token', () {
      expect(AnalysisSpeed.batch.cost, 1);
    });

    test('instant costs 5 tokens', () {
      expect(AnalysisSpeed.instant.cost, 5);
    });

    test('displayName is non-empty', () {
      for (final speed in AnalysisSpeed.values) {
        expect(speed.displayName, isNotEmpty);
      }
    });

    test('description is non-empty', () {
      for (final speed in AnalysisSpeed.values) {
        expect(speed.description, isNotEmpty);
      }
    });
  });

  group('TokenTransactionType', () {
    test('has expected values', () {
      expect(TokenTransactionType.values, containsAll([
        TokenTransactionType.earn,
        TokenTransactionType.spend,
        TokenTransactionType.convert,
        TokenTransactionType.bonus,
        TokenTransactionType.refund,
      ]));
    });
  });
}
