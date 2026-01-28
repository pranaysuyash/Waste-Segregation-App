import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/screens/image_capture_screen.dart';

void main() {
  group('ImageCaptureScreen', () {
    testWidgets('renders waiting state when no image is provided',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ImageCaptureScreen(),
          ),
        ),
      );

      expect(find.text('Waiting for camera...'), findsOneWidget);
    });
  });
}

