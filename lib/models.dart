class SessionData {
  const SessionData({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  factory SessionData.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final expiresAt = json['expiresAt'];
    if (token is! String || expiresAt is! String) {
      throw const FormatException('Invalid session response');
    }
    return SessionData(token: token, expiresAt: DateTime.parse(expiresAt));
  }
}

double? _doubleOrNull(dynamic value) {
  if (value == null) return null;
  return value is num ? value.toDouble() : double.tryParse(value.toString());
}

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value.toString()) ?? 0;

String? _stringOrNull(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

Map<String, dynamic>? _mapOrNull(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

List<dynamic> _listValue(dynamic value) =>
    value is List ? List<dynamic>.from(value) : const [];

class RuntimeInfo {
  const RuntimeInfo({
    required this.healthy,
    required this.automationEnabled,
    required this.automationReady,
  });

  final bool healthy;
  final bool automationEnabled;
  final bool automationReady;

  factory RuntimeInfo.fromJson(Map<String, dynamic> json) => RuntimeInfo(
        healthy: json['healthy'] == true,
        automationEnabled: json['automationEnabled'] == true,
        automationReady: json['automationReady'] == true,
      );
}

class DailyBill {
  const DailyBill({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;

  factory DailyBill.fromJson(Map<String, dynamic> json) => DailyBill(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        count: _intValue(json['count']),
      );
}

class DashboardData {
  const DashboardData({
    required this.billsToday,
    required this.totalBills,
    required this.pendingReview,
    required this.recorded,
    required this.inboundMessages,
    required this.stockProducts,
    required this.totalStockQuantity,
    required this.dailyBills,
  });

  final int billsToday;
  final int totalBills;
  final int pendingReview;
  final int recorded;
  final int inboundMessages;
  final int stockProducts;
  final double totalStockQuantity;
  final List<DailyBill> dailyBills;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        billsToday: _intValue(json['billsToday']),
        totalBills: _intValue(json['totalBills']),
        pendingReview: _intValue(json['pendingReview']),
        recorded: _intValue(json['recorded']),
        inboundMessages: _intValue(json['inboundMessages']),
        stockProducts: _intValue(json['stockProducts']),
        totalStockQuantity: _doubleOrNull(json['totalStockQuantity']) ?? 0,
        dailyBills: _listValue(json['dailyBills'])
            .whereType<Map>()
            .map((item) => DailyBill.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class BillItem {
  const BillItem({
    required this.id,
    required this.lineIndex,
    required this.description,
    this.hsnSac,
    this.quantity,
    this.unit,
    this.rate,
    this.amount,
  });

  final String id;
  final int lineIndex;
  final String description;
  final String? hsnSac;
  final double? quantity;
  final String? unit;
  final double? rate;
  final double? amount;

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        id: (json['id'] ?? '').toString(),
        lineIndex: _intValue(json['lineIndex']),
        description: (json['description'] ?? '').toString(),
        hsnSac: _stringOrNull(json['hsnSac']),
        quantity: _doubleOrNull(json['quantity']),
        unit: _stringOrNull(json['unit']),
        rate: _doubleOrNull(json['rate']),
        amount: _doubleOrNull(json['amount']),
      );
}

class BillDraft {
  const BillDraft({
    required this.id,
    required this.parseStatus,
    required this.missingFields,
    required this.verificationStatus,
    required this.workflowStatus,
    required this.stockStatus,
    required this.items,
    this.documentType,
    this.supplierName,
    this.supplierGstin,
    this.supplierAddress,
    this.documentNumber,
    this.documentDate,
    this.ewayBillNumber,
    this.consigneeName,
    this.consigneeAddress,
    this.consigneeGstin,
    this.buyerName,
    this.buyerAddress,
    this.buyerGstin,
    this.destination,
    this.dispatchFromAddress,
    this.vehicleNumber,
    this.approximateDistanceKm,
    this.supplyType,
    this.transactionType,
    this.taxableAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.totalAmount,
    this.parseError,
    this.extractedAt,
    this.approvedAt,
    this.stockError,
    this.stockUpdatedAt,
  });

  final String id;
  final String parseStatus;
  final String? documentType;
  final String? supplierName;
  final String? supplierGstin;
  final String? supplierAddress;
  final String? documentNumber;
  final String? documentDate;
  final String? ewayBillNumber;
  final String? consigneeName;
  final String? consigneeAddress;
  final String? consigneeGstin;
  final String? buyerName;
  final String? buyerAddress;
  final String? buyerGstin;
  final String? destination;
  final String? dispatchFromAddress;
  final String? vehicleNumber;
  final double? approximateDistanceKm;
  final String? supplyType;
  final String? transactionType;
  final double? taxableAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? totalAmount;
  final List<String> missingFields;
  final String? parseError;
  final String? extractedAt;
  final String? approvedAt;
  final String verificationStatus;
  final String workflowStatus;
  final String stockStatus;
  final String? stockError;
  final String? stockUpdatedAt;
  final List<BillItem> items;

  factory BillDraft.fromJson(Map<String, dynamic> json) => BillDraft(
        id: (json['id'] ?? '').toString(),
        parseStatus: (json['parseStatus'] ?? 'unknown').toString(),
        documentType: _stringOrNull(json['documentType']),
        supplierName: _stringOrNull(json['supplierName']),
        supplierGstin: _stringOrNull(json['supplierGstin']),
        supplierAddress: _stringOrNull(json['supplierAddress']),
        documentNumber: _stringOrNull(json['documentNumber']),
        documentDate: _stringOrNull(json['documentDate']),
        ewayBillNumber: _stringOrNull(json['ewayBillNumber']),
        consigneeName: _stringOrNull(json['consigneeName']),
        consigneeAddress: _stringOrNull(json['consigneeAddress']),
        consigneeGstin: _stringOrNull(json['consigneeGstin']),
        buyerName: _stringOrNull(json['buyerName']),
        buyerAddress: _stringOrNull(json['buyerAddress']),
        buyerGstin: _stringOrNull(json['buyerGstin']),
        destination: _stringOrNull(json['destination']),
        dispatchFromAddress: _stringOrNull(json['dispatchFromAddress']),
        vehicleNumber: _stringOrNull(json['vehicleNumber']),
        approximateDistanceKm: _doubleOrNull(json['approximateDistanceKm']),
        supplyType: _stringOrNull(json['supplyType']),
        transactionType: _stringOrNull(json['transactionType']),
        taxableAmount: _doubleOrNull(json['taxableAmount']),
        cgstAmount: _doubleOrNull(json['cgstAmount']),
        sgstAmount: _doubleOrNull(json['sgstAmount']),
        totalAmount: _doubleOrNull(json['totalAmount']),
        missingFields: _listValue(json['missingFields'])
            .whereType<String>()
            .toList(growable: false),
        parseError: _stringOrNull(json['parseError']),
        extractedAt: _stringOrNull(json['extractedAt']),
        approvedAt: _stringOrNull(json['approvedAt']),
        verificationStatus:
            (json['verificationStatus'] ?? 'unknown').toString(),
        workflowStatus: (json['workflowStatus'] ?? 'unknown').toString(),
        stockStatus: (json['stockStatus'] ?? 'unknown').toString(),
        stockError: _stringOrNull(json['stockError']),
        stockUpdatedAt: _stringOrNull(json['stockUpdatedAt']),
        items: _listValue(json['items'])
            .whereType<Map>()
            .map((item) => BillItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class BillRecord {
  const BillRecord({
    required this.id,
    required this.fileName,
    required this.storageAvailable,
    required this.processingStatus,
    required this.receivedAt,
    required this.senderPhoneMasked,
    this.mimeType,
    this.mediaSizeBytes,
    this.senderName,
    this.draft,
  });

  final String id;
  final String fileName;
  final String? mimeType;
  final int? mediaSizeBytes;
  final bool storageAvailable;
  final String processingStatus;
  final DateTime receivedAt;
  final String? senderName;
  final String senderPhoneMasked;
  final BillDraft? draft;

  factory BillRecord.fromJson(Map<String, dynamic> json) {
    final draft = _mapOrNull(json['draft']);
    return BillRecord(
      id: (json['id'] ?? '').toString(),
      fileName: (json['fileName'] ?? 'WhatsApp PDF').toString(),
      mimeType: _stringOrNull(json['mimeType']),
      mediaSizeBytes: json['mediaSizeBytes'] == null
          ? null
          : _intValue(json['mediaSizeBytes']),
      storageAvailable: json['storageAvailable'] == true,
      processingStatus: (json['processingStatus'] ?? 'unknown').toString(),
      receivedAt: DateTime.parse(json['receivedAt'].toString()),
      senderName: _stringOrNull(json['senderName']),
      senderPhoneMasked: (json['senderPhoneMasked'] ?? '••••').toString(),
      draft: draft == null ? null : BillDraft.fromJson(draft),
    );
  }
}

class DispatchRecord {
  const DispatchRecord({
    required this.billId,
    required this.fileName,
    required this.receivedAt,
    required this.workflowStatus,
    required this.stockStatus,
    this.documentNumber,
    this.companyName,
    this.destination,
    this.consigneeName,
    this.vehicleNumber,
  });

  final String billId;
  final String fileName;
  final DateTime receivedAt;
  final String? documentNumber;
  final String? companyName;
  final String? destination;
  final String? consigneeName;
  final String? vehicleNumber;
  final String workflowStatus;
  final String stockStatus;

  factory DispatchRecord.fromJson(Map<String, dynamic> json) => DispatchRecord(
        billId: (json['billId'] ?? '').toString(),
        fileName: (json['fileName'] ?? 'WhatsApp PDF').toString(),
        receivedAt: DateTime.parse(json['receivedAt'].toString()),
        documentNumber: _stringOrNull(json['documentNumber']),
        companyName: _stringOrNull(json['companyName']),
        destination: _stringOrNull(json['destination']),
        consigneeName: _stringOrNull(json['consigneeName']),
        vehicleNumber: _stringOrNull(json['vehicleNumber']),
        workflowStatus: (json['workflowStatus'] ?? 'unknown').toString(),
        stockStatus: (json['stockStatus'] ?? 'unknown').toString(),
      );
}

class StockCompany {
  const StockCompany({
    required this.id,
    required this.name,
    required this.gstin,
  });

  final String id;
  final String name;
  final String gstin;

  factory StockCompany.fromJson(Map<String, dynamic> json) => StockCompany(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        gstin: (json['gstin'] ?? '').toString(),
      );
}

class StockBalance {
  const StockBalance({
    required this.productId,
    required this.companyId,
    required this.companyName,
    required this.companyGstin,
    required this.productName,
    required this.unit,
    required this.currentQuantity,
    this.hsnSac,
  });

  final String productId;
  final String companyId;
  final String companyName;
  final String companyGstin;
  final String productName;
  final String unit;
  final String? hsnSac;
  final double currentQuantity;

  factory StockBalance.fromJson(Map<String, dynamic> json) => StockBalance(
        productId: (json['productId'] ?? '').toString(),
        companyId: (json['companyId'] ?? '').toString(),
        companyName: (json['companyName'] ?? '').toString(),
        companyGstin: (json['companyGstin'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        unit: (json['unit'] ?? '').toString(),
        hsnSac: _stringOrNull(json['hsnSac']),
        currentQuantity: _doubleOrNull(json['currentQuantity']) ?? 0,
      );
}

class StockData {
  const StockData({required this.companies, required this.balances});

  final List<StockCompany> companies;
  final List<StockBalance> balances;

  factory StockData.fromJson(Map<String, dynamic> json) => StockData(
        companies: _listValue(json['companies'])
            .whereType<Map>()
            .map((item) =>
                StockCompany.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
        balances: _listValue(json['balances'])
            .whereType<Map>()
            .map((item) =>
                StockBalance.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class BootstrapData {
  const BootstrapData({
    required this.apiVersion,
    required this.generatedAt,
    required this.runtime,
    required this.dashboard,
    required this.bills,
    required this.dispatches,
    required this.stock,
    required this.sessionExpiresAt,
  });

  final String apiVersion;
  final DateTime generatedAt;
  final RuntimeInfo runtime;
  final DashboardData dashboard;
  final List<BillRecord> bills;
  final List<DispatchRecord> dispatches;
  final StockData stock;
  final DateTime? sessionExpiresAt;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    final runtime = _mapOrNull(json['runtime']) ?? const <String, dynamic>{};
    final dashboard =
        _mapOrNull(json['dashboard']) ?? const <String, dynamic>{};
    final stock = _mapOrNull(json['stock']) ?? const <String, dynamic>{};
    final expiry = _stringOrNull(json['sessionExpiresAt']);

    return BootstrapData(
      apiVersion: (json['apiVersion'] ?? 'v1').toString(),
      generatedAt: DateTime.parse(json['generatedAt'].toString()),
      runtime: RuntimeInfo.fromJson(runtime),
      dashboard: DashboardData.fromJson(dashboard),
      bills: _listValue(json['bills'])
          .whereType<Map>()
          .map((item) => BillRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      dispatches: _listValue(json['dispatches'])
          .whereType<Map>()
          .map((item) =>
              DispatchRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      stock: StockData.fromJson(stock),
      sessionExpiresAt: expiry == null ? null : DateTime.parse(expiry),
    );
  }
}
