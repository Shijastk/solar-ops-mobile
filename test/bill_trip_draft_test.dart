import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/bill_trip_draft.dart';
import 'package:solar_ops_mobile/models.dart';
import 'package:solar_ops_mobile/trip_activity_ui.dart';
import 'fixtures.dart';

class DraftController extends AppController {
  int uploads = 0, saves = 0;
  String? uploadedRequest;
  bool failCommit = false;
  @override
  Future<Map<String, dynamic>> uploadDraftFile(
      String name, Uint8List bytes, String requestId) async {
    uploads++;
    uploadedRequest = requestId;
    return {'id': 'saved-bill', 'duplicate': false};
  }

  @override
  Future<DeliveryTrip> commitBillDraft(Map<String, dynamic> payload) async {
    saves++;
    if (failCommit) throw Exception('Offline');
    return DeliveryTrip.fromJson({
      'id': payload['requestId'],
      'bills': [
        {'messageId': 'saved-bill'}
      ]
    });
  }
}

void main() {
  testWidgets(
      'opening bill draft and choosing PDF do not upload or create trip; only Save does',
      (tester) async {
    final c = DraftController()
      ..data = BootstrapData.fromJson(sampleData())
      ..selectedCompanyId = 'a';
    addTearDown(c.dispose);
    final pdf = DraftPdf(
        'synthetic.pdf', Uint8List.fromList('%PDF-synthetic'.codeUnits));
    await tester.pumpWidget(MaterialApp(
        home: BillTripDraftPage(controller: c, pickFiles: () async => [pdf])));
    await tester.pumpAndSettle();
    expect(c.uploads, 0);
    expect(c.saves, 0);
    await tester.tap(find.text('Add PDFs'));
    await tester.pumpAndSettle();
    expect(find.text('Not uploaded'), findsOneWidget);
    expect(c.uploads, 0);
    expect(c.saves, 0);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver A').last);
    await tester.pumpAndSettle();
    c.failCommit = true;
    await tester.ensureVisible(find.text('Save trip'));
    await tester.tap(find.text('Save trip'));
    await tester.pumpAndSettle();
    expect(c.uploads, 1);
    expect(c.saves, 1);
    expect(c.uploadedRequest, pdf.requestId);
    await tester.ensureVisible(find.text('Retry save'));
    await tester.tap(find.text('Retry save'));
    await tester.pumpAndSettle();
    expect(c.uploads, 1);
    expect(c.saves, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'stock cards and chart remain company-scoped; unknown summary is not zero',
      (tester) async {
    final activity = {
      'today': '2026-10-04',
      'pending': [
        {'companyId': 'a', 'count': 2},
        {'companyId': 'b', 'count': 9}
      ],
      'daily': [
        {'companyId': 'a', 'day': '2026-10-04', 'count': 3},
        {'companyId': 'b', 'day': '2026-10-04', 'count': 11}
      ]
    };
    expect(TripActivity(activity).count('daily', 'a', day: '2026-10-04'), 3);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(children: [
      TripSummaryCards(data: activity, companyId: 'a'),
      TripActivityChart(data: activity, companyId: 'a')
    ]))));
    await tester.pumpAndSettle();
    expect(find.text('3 trips'), findsOneWidget);
    expect(find.text('2 trips'), findsOneWidget);
    expect(find.text('3 completed trips · last 7 days'), findsOneWidget);
    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();
    expect(find.text('3 completed trips · last 30 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TripSummaryCards(data: null))));
    expect(find.text('Unavailable'), findsNWidgets(2));
  });
}
