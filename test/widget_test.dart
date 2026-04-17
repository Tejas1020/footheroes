import 'package:flutter_test/flutter_test.dart';
import 'package:footheroes/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const FootheroesApp());
    await tester.pumpAndSettle();

    // Verify that the app renders key elements
    expect(find.text('MATCH DAY'), findsOneWidget);
    expect(find.text('Marcus Thornton'), findsOneWidget);
  });
}
