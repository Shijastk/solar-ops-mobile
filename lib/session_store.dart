import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  const StoredSession({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;

  bool get isValid =>
      expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 1)));
}

class SessionStore {
  static const _tokenKey = 'solar_ops_session_token';
  static const _expiresKey = 'solar_ops_session_expires_at';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<StoredSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _tokenKey),
      _storage.read(key: _expiresKey),
    ]);
    final token = values[0];
    final expiresAt = DateTime.tryParse(values[1] ?? '');
    if (token == null || token.isEmpty || expiresAt == null) return null;
    return StoredSession(token: token, expiresAt: expiresAt);
  }

  Future<void> save(String token, DateTime expiresAt) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _expiresKey, value: expiresAt.toIso8601String()),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _expiresKey),
    ]);
  }
}
