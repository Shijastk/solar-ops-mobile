import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/api.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/main.dart';
import 'package:solar_ops_mobile/models.dart';
import 'package:solar_ops_mobile/session_store.dart';

class FakeOpsRepository implements OpsRepository {
  FakeOpsRepository(this.data);

  BootstrapData data;
  bool invalidLogin = false;

  @override
  String get baseUrl => 'https://example.test/api/mobile/v1';

  @override
  Future<SessionData> login(String accessKey) async {
    if (invalidLogin || accessKey != 'valid-key') {
      throw const ApiException('Invalid access key', statusCode: 401);
    }
    return SessionData(
      token: 'signed-session',
      expiresAt: DateTime.now().add(const Duration(hours: 8)),
    );
  }

  @override
  Future<BootstrapData> bootstrap(String token) async => data;

  @override
  Future<Map<String, dynamic>> addOpeningStock(
    String token,
    Map<String, dynamic> body,
  ) async =>
      {'status': 'opening_created'};

  @override
  Future<void> approveBill(String token, String messageId) async {}

  @override
  Future<Map<String, dynamic>> adjustStock(
    String token,
    Map<String, dynamic> body,
  ) async =>
      {'status': 'adjusted'};

  @override
  Future<String> mediaUrl(String token, String messageId) async =>
      'https://example.test/bill.pdf';

  @override
  Future<void> parseBill(String token, String messageId) async {}
}

class FakeSessionStore implements SessionStore {
  FakeSessionStore(this.session);

  SessionData? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<SessionData?> read() async => session;

  @override
  Future<void> write(SessionData value) async => session = value;
}

BootstrapData fixture({bool includeDispatch = true}) {
  return BootstrapData.fromJson({
    'apiVersion': 'v1',
    'generatedAt': '2026-09-25T10:00:00.000Z',
    'sessionExpiresAt': '2026-09-25T18:00:00.000Z',
    'runtime': {
      'healthy': true,
      'automationEnabled': true,
      'automationReady': true,
    },
    'dashboard': {
      'billsToday': 1,
      'totalBills': 1,
      'pendingReview': 0,
      'recorded': includeDispatch ? 1 : 0,
      'inboundMessages': 6,
      'stockProducts': 1,
      'totalStockQuantity': 134,
      'dailyBills': [
        {'key': '2026-09-19', 'label': 'Fri', 'count': 0},
        {'key': '2026-09-20', 'label': 'Sat', 'count': 0},
        {'key': '2026-09-21', 'label': 'Sun', 'count': 0},
        {'key': '2026-09-22', 'label': 'Mon', 'count': 0},
        {'key': '2026-09-23', 'label': 'Tue', 'count': 0},
        {'key': '2026-09-24', 'label': 'Wed', 'count': 0},
        {'key': '2026-09-25', 'label': 'Thu', 'count': 1},
      ],
    },
    'bills': [
      {
        'id': '11111111-1111-4111-8111-111111111111',
        'fileName': 'real-bill.pdf',
        'mimeType': 'application/pdf',
        'mediaSizeBytes': 2048,
        'storageAvailable': true,
        'processingStatus': 'stored',
        'receivedAt': '2026-09-25T09:30:00.000Z',
        'senderName': 'Supplier',
        'senderPhoneMasked': '•••• 3210',
        'draft': includeDispatch
            ? {
                'id': '22222222-2222-4222-8222-222222222222',
                'parseStatus': 'approved',
                'documentType': 'tax_invoice',
                'supplierName': 'Real Solar Supplier',
                'supplierGstin': '32ABCDE1234F1Z5',
                'documentNumber': 'INV-REAL-001',
                'documentDate': '2026-09-25',
                'ewayBillNumber': '123456789012',
                'consigneeName': 'Solar Godown',
                'destination': 'Kozhikode',
                'vehicleNumber': 'KL 11 AB 1234',
                'totalAmount': 25000,
                'missingFields': [],
                'verificationStatus': 'verified',
                'workflowStatus': 'recorded',
                'stockStatus': 'applied',
                'items': [
                  {
                    'id': '33333333-3333-4333-8333-333333333333',
                    'lineIndex': 0,
                    'description': 'Solar Panel 560W',
                    'hsnSac': '8541',
                    'quantity': 2,
                    'unit': 'NOS',
                    'rate': 12500,
                    'amount': 25000,
                  }
                ],
              }
            : null,
      }
    ],
    'dispatches': includeDispatch
        ? [
            {
              'billId': '11111111-1111-4111-8111-111111111111',
              'fileName': 'real-bill.pdf',
              'receivedAt': '2026-09-25T09:30:00.000Z',
              'documentNumber': 'INV-REAL-001',
              'companyName': 'Real Solar Supplier',
              'destination': 'Kozhikode',
              'consigneeName': 'Solar Godown',
              'vehicleNumber': 'KL 11 AB 1234',
              'workflowStatus': 'recorded',
              'stockStatus': 'applied',
            }
          ]
        : [],
    'stock': {
      'companies': [
        {
          'id': '44444444-4444-4444-8444-444444444444',
          'name': 'Real Solar Supplier',
          'gstin': '32ABCDE1234F1Z5',
        }
      ],
      'balances': [
        {
          'productId': '55555555-5555-4555-8555-555555555555',
          'companyId': '44444444-4444-4444-8444-444444444444',
          'companyName': 'Real Solar Supplier',
          'companyGstin': '32ABCDE1234F1Z5',
          'productName': 'Solar Panel 560W',
          'unit': 'NOS',
          'hsnSac': '8541',
          'currentQuantity': 134,
        }
      ],
    },
  });
}

AppController authenticatedController({bool includeDispatch = true}) {
  final session = SessionData(
    token: 'signed-session',
    expiresAt: DateTime.now().add(const Duration(hours: 8)),
  );
  return AppController(
    api: FakeOpsRepository(fixture(includeDispatch: includeDispatch)),
    sessionStore: FakeSessionStore(session),
  );
}

void main() {
  testWidgets('shows secure login when there is no saved session',
      (tester) async {
    final controller = AppController(
      api: FakeOpsRepository(fixture()),
      sessionStore: FakeSessionStore(null),
    );

    await tester.pumpWidget(SolarOpsApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Operations access key'), findsOneWidget);
    expect(find.text('Connect securely'), findsOneWidget);
    expect(find.text('Bills today'), findsNothing);
  });

  testWidgets('dashboard uses repository data instead of mock counters',
      (tester) async {
    final controller = authenticatedController();

    await tester.pumpWidget(SolarOpsApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Bills today'), findsOneWidget);
    expect(find.text('Needs review'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Recent bills'), findsOneWidget);
    expect(find.text('INV-REAL-001'), findsOneWidget);
  });

  testWidgets('all navigation screens render real repository content',
      (tester) async {
    final controller = authenticatedController();

    await tester.pumpWidget(SolarOpsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bills'));
    await tester.pumpAndSettle();
    expect(find.text('INV-REAL-001'), findsOneWidget);

    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();
    expect(find.text('KL 11 AB 1234'), findsOneWidget);
    expect(find.text('Kozhikode'), findsOneWidget);

    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Solar Panel 560W'), findsOneWidget);
    expect(find.text('134'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Backend connection'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);
    expect(find.text('Enabled · ready'), findsOneWidget);
  });

  testWidgets('dispatch shows truthful empty state without parsed drafts',
      (tester) async {
    final controller = authenticatedController(includeDispatch: false);

    await tester.pumpWidget(SolarOpsApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();

    expect(find.text('No parsed dispatch data'), findsOneWidget);
    expect(
      find.textContaining('No driver or delivery state is invented'),
      findsOneWidget,
    );
  });
}
