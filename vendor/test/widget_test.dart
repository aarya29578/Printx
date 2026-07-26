import 'package:flutter_test/flutter_test.dart';
import 'package:printx_vendor/vendor_app.dart';

void main() {
  testWidgets('PrintX Vendor app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const PrintXVendorApp());
    expect(find.text('PrintX Vendor'), findsWidgets);
  });
}
