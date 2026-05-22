import 'dart:convert';
import 'package:crypto/crypto.dart';

class WalletEncryption {
  static const _salt = 'waste_seg_integrity_v1';

  static String _deriveKey(String userId) {
    final keyMaterial = '$userId:$_salt';
    return sha256.convert(utf8.encode(keyMaterial)).toString();
  }

  static String computeIntegrityHash({
    required String walletJson,
    required String userId,
  }) {
    final key = _deriveKey(userId);
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(walletJson)).toString();
  }

  static bool verifyIntegrity({
    required String walletJson,
    required String expectedHash,
    required String userId,
  }) {
    final computed = computeIntegrityHash(
      walletJson: walletJson,
      userId: userId,
    );
    return computed == expectedHash;
  }
}
