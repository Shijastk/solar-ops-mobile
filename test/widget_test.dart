
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solar_ops_mobile/api_client.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/app_ui.dart';
import 'package:solar_ops_mobile/models.dart';

void main() {
  const bootstrapJson = {
    'apiVersion': 'v1',
    'generatedAt': '2026-09-25T12:00:00.000Z',
    'sessionExpiresAt': '2026-09-25T18:00:00.000Z',
    'runtime': {
      'healthy': true,
      'automationEnabled': true,
      'automationReady': true,
    },
    'dashboard': {
      'billsToday': 2,
      'totalBills': 5,
      'pendingReview': 1,
      'recorded': 3,
      'inboundMessages': 9,
      'stockProducts': 2,
      'totalStockQuantity': 42,
      'dailyBills': [
        {'key': '2026-09-25', 'label': 'Thu', 'count': 2}
      ],
    },
    'bills': [
      {
        'id': '11111111-1111-4111-8111-111111111111',
        'fileName': 'invoice.pdf',
        'mimeType': 'application/pdf',
        'mediaSizeBytes': 1234,
        'storageAvailable': true,
        'processingStatus': 'stored',
        'receivedAt': '2026-09-25T10:00:00.000Z',
        'senderName': 'Supplier',
        'senderPhoneMasked': '•••• 3210',
        'companyId': '44444444-4444-4444-8444-444444444444',
        'companyName': 'Supplier Pvt Ltd',
        'companyGstin': '32AAAAA0000A1Z5',
        'draft': {
          'id': '22222222-2222-4222-8222-222222222222',
          'parseStatus': 'ready_for_review',
          'documentType': 'tax_invoice',
          'supplierName': 'Supplier Pvt Ltd',
          'supplierGstin': '32AAAAA0000A1Z5',
          'supplierAddress': 'Kozhikode',
          'documentNumber': 'INV-42',
          'documentDate': '2026-09-25',
          'ewayBillNumber': '123',
          'consigneeName': 'Godown',
          'consigneeAddress': 'Kerala',
          'consigneeGstin': null,
          'buyerName': null,
          'buyerAddress': null,
          'buyerGstin': null,
          'destination': 'Kozhikode',
          'dispatchFromAddress': 'Supplier',
          'vehicleNumber': 'KL11AA1234',
          'approximateDistanceKm': 50,
          'supplyType': 'Outward',
          'transactionType': 'Regular',
          'taxableAmount': 1000,
          'cgstAmount': 90,
          'sgstAmount': 90,
          'totalAmount': 1180,
          'missingFields': [],
          'parseError': null,
          'extractedAt': '2026-09-25T10:01:00.000Z',
          'approvedAt': null,
          'verificationStatus': 'pending',
          'workflowStatus': 'review_required',
          'stockStatus': 'pending',
          'stockError': null,
          'stockUpdatedAt': null,
          'stockCompanyId': '44444444-4444-4444-8444-444444444444',
          'items': [
            {
              'id': '33333333-3333-4333-8333-333333333333',
              'lineIndex': 0,
              'description': 'Solar Panel',
              'hsnSac': '8541',
              'quantity': 10,
              'unit': 'NOS',
              'rate': 100,
              'amount': 1000,
            }
          ],
        },
      }
    ],
    'dispatches': [
      {
        'billId': '11111111-1111-4111-8111-111111111111',
        'fileName': 'invoice.pdf',
        'receivedAt': '2026-09-25T10:00:00.000Z',
        'documentNumber': 'INV-42',
        'companyId': '44444444-4444-4444-8444-444444444444',
        'companyName': 'Supplier Pvt Ltd',
        'companyGstin': '32AAAAA0000A1Z5',
        'destination': 'Kozhikode',
        'consigneeName': 'Godown',
        'vehicleNumber': 'KL11AA1234',
        'workflowStatus': 'review_required',
        'stockStatus': 'pending',
      }
    ],
    'stock': {
      'companies': [
        {
          'id': '44444444-4444-4444-8444-444444444444',
          'name': 'Supplier Pvt Ltd',
          'gstin': '32AAAAA0000A1Z5',
        }
      ],
      'balances': [
        {
          'productId': '55555555-5555-4555-8555-555555555555',
          'companyId': '44444444-4444-4444-8444-444444444444',
          'companyName': 'Supplier Pvt Ltd',
          'companyGstin': '32AAAAA0000A1Z5',
          'productName': 'Solar Panel',
          'unit': 'NOS',
          'hsnSac': '8541',
          'currentQuantity': 42,
        }
      ],
    },
    'conversations': [
      {
        'key': 'abc',
        'senderName': 'Supplier',
        'senderPhoneMasked': '•••• 3210',
        'latestReceivedAt': '2026-09-25T10:00:00.000Z',
        'latestInboundMessageId': '11111111-1111-4111-8111-111111111111',
        'canReply': true,
        'timeline': [
          {
            'type': 'inbound',
            'time': '2026-09-25T10:00:00.000Z',
            'id': '11111111-1111-4111-8111-111111111111',
            'messageType': 'document',
            'textBody': null,
            'fileName': 'invoice.pdf',
            'mimeType': 'application/pdf',
            'mediaSizeBytes': 1234,
            'storageAvailable': true,
            'processingStatus': 'stored',
          }
        ],
      }
    ],
  };

  test('parses the real mobile bootstrap contract', () {
    final data = BootstrapData.fromJson(bootstrapJson);

    expect(data.runtime.healthy, isTrue);
    expect(data.dashboard.billsToday, 2);
    expect(data.bills.single.draft?.supplierName, 'Supplier Pvt Ltd');
    expect(data.bills.single.companyId,
        '44444444-4444-4444-8444-444444444444');
    expect(data.bills.single.draft?.items.single.quantity, 10);
    expect(data.stock.balances.single.currentQuantity, 42);
    expect(data.conversations.single.canReply, isTrue);
    expect(data.dispatches.single.vehicleNumber, 'KL11AA1234');
  });


  test('company snapshot uses canonical company IDs and does not name-guess', () {
    final data = BootstrapData.fromJson(bootstrapJson);
    final company = data.stock.companies.single;
    final snapshot = CompanySnapshot.fromData(data, company);

    expect(snapshot.bills.length, 1);
    expect(snapshot.dispatches.length, 1);
    expect(snapshot.balances.length, 1);
    expect(snapshot.pendingReview, 1);
    expect(snapshot.balances.single.currentQuantity, 42);

    final payload =
        jsonDecode(jsonEncode(bootstrapJson)) as Map<String, dynamic>;
    final bills = payload['bills'] as List<dynamic>;
    final bill = Map<String, dynamic>.from(bills.single as Map);
    bill['companyId'] = null;
    bill['companyName'] = null;
    bill['companyGstin'] = null;
    bills[0] = bill;

    final unassignedData = BootstrapData.fromJson(payload);
    final unassignedSnapshot =
        CompanySnapshot.fromData(unassignedData, unassignedData.stock.companies.single);

    expect(unassignedSnapshot.bills, isEmpty);
  });

  test('API client sends bearer token and parses bootstrap', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode(bootstrapJson),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = SolarOpsApi(client: client);
    final data = await api.bootstrap('test-token');

    expect(data.dashboard.totalBills, 5);
    expect(data.bills.single.fileName, 'invoice.pdf');
    api.dispose();
  });

  test('session endpoint response is validated', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      return http.Response(
        jsonEncode({
          'token': 'signed-token',
          'expiresAt': '2026-09-26T00:00:00.000Z',
        }),
        200,
      );
    });

    final api = SolarOpsApi(client: client);
    final session = await api.createSession('access-key');

    expect(session.token, 'signed-token');
    expect(session.expiresAt.year, 2026);
    api.dispose();
  });

  testWidgets('stock adjustment dialog owns its controller lifecycle',
      (tester) async {
    double? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<double>(
                  context: context,
                  builder: (_) => const StockAdjustmentDialog(
                    productName: 'Solar Panel',
                    unit: 'NOS',
                    currentQuantity: 42,
                  ),
                );
              },
              child: const Text('Open adjustment'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open adjustment'));
    await tester.pumpAndSettle();
    expect(find.text('Adjust Solar Panel'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(result, 42);
  });


  testWidgets('company dropdown does not overflow on narrow phones',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const company = StockCompany(
      id: '44444444-4444-4444-8444-444444444444',
      name:
          'SAVITR SOLAR SOLUTIONS LIMITED KERALA DISTRIBUTION OPERATIONS',
      gstin: '32AAAAA0000A1Z5',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: CompanyFilterField(
              companies: const [company],
              selectedCompanyId: company.id,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();

    expect(find.text(company.name), findsWidgets);
    expect(tester.takeException(), isNull);
  });


  testWidgets('WhatsApp conversation opens at the latest message',
      (tester) async {
    final payload =
        jsonDecode(jsonEncode(bootstrapJson)) as Map<String, dynamic>;
    final conversations = payload['conversations'] as List<dynamic>;
    final conversation =
        Map<String, dynamic>.from(conversations.single as Map);
    conversation['timeline'] = List.generate(30, (index) {
      final time = DateTime.utc(2026, 9, 25, 10)
          .add(Duration(minutes: index))
          .toIso8601String();
      return {
        'type': 'inbound',
        'time': time,
        'id': 'message-$index',
        'messageType': 'text',
        'textBody': 'message $index',
        'fileName': null,
        'mimeType': null,
        'mediaSizeBytes': null,
        'storageAvailable': false,
        'processingStatus': 'stored',
      };
    });
    conversation['latestReceivedAt'] = '2026-09-25T10:29:00.000Z';
    conversations[0] = conversation;

    final controller = AppController();
    controller.data = BootstrapData.fromJson(payload);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationScreen(
          controller: controller,
          conversationKey: 'abc',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('message 29'), findsOneWidget);
    expect(find.text('message 0'), findsNothing);
  });

}
