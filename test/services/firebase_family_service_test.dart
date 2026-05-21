import 'package:flutter_test/flutter_test.dart';
void main() {
  test(
    'firebase family service unit tests migrated to integration/emulator suites',
    () {},
    skip:
        'Legacy unit tests were API-stale. Firestore-coupled behavior is validated via integration/emulator tests.',
  );
}
