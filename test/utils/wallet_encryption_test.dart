import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/wallet_encryption.dart';

void main() {
  group('WalletEncryption', () {
    const userId = 'test-user-123';
    const differentUser = 'other-user-456';

    test('computeIntegrityHash produces consistent output for same input', () {
      const json = '{"balance":100,"totalEarned":200}';
      final hash1 = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      final hash2 = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      expect(hash1, hash2);
    });

    test('computeIntegrityHash produces different hash for different user', () {
      const json = '{"balance":100,"totalEarned":200}';
      final hash1 = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      final hash2 = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: differentUser,
      );
      expect(hash1, isNot(hash2));
    });

    test('computeIntegrityHash produces different hash for different data', () {
      const json1 = '{"balance":100,"totalEarned":200}';
      const json2 = '{"balance":101,"totalEarned":200}';
      final hash1 = WalletEncryption.computeIntegrityHash(
        walletJson: json1,
        userId: userId,
      );
      final hash2 = WalletEncryption.computeIntegrityHash(
        walletJson: json2,
        userId: userId,
      );
      expect(hash1, isNot(hash2));
    });

    test('verifyIntegrity returns true for valid data', () {
      const json = '{"balance":50,"totalEarned":100}';
      final hash = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      expect(
        WalletEncryption.verifyIntegrity(
          walletJson: json,
          expectedHash: hash,
          userId: userId,
        ),
        isTrue,
      );
    });

    test('verifyIntegrity returns false for tampered data', () {
      const originalJson = '{"balance":50,"totalEarned":100}';
      const tamperedJson = '{"balance":9999,"totalEarned":100}';
      final hash = WalletEncryption.computeIntegrityHash(
        walletJson: originalJson,
        userId: userId,
      );
      expect(
        WalletEncryption.verifyIntegrity(
          walletJson: tamperedJson,
          expectedHash: hash,
          userId: userId,
        ),
        isFalse,
      );
    });

    test('verifyIntegrity returns false for wrong user', () {
      const json = '{"balance":50,"totalEarned":100}';
      final hash = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      expect(
        WalletEncryption.verifyIntegrity(
          walletJson: json,
          expectedHash: hash,
          userId: differentUser,
        ),
        isFalse,
      );
    });

    test('verifyIntegrity returns false for empty expected hash', () {
      expect(
        WalletEncryption.verifyIntegrity(
          walletJson: '{}',
          expectedHash: '',
          userId: userId,
        ),
        isFalse,
      );
    });

    test('handles empty wallet JSON gracefully', () {
      const json = '';
      final hash = WalletEncryption.computeIntegrityHash(
        walletJson: json,
        userId: userId,
      );
      expect(hash, isNotEmpty);
      expect(
        WalletEncryption.verifyIntegrity(
          walletJson: json,
          expectedHash: hash,
          userId: userId,
        ),
        isTrue,
      );
    });
  });
}
