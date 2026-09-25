import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get unauthorized => statusCode == 401;

  @override
  String toString() => message;
}

abstract class OpsRepository {
  String get baseUrl;

  Future<SessionData> login(String accessKey);
  Future<BootstrapData> bootstrap(String token);
  Future<void> parseBill(String token, String messageId);
  Future<void> approveBill(String token, String messageId);
  Future<String> mediaUrl(String token, String messageId);
  Future<Map<String, dynamic>> addOpeningStock(
    String token,
    Map<String, dynamic> body,
  );
  Future<Map<String, dynamic>> adjustStock(
    String token,
    Map<String, dynamic> body,
  );
}

class OpsApiClient implements OpsRepository {
  OpsApiClient({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ??
                const String.fromEnvironment(
                  'SOLAR_OPS_API_BASE',
                  defaultValue:
                      'https://solar-ops-whatsapp.vercel.app/api/mobile/v1',
                ))
            .replaceFirst(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  @override
  String get baseUrl => _baseUrl;

  Uri _uri(String path) => Uri.parse(_baseUrl + path);

  Map<String, String> _headers(String token) => {
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Handled below as a bounded API error.
    }
    throw ApiException(
      'The server returned an invalid response.',
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {
      // Use the bounded fallback below.
    }
    return response.statusCode == 401
        ? 'Your session is no longer valid.'
        : 'The operation could not be completed.';
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<SessionData> login(String accessKey) async {
    final response = await _client.post(
      _uri('/session'),
      headers: const {
        'accept': 'application/json',
        'content-type': 'application/json',
      },
      body: jsonEncode({'accessKey': accessKey}),
    );
    _requireSuccess(response);
    return SessionData.fromJson(_decodeObject(response));
  }

  @override
  Future<BootstrapData> bootstrap(String token) async {
    final response = await _client.get(
      _uri('/bootstrap'),
      headers: _headers(token),
    );
    _requireSuccess(response);
    return BootstrapData.fromJson(_decodeObject(response));
  }

  Future<Map<String, dynamic>> _post(
    String token,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );
    _requireSuccess(response);
    return _decodeObject(response);
  }

  @override
  Future<void> parseBill(String token, String messageId) async {
    await _post(token, '/messages/$messageId/parse');
  }

  @override
  Future<void> approveBill(String token, String messageId) async {
    await _post(token, '/messages/$messageId/approve');
  }

  @override
  Future<String> mediaUrl(String token, String messageId) async {
    final response = await _client.get(
      _uri('/messages/$messageId/media'),
      headers: _headers(token),
    );
    _requireSuccess(response);
    final object = _decodeObject(response);
    final url = object['url'];
    if (url is! String || url.isEmpty) {
      throw const ApiException('The PDF URL was not returned by the server.');
    }
    return url;
  }

  @override
  Future<Map<String, dynamic>> addOpeningStock(
    String token,
    Map<String, dynamic> body,
  ) =>
      _post(token, '/stock/opening', body);

  @override
  Future<Map<String, dynamic>> adjustStock(
    String token,
    Map<String, dynamic> body,
  ) =>
      _post(token, '/stock/adjust', body);
}
