import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

abstract class SessionStore {
  Future<SessionData?> read();
  Future<void> write(SessionData session);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'solar_ops_session_token';
  static const _expiryKey = 'solar_ops_session_expiry';

  final FlutterSecureStorage _storage;

  @override
  Future<SessionData?> read() async {
    final token = await _storage.read(key: _tokenKey);
    final expiryRaw = await _storage.read(key: _expiryKey);
    if (token == null || expiryRaw == null) return null;

    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null || !expiry.isAfter(DateTime.now())) {
      await clear();
      return null;
    }

    return SessionData(token: token, expiresAt: expiry);
  }

  @override
  Future<void> write(SessionData session) async {
    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(
      key: _expiryKey,
      value: session.expiresAt.toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
  }
}
