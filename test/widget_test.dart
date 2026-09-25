
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solar_ops_mobile/api_client.dart';
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
        'companyName': 'Supplier Pvt Ltd',
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
    expect(data.bills.single.draft?.items.single.quantity, 10);
    expect(data.stock.balances.single.currentQuantity, 42);
    expect(data.conversations.single.canReply, isTrue);
    expect(data.dispatches.single.vehicleNumber, 'KL11AA1234');
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
}
