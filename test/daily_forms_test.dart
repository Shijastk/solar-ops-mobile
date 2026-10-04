import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/daily_forms.dart';
import 'package:solar_ops_mobile/models.dart';
import 'fixtures.dart';

void main() {
  testWidgets('stock reuses company and offers zero-balance product without GSTIN or HSN fields', (tester) async {
    tester.view.physicalSize = const Size(320,740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final json=sampleData();
    (json['stock']['balances'][0] as Map)['currentQuantity']=0;
    final c=AppController()..data=BootstrapData.fromJson(json)..selectedCompanyId='a';
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:StockEntrySheet(controller:c))));
    await tester.pumpAndSettle();
    expect(find.text('GSTIN'),findsNothing);
    expect(find.text('Company name'),findsNothing);
    expect(find.text('HSN / SAC'),findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('First panel · NOS').last);
    await tester.pumpAndSettle();
    expect(find.text('Quantity received (NOS)'),findsOneWidget);
    expect(find.text('Product name'),findsNothing);
    expect(tester.takeException(),isNull);
  });
  testWidgets('manual trip starts with essential fields and keeps owner and bills secondary', (tester) async {
    final c=AppController()..data=BootstrapData.fromJson(sampleData())..selectedCompanyId='a';
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:ManualTripForm(controller:c))));
    await tester.pumpAndSettle();
    expect(find.text('Place'),findsOneWidget);
    expect(find.text('Driver'),findsOneWidget);
    expect(find.text('Sites'),findsOneWidget);
    expect(find.text('Owner name (optional)'),findsNothing);
    expect(find.text('Upload bill'),findsNothing);
    expect(find.text('Price'),findsNothing);
    expect(tester.takeException(),isNull);
  });
}
