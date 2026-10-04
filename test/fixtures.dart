Map<String, dynamic> sampleData() => {
      'generatedAt': DateTime.now().toIso8601String(),
      'drivers': [
        {'id': 'driver-a', 'name': 'Driver A'}
      ],
      'tripActivity': {
        'today': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 5, minutes: 30))
            .toIso8601String()
            .substring(0, 10),
        'pending': [
          {'companyId': null, 'count': 2},
          {'companyId': 'a', 'count': 1},
          {'companyId': 'b', 'count': 1}
        ],
        'daily': []
      },
      'todayTotals': [
        {'companyId': 'a', 'billCount': 1, 'totalAmount': 100},
        {'companyId': 'b', 'billCount': 1, 'totalAmount': 200}
      ],
      'stock': {
        'companies': [
          {
            'id': 'a',
            'name': 'First Solar Company Limited',
            'gstin': '32AAAAA0000A1Z5'
          },
          {
            'id': 'b',
            'name': 'Second Solar Company Limited',
            'gstin': '33AAAAA0000A1Z5'
          }
        ],
        'balances': [
          {
            'productId': 'p1',
            'companyId': 'a',
            'companyName': 'First Solar Company Limited',
            'productName': 'First panel',
            'unit': 'NOS',
            'currentQuantity': 7,
            'balanceKnown': true
          },
          {
            'productId': 'p2',
            'companyId': 'b',
            'companyName': 'Second Solar Company Limited',
            'productName': 'Second panel',
            'unit': 'NOS',
            'currentQuantity': 12,
            'balanceKnown': true
          },
        ]
      },
      'trips': [
        {
          'id': 't1',
          'companyId': 'a',
          'name': 'Tirur',
          'status': 'ready',
          'driverName': 'Driver A',
          'bills': [
            {'messageId': 'b1', 'number': 'INV-1', 'companyId': 'a'}
          ]
        },
        {
          'id': 't2',
          'companyId': 'b',
          'name': 'Palakkad',
          'status': 'collecting',
          'bills': [
            {'messageId': 'b2', 'number': 'INV-2', 'companyId': 'b'}
          ]
        }
      ],
      'bills': [
        {
          'id': 'b1',
          'companyId': 'a',
          'fileName': 'first.pdf',
          'receivedAt': DateTime.now().toIso8601String(),
          'draft': {
            'id': 'd1',
            'documentNumber': 'INV-1',
            'consigneeName': 'First customer',
            'totalAmount': 100,
            'workflowStatus': 'recorded',
            'stockStatus': 'applied',
            'items': []
          }
        },
        {
          'id': 'b2',
          'companyId': 'b',
          'fileName': 'second.pdf',
          'draft': {
            'id': 'd2',
            'documentNumber': 'INV-2',
            'totalAmount': 200,
            'items': []
          }
        }
      ],
    };
