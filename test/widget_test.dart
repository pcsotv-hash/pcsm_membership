import 'package:flutter_test/flutter_test.dart';

import 'package:pcsm_membership/main.dart';

void main() {
  testWidgets('App loads and shows membership title', (
    WidgetTester tester,
  ) async {
    // Build the real app widget.
    await tester.pumpWidget(const PcsmApp());

    // Allow async init work to settle (asset loads handled gracefully).
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Verify that the main screen title is present.
    expect(find.text('PCSM Membership Registration'), findsOneWidget);
  });
}
