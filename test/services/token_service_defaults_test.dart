import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/token_service.dart';

void main() {
  test('TokenService defaults keep phase 0 enforcement off', () {
    expect(TokenService.enableTokenEnforcement, isFalse);
    expect(TokenService.enableServerSideValidation, isTrue);
  });
}
