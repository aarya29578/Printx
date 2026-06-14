import 'package:flutter_test/flutter_test.dart';
import 'package:printx/app.dart';

void main() {
  testWidgets('PrintX app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PrintXApp());
    expect(find.text('PrintX'), findsWidgets);
  });
}
