import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../widgetbook/main.dart' as wb;

void main() {
  testWidgets('Widgetbook app renders', (tester) async {
    await tester.pumpWidget(const wb.WidgetbookApp());
    await tester.pumpAndSettle();

    expect(find.byType(Widgetbook), findsOneWidget);
  });
}
