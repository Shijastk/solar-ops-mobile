import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/main.dart';

void main() {
  testWidgets('dashboard renders core Solar Ops sections', (tester) async {
    await tester.pumpWidget(const SolarOpsApp());

    expect(find.text('Solar Ops'), findsOneWidget);
    expect(find.text('Bills today'), findsOneWidget);
    expect(find.text('Pending review'), findsOneWidget);
    expect(find.text('Dispatched'), findsWidgets);
    expect(find.text('Stock alerts'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent bills'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recent bills'), findsOneWidget);
  });

  testWidgets('bottom navigation opens stock page', (tester) async {
    await tester.pumpWidget(const SolarOpsApp());

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();

    expect(find.text('Opening stock and inventory ledger will appear here.'),
        findsOneWidget);
  });
}
