import 'package:daily/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DailyApp Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyApp());
    expect(find.byType(DailyApp), findsOneWidget);
  });
}
