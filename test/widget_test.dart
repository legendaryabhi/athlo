import 'package:flutter_test/flutter_test.dart';
import 'package:athlo/main.dart';

void main() {
  testWidgets('Counter value increment smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app shows the title text.
    expect(find.text('Athlo App'), findsOneWidget);
  });
}
