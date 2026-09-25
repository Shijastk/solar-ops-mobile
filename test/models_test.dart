import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/models.dart';

void main() {
  test('bootstrap parser preserves empty real-data states', () {
    final data = BootstrapData.fromJson({
      'apiVersion': 'v1',
      'generatedAt': '2026-09-25T10:00:00.000Z',
      'sessionExpiresAt': null,
      'runtime': {
        'healthy': true,
        'automationEnabled': false,
        'automationReady': false,
      },
      'dashboard': {
        'billsToday': 0,
        'totalBills': 0,
        'pendingReview': 0,
        'recorded': 0,
        'inboundMessages': 6,
        'stockProducts': 0,
        'totalStockQuantity': 0,
        'dailyBills': [],
      },
      'bills': [],
      'dispatches': [],
      'stock': {'companies': [], 'balances': []},
    });

    expect(data.bills, isEmpty);
    expect(data.dispatches, isEmpty);
    expect(data.stock.balances, isEmpty);
    expect(data.dashboard.inboundMessages, 6);
    expect(data.sessionExpiresAt, isNull);
  });

  test('bill parser accepts a PDF without a parsed draft', () {
    final data = BootstrapData.fromJson({
      'apiVersion': 'v1',
      'generatedAt': '2026-09-25T10:00:00.000Z',
      'runtime': {
        'healthy': true,
        'automationEnabled': true,
        'automationReady': true,
      },
      'dashboard': {
        'billsToday': 1,
        'totalBills': 1,
        'pendingReview': 0,
        'recorded': 0,
        'inboundMessages': 1,
        'stockProducts': 0,
        'totalStockQuantity': 0,
        'dailyBills': [],
      },
      'bills': [
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'fileName': 'bill.pdf',
          'storageAvailable': true,
          'processingStatus': 'stored',
          'receivedAt': '2026-09-25T09:00:00.000Z',
          'senderPhoneMasked': '•••• 0001',
          'draft': null,
        }
      ],
      'dispatches': [],
      'stock': {'companies': [], 'balances': []},
    });

    expect(data.bills.single.fileName, 'bill.pdf');
    expect(data.bills.single.draft, isNull);
    expect(data.dispatches, isEmpty);
  });
}
