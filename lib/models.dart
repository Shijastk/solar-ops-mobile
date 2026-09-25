class BootstrapData {
  BootstrapData({
    required this.generatedAt,
    required this.sessionExpiresAt,
    required this.runtime,
    required this.dashboard,
    required this.bills,
    required this.dispatches,
    required this.stock,
    required this.conversations,
  });

  final DateTime generatedAt;
  final DateTime? sessionExpiresAt;
  final RuntimeStatus runtime;
  final DashboardData dashboard;
  final List<Bill> bills;
  final List<DispatchRecord> dispatches;
  final StockData stock;
  final List<Conversation> conversations;

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      generatedAt: DateTime.tryParse(_string(json['generatedAt']) ?? '') ??
          DateTime.now(),
      sessionExpiresAt:
          DateTime.tryParse(_string(json['sessionExpiresAt']) ?? ''),
      runtime: RuntimeStatus.fromJson(_map(json['runtime'])),
      dashboard: DashboardData.fromJson(_map(json['dashboard'])),
      bills: _list(json['bills'])
          .map((item) => Bill.fromJson(_map(item)))
          .toList(),
      dispatches: _list(json['dispatches'])
          .map((item) => DispatchRecord.fromJson(_map(item)))
          .toList(),
      stock: StockData.fromJson(_map(json['stock'])),
      conversations: _list(json['conversations'])
          .map((item) => Conversation.fromJson(_map(item)))
          .toList(),
    );
  }
}

class RuntimeStatus {
  const RuntimeStatus({
    required this.healthy,
    required this.automationEnabled,
    required this.automationReady,
  });

  final bool healthy;
  final bool automationEnabled;
  final bool automationReady;

  factory RuntimeStatus.fromJson(Map<String, dynamic> json) => RuntimeStatus(
        healthy: json['healthy'] == true,
        automationEnabled: json['automationEnabled'] == true,
        automationReady: json['automationReady'] == true,
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
  final List<DailyBillCount> dailyBills;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        billsToday: _int(json['billsToday']),
        totalBills: _int(json['totalBills']),
        pendingReview: _int(json['pendingReview']),
        recorded: _int(json['recorded']),
        inboundMessages: _int(json['inboundMessages']),
        stockProducts: _int(json['stockProducts']),
        totalStockQuantity: _double(json['totalStockQuantity']),
        dailyBills: _list(json['dailyBills'])
            .map((item) => DailyBillCount.fromJson(_map(item)))
            .toList(),
      );
}

class DailyBillCount {
  const DailyBillCount({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;

  factory DailyBillCount.fromJson(Map<String, dynamic> json) => DailyBillCount(
        key: _string(json['key']) ?? '',
        label: _string(json['label']) ?? '',
        count: _int(json['count']),
      );
}

class Bill {
  const Bill({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.mediaSizeBytes,
    required this.storageAvailable,
    required this.processingStatus,
    required this.receivedAt,
    required this.senderName,
    required this.senderPhoneMasked,
    required this.draft,
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
  final DocumentDraft? draft;

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
        id: _string(json['id']) ?? '',
        fileName: _string(json['fileName']) ?? 'WhatsApp PDF',
        mimeType: _string(json['mimeType']),
        mediaSizeBytes:
            json['mediaSizeBytes'] == null ? null : _int(json['mediaSizeBytes']),
        storageAvailable: json['storageAvailable'] == true,
        processingStatus: _string(json['processingStatus']) ?? 'unknown',
        receivedAt: DateTime.tryParse(_string(json['receivedAt']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        senderName: _string(json['senderName']),
        senderPhoneMasked: _string(json['senderPhoneMasked']) ?? '••••',
        draft: json['draft'] is Map
            ? DocumentDraft.fromJson(_map(json['draft']))
            : null,
      );
}

class DocumentDraft {
  const DocumentDraft({
    required this.id,
    required this.parseStatus,
    required this.documentType,
    required this.supplierName,
    required this.supplierGstin,
    required this.supplierAddress,
    required this.documentNumber,
    required this.documentDate,
    required this.ewayBillNumber,
    required this.consigneeName,
    required this.consigneeAddress,
    required this.consigneeGstin,
    required this.buyerName,
    required this.buyerAddress,
    required this.buyerGstin,
    required this.destination,
    required this.dispatchFromAddress,
    required this.vehicleNumber,
    required this.approximateDistanceKm,
    required this.supplyType,
    required this.transactionType,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalAmount,
    required this.missingFields,
    required this.parseError,
    required this.extractedAt,
    required this.approvedAt,
    required this.verificationStatus,
    required this.workflowStatus,
    required this.stockStatus,
    required this.stockError,
    required this.stockUpdatedAt,
    required this.items,
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
  final DateTime? extractedAt;
  final DateTime? approvedAt;
  final String verificationStatus;
  final String workflowStatus;
  final String stockStatus;
  final String? stockError;
  final DateTime? stockUpdatedAt;
  final List<DocumentItem> items;

  bool get canApprove =>
      parseStatus == 'ready_for_review' && workflowStatus != 'cancelled';

  factory DocumentDraft.fromJson(Map<String, dynamic> json) => DocumentDraft(
        id: _string(json['id']) ?? '',
        parseStatus: _string(json['parseStatus']) ?? 'unknown',
        documentType: _string(json['documentType']),
        supplierName: _string(json['supplierName']),
        supplierGstin: _string(json['supplierGstin']),
        supplierAddress: _string(json['supplierAddress']),
        documentNumber: _string(json['documentNumber']),
        documentDate: _string(json['documentDate']),
        ewayBillNumber: _string(json['ewayBillNumber']),
        consigneeName: _string(json['consigneeName']),
        consigneeAddress: _string(json['consigneeAddress']),
        consigneeGstin: _string(json['consigneeGstin']),
        buyerName: _string(json['buyerName']),
        buyerAddress: _string(json['buyerAddress']),
        buyerGstin: _string(json['buyerGstin']),
        destination: _string(json['destination']),
        dispatchFromAddress: _string(json['dispatchFromAddress']),
        vehicleNumber: _string(json['vehicleNumber']),
        approximateDistanceKm: _nullableDouble(json['approximateDistanceKm']),
        supplyType: _string(json['supplyType']),
        transactionType: _string(json['transactionType']),
        taxableAmount: _nullableDouble(json['taxableAmount']),
        cgstAmount: _nullableDouble(json['cgstAmount']),
        sgstAmount: _nullableDouble(json['sgstAmount']),
        totalAmount: _nullableDouble(json['totalAmount']),
        missingFields:
            _list(json['missingFields']).map((e) => e.toString()).toList(),
        parseError: _string(json['parseError']),
        extractedAt: DateTime.tryParse(_string(json['extractedAt']) ?? ''),
        approvedAt: DateTime.tryParse(_string(json['approvedAt']) ?? ''),
        verificationStatus:
            _string(json['verificationStatus']) ?? 'unknown',
        workflowStatus: _string(json['workflowStatus']) ?? 'unknown',
        stockStatus: _string(json['stockStatus']) ?? 'unknown',
        stockError: _string(json['stockError']),
        stockUpdatedAt:
            DateTime.tryParse(_string(json['stockUpdatedAt']) ?? ''),
        items: _list(json['items'])
            .map((item) => DocumentItem.fromJson(_map(item)))
            .toList(),
      );
}

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.lineIndex,
    required this.description,
    required this.hsnSac,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  final String id;
  final int lineIndex;
  final String description;
  final String? hsnSac;
  final double? quantity;
  final String? unit;
  final double? rate;
  final double? amount;

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
        id: _string(json['id']) ?? '',
        lineIndex: _int(json['lineIndex']),
        description: _string(json['description']) ?? 'Product',
        hsnSac: _string(json['hsnSac']),
        quantity: _nullableDouble(json['quantity']),
        unit: _string(json['unit']),
        rate: _nullableDouble(json['rate']),
        amount: _nullableDouble(json['amount']),
      );
}

class DispatchRecord {
  const DispatchRecord({
    required this.billId,
    required this.fileName,
    required this.receivedAt,
    required this.documentNumber,
    required this.companyName,
    required this.destination,
    required this.consigneeName,
    required this.vehicleNumber,
    required this.workflowStatus,
    required this.stockStatus,
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
        billId: _string(json['billId']) ?? '',
        fileName: _string(json['fileName']) ?? 'WhatsApp PDF',
        receivedAt: DateTime.tryParse(_string(json['receivedAt']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        documentNumber: _string(json['documentNumber']),
        companyName: _string(json['companyName']),
        destination: _string(json['destination']),
        consigneeName: _string(json['consigneeName']),
        vehicleNumber: _string(json['vehicleNumber']),
        workflowStatus: _string(json['workflowStatus']) ?? 'unknown',
        stockStatus: _string(json['stockStatus']) ?? 'unknown',
      );
}

class StockData {
  const StockData({required this.companies, required this.balances});

  final List<StockCompany> companies;
  final List<StockBalance> balances;

  factory StockData.fromJson(Map<String, dynamic> json) => StockData(
        companies: _list(json['companies'])
            .map((item) => StockCompany.fromJson(_map(item)))
            .toList(),
        balances: _list(json['balances'])
            .map((item) => StockBalance.fromJson(_map(item)))
            .toList(),
      );
}

class StockCompany {
  const StockCompany({required this.id, required this.name, required this.gstin});

  final String id;
  final String name;
  final String? gstin;

  factory StockCompany.fromJson(Map<String, dynamic> json) => StockCompany(
        id: _string(json['id']) ?? '',
        name: _string(json['name']) ?? 'Company',
        gstin: _string(json['gstin']),
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
    required this.hsnSac,
    required this.currentQuantity,
  });

  final String productId;
  final String companyId;
  final String companyName;
  final String? companyGstin;
  final String productName;
  final String unit;
  final String? hsnSac;
  final double currentQuantity;

  factory StockBalance.fromJson(Map<String, dynamic> json) => StockBalance(
        productId: _string(json['productId']) ?? '',
        companyId: _string(json['companyId']) ?? '',
        companyName: _string(json['companyName']) ?? 'Company',
        companyGstin: _string(json['companyGstin']),
        productName: _string(json['productName']) ?? 'Product',
        unit: _string(json['unit']) ?? '',
        hsnSac: _string(json['hsnSac']),
        currentQuantity: _double(json['currentQuantity']),
      );
}

class Conversation {
  const Conversation({
    required this.key,
    required this.senderName,
    required this.senderPhoneMasked,
    required this.latestReceivedAt,
    required this.latestInboundMessageId,
    required this.canReply,
    required this.timeline,
  });

  final String key;
  final String? senderName;
  final String senderPhoneMasked;
  final DateTime latestReceivedAt;
  final String? latestInboundMessageId;
  final bool canReply;
  final List<ConversationEvent> timeline;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        key: _string(json['key']) ?? '',
        senderName: _string(json['senderName']),
        senderPhoneMasked: _string(json['senderPhoneMasked']) ?? '••••',
        latestReceivedAt:
            DateTime.tryParse(_string(json['latestReceivedAt']) ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        latestInboundMessageId: _string(json['latestInboundMessageId']),
        canReply: json['canReply'] == true,
        timeline: _list(json['timeline'])
            .map((item) => ConversationEvent.fromJson(_map(item)))
            .toList(),
      );
}

class ConversationEvent {
  const ConversationEvent({
    required this.type,
    required this.time,
    required this.id,
    required this.messageType,
    required this.textBody,
    required this.fileName,
    required this.mimeType,
    required this.mediaSizeBytes,
    required this.storageAvailable,
    required this.processingStatus,
    required this.body,
    required this.status,
    required this.errorMessage,
  });

  final String type;
  final DateTime time;
  final String id;
  final String? messageType;
  final String? textBody;
  final String? fileName;
  final String? mimeType;
  final int? mediaSizeBytes;
  final bool storageAvailable;
  final String? processingStatus;
  final String? body;
  final String? status;
  final String? errorMessage;

  bool get inbound => type == 'inbound';

  factory ConversationEvent.fromJson(Map<String, dynamic> json) =>
      ConversationEvent(
        type: _string(json['type']) ?? 'inbound',
        time: DateTime.tryParse(_string(json['time']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        id: _string(json['id']) ?? '',
        messageType: _string(json['messageType']),
        textBody: _string(json['textBody']),
        fileName: _string(json['fileName']),
        mimeType: _string(json['mimeType']),
        mediaSizeBytes:
            json['mediaSizeBytes'] == null ? null : _int(json['mediaSizeBytes']),
        storageAvailable: json['storageAvailable'] == true,
        processingStatus: _string(json['processingStatus']),
        body: _string(json['body']),
        status: _string(json['status']),
        errorMessage: _string(json['errorMessage']),
      );
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String? _string(dynamic value) => value?.toString();

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
