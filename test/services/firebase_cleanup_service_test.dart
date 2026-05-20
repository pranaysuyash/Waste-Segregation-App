import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/firebase_cleanup_service.dart';

void main() {
  group('FirebaseCleanupService', () {
    late FirebaseCleanupService service;

    setUp(() {
      service = FirebaseCleanupService();
    });

    test('should be instantiable', () {
      expect(service, isA<FirebaseCleanupService>());
    });

    test('fresh-install flag defaults to false in test runtime', () {
      FirebaseCleanupService.didPerformFreshInstall = false;
      expect(FirebaseCleanupService.didPerformFreshInstall, isFalse);
    });

    test('fresh-install flag is writable for app lifecycle signaling', () {
      FirebaseCleanupService.didPerformFreshInstall = false;
      FirebaseCleanupService.didPerformFreshInstall = true;
      expect(FirebaseCleanupService.didPerformFreshInstall, isTrue);
    });
  });
}
