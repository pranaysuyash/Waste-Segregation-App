import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/firebase_family_service.dart';

void main() {
  group('FirebaseFamilyService', () {
    late FirebaseFamilyService service;

    setUp(() {
      service = FirebaseFamilyService();
    });

    test('generateInviteCode returns non-empty uppercase code', () {
      final code = service.generateInviteCode();
      expect(code, isNotEmpty);
      expect(code, equals(code.toUpperCase()));
      expect(code.length, greaterThanOrEqualTo(6));
    });

    test('generateInviteCode returns different values across calls', () {
      final first = service.generateInviteCode();
      final second = service.generateInviteCode();
      expect(first, isNot(equals(second)));
    });

    test(
      'firestore-dependent behavior covered by integration suites',
      () {},
      skip:
          'Service uses FirebaseFirestore.instance directly; API-contract and runtime behavior are covered in integration/emulator tests.',
    );
  });
}
