import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class SessionResponse {
  const SessionResponse({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;
}

class SolarOpsApi {
  SolarOpsApi({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'SOLAR_OPS_API_BASE_URL',
    defaultValue: 'https://solar-ops-whatsapp.vercel.app',
  );

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<SessionResponse> createSession(String accessKey) async {
    final response = await _client
        .post(
          _uri('/api/mobile/v1/session'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'accessKey': accessKey}),
        )
        .timeout(const Duration(seconds: 20));

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(body, 'Unable to sign in'),
        statusCode: response.statusCode,
      );
    }

    final token = body['token']?.toString();
    final expiresAt = DateTime.tryParse(body['expiresAt']?.toString() ?? '');
    if (token == null || token.isEmpty || expiresAt == null) {
      throw const ApiException('Server returned an invalid session');
    }

    return SessionResponse(token: token, expiresAt: expiresAt);
  }

  Future<BootstrapData> bootstrap(String token) async {
    final response = await _client
        .get(_uri('/api/mobile/v1/home'), headers: _authorized(token))
        .timeout(const Duration(seconds: 25));

    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(body, 'Unable to load operations data'),
        statusCode: response.statusCode,
      );
    }

    return BootstrapData.fromJson(body);
  }

  Future<List<Conversation>> conversations(String token) async {
    final response = await _client
        .get(_uri('/api/mobile/v1/bootstrap'), headers: _authorized(token))
        .timeout(const Duration(seconds: 25));
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(body, 'Could not load WhatsApp'),
        statusCode: response.statusCode,
      );
    }
    return BootstrapData.fromJson(body).conversations;
  }

  Future<Map<String, dynamic>> operation(
    String token,
    Map<String, dynamic> payload,
  ) =>
      _postAuthorized(token, '/api/mobile/v1/operations', payload);
  Future<void> editBill(String token, Map<String, dynamic> payload) async {
    await _postAuthorized(token, '/api/mobile/v1/bill', payload);
  }

  Future<String> uploadBill(
    String token,
    String name,
    Uint8List bytes, {
    String? tripId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/mobile/v1/upload'),
    );
    request.headers.addAll(_authorized(token));
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: name),
    );
    if (tripId != null) request.fields['tripId'] = tripId;
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(const Duration(seconds: 75)),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(body, 'Could not upload'),
        statusCode: response.statusCode,
      );
    }
    return body['message']?.toString() ?? 'Bill saved';
  }

  Future<Bill> billDetails(String token, String id) async {
    final response = await _client
        .get(_uri('/api/mobile/v1/bills').replace(queryParameters: {'id': id}),
            headers: _authorized(token))
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(body, 'Bill unavailable'),
          statusCode: response.statusCode);
    }
    return Bill.fromJson(body);
  }

  Future<List<Bill>> searchBills(
      String token, String query, String? companyId) async {
    final response = await _client
        .get(
            _uri('/api/mobile/v1/bills').replace(queryParameters: {
              'q': query,
              if (companyId != null) 'companyId': companyId
            }),
            headers: _authorized(token))
        .timeout(const Duration(seconds: 25));
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(body, 'Could not search bills'),
          statusCode: response.statusCode);
    }
    return (body['bills'] as List? ?? [])
        .whereType<Map>()
        .map((b) => Bill.fromJson(Map<String, dynamic>.from(b)))
        .toList();
  }

  Future<void> parseBill(String token, String messageId) async {
    await _postAuthorized(
      token,
      '/api/mobile/v1/messages/$messageId/parse',
      const {},
    );
  }

  Future<void> approveBill(String token, String messageId) async {
    await _postAuthorized(
      token,
      '/api/mobile/v1/messages/$messageId/approve',
      const {},
    );
  }

  Future<Uri> mediaUrl(String token, String messageId) async {
    final response = await _client
        .get(
          _uri('/api/mobile/v1/messages/$messageId/media'),
          headers: _authorized(token),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _errorMessage(body, 'Unable to open file'),
        statusCode: response.statusCode,
      );
    }

    final url = Uri.tryParse(body['url']?.toString() ?? '');
    if (url == null) throw const ApiException('Invalid file URL');
    return url;
  }

  Future<void> adjustStock({
    required String token,
    required String productId,
    required double targetQuantity,
  }) async {
    await _postAuthorized(token, '/api/mobile/v1/stock/adjust', {
      'productId': productId,
      'targetQuantity': targetQuantity,
    });
  }

  Future<void> addOpeningStock({
    required String token,
    String? companyId,
    String? companyName,
    String? companyGstin,
    required String productName,
    required String unit,
    String? hsnSac,
    required double quantity,
    bool allowSimilarCompany = false,
    bool allowSimilarProduct = false,
  }) async {
    await _postAuthorized(token, '/api/mobile/v1/stock/opening', {
      'companyId': companyId,
      'companyName': companyName,
      'companyGstin': companyGstin,
      'productName': productName,
      'unit': unit,
      'hsnSac': hsnSac,
      'quantity': quantity,
      'allowSimilarCompany': allowSimilarCompany,
      'allowSimilarProduct': allowSimilarProduct,
    });
  }

  Future<void> sendReply({
    required String token,
    required String messageId,
    required String body,
  }) async {
    await _postAuthorized(token, '/api/mobile/v1/messages/$messageId/reply', {
      'body': body,
    });
  }

  Future<Map<String, dynamic>> _postAuthorized(
    String token,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client
        .post(
          _uri(path),
          headers: {..._authorized(token), 'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(body, 'Request failed'),
        statusCode: response.statusCode,
        code: body['code']?.toString(),
      );
    }
    return body;
  }

  Map<String, String> _authorized(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) =>
      body['error']?.toString().trim().isNotEmpty == true
          ? body['error'].toString()
          : fallback;

  void dispose() => _client.close();
}
