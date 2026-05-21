import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_buttons.dart';

import '../../helpers/component_test_harness.dart';

void main() {
  group('ModernButton component library', () {
    testWidgets('renders all style variants', (tester) async {
      await pumpComponent(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            ModernButton(text: 'Filled', onPressed: _noop),
            ModernButton(
              text: 'Outlined',
              style: ModernButtonStyle.outlined,
              onPressed: _noop,
            ),
            ModernButton(
              text: 'Text',
              style: ModernButtonStyle.text,
              onPressed: _noop,
            ),
            ModernButton(
              text: 'Glass',
              style: ModernButtonStyle.glassmorphism,
              onPressed: _noop,
            ),
          ],
        ),
      );

      expect(find.text('Filled'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Glass'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await pumpComponent(
        tester,
        const ModernButton(text: 'Loading', isLoading: true),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('supports icon and tooltip', (tester) async {
      await pumpComponent(
        tester,
        const ModernButton(
          text: 'Scan',
          icon: Icons.camera_alt,
          tooltip: 'Start scan',
          onPressed: _noop,
        ),
      );
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });
  });
}

void _noop() {}
