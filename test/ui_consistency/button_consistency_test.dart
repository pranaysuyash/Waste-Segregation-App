import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';

import '../helpers/component_test_harness.dart';

void main() {
  group('Button consistency tests', () {
    testWidgets('renders all supported button styles without layout drift',
        (tester) async {
      await pumpComponent(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ModernButton(text: 'Filled', onPressed: _noop),
            SizedBox(height: 12),
            ModernButton(
              text: 'Outlined',
              style: ModernButtonStyle.outlined,
              onPressed: _noop,
            ),
            SizedBox(height: 12),
            ModernButton(
              text: 'Text',
              style: ModernButtonStyle.text,
              onPressed: _noop,
            ),
            SizedBox(height: 12),
            ModernButton(
              text: 'Glass',
              style: ModernButtonStyle.glassmorphism,
              onPressed: _noop,
            ),
          ],
        ),
        surfaceSize: const Size(360, 600),
      );

      expect(find.text('Filled'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Glass'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps minimum touch target across sizes', (tester) async {
      await pumpComponent(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ModernButton(
              text: 'Small',
              size: ModernButtonSize.small,
              onPressed: _noop,
            ),
            SizedBox(height: 12),
            ModernButton(
              text: 'Medium',
              size: ModernButtonSize.medium,
              onPressed: _noop,
            ),
            SizedBox(height: 12),
            ModernButton(
              text: 'Large',
              size: ModernButtonSize.large,
              onPressed: _noop,
            ),
          ],
        ),
        surfaceSize: const Size(360, 600),
      );

      for (final label in ['Small', 'Medium', 'Large']) {
        final buttonFinder = find.widgetWithText(ElevatedButton, label);
        expect(buttonFinder, findsOneWidget);
        expect(
          tester.getSize(buttonFinder).height,
          greaterThanOrEqualTo(AppTheme.buttonHeightSm),
          reason: '$label button should keep the 48dp minimum touch target',
        );
      }
    });

    testWidgets('supports icon, loading, tooltip and expanded states',
        (tester) async {
      await pumpComponent(
        tester,
        SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ModernButton(
                text: 'Scan',
                icon: Icons.camera_alt,
                tooltip: 'Start scan',
                onPressed: _noop,
              ),
              SizedBox(height: 12),
              ModernButton(
                text: 'Processing',
                isLoading: true,
                isExpanded: true,
                onPressed: _noop,
              ),
            ],
          ),
        ),
        surfaceSize: const Size(360, 600),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _noop() {}
