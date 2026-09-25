import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';
import 'session_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    required OpsRepository api,
    required SessionStore sessionStore,
  })  : _api = api,
        _sessionStore = sessionStore;

  final OpsRepository _api;
  final SessionStore _sessionStore;

  bool _initialized = false;
  bool _loading = false;
  bool _mutating = false;
  String? _token;
  DateTime? _sessionExpiresAt;
  BootstrapData? _data;
  String? _error;

  bool get initialized => _initialized;
  bool get loading => _loading;
  bool get mutating => _mutating;
  bool get authenticated => _token != null;
  BootstrapData? get data => _data;
  String? get error => _error;
  DateTime? get sessionExpiresAt =>
      _data?.sessionExpiresAt ?? _sessionExpiresAt;
  String get apiBaseUrl => _api.baseUrl;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final session = await _sessionStore.read();
      if (session != null) {
        _token = session.token;
        _sessionExpiresAt = session.expiresAt;
        await _refreshInternal();
      }
    } on ApiException catch (error) {
      if (error.unauthorized) {
        await _clearSession();
      } else {
        _error = error.message;
      }
    } catch (_) {
      _error = 'Unable to restore the saved session.';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String accessKey) async {
    final clean = accessKey.trim();
    if (clean.isEmpty) {
      _error = 'Operations access key is required.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final session = await _api.login(clean);
      _token = session.token;
      _sessionExpiresAt = session.expiresAt;
      await _sessionStore.write(session);
      await _refreshInternal();
      return _data != null;
    } on ApiException catch (error) {
      _error = error.statusCode == 401
          ? 'The Operations access key was not accepted.'
          : error.message;
      await _clearSession();
      return false;
    } catch (_) {
      _error = 'Unable to connect to Solar Ops.';
      await _clearSession();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_token == null || _loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _refreshInternal();
    } on ApiException catch (error) {
      if (error.unauthorized) {
        _error = 'Your session expired. Sign in again.';
        await _clearSession();
      } else {
        _error = error.message;
      }
    } catch (_) {
      _error = 'Unable to refresh operations data.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInternal() async {
    final token = _token;
    if (token == null) return;
    _data = await _api.bootstrap(token);
    _error = null;
  }

  Future<void> logout() async {
    await _clearSession();
    _data = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _sessionExpiresAt = null;
    await _sessionStore.clear();
  }

  Future<String> parseBill(String messageId) async {
    return _runMutation(() async {
      await _api.parseBill(_requireToken(), messageId);
      await _refreshInternal();
      return 'Bill parsing completed.';
    });
  }

  Future<String> approveBill(String messageId) async {
    return _runMutation(() async {
      await _api.approveBill(_requireToken(), messageId);
      await _refreshInternal();
      return 'Bill approved and stock workflow rechecked.';
    });
  }

  Future<String> getMediaUrl(String messageId) async {
    try {
      return await _api.mediaUrl(_requireToken(), messageId);
    } on ApiException catch (error) {
      if (error.unauthorized) {
        await _handleExpiredSession();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addOpeningStock({
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
    return _runMutation(() async {
      final result = await _api.addOpeningStock(
        _requireToken(),
        {
          'companyId': companyId,
          'companyName': companyName,
          'companyGstin': companyGstin,
          'productName': productName,
          'unit': unit,
          'hsnSac': hsnSac,
          'quantity': quantity,
          'allowSimilarCompany': allowSimilarCompany,
          'allowSimilarProduct': allowSimilarProduct,
        },
      );

      final status = (result['status'] ?? 'unknown').toString();
      if (status == 'opening_created' || status == 'opening_exists') {
        await _refreshInternal();
      }
      return result;
    });
  }

  Future<String> adjustStock({
    required String productId,
    required double targetQuantity,
  }) async {
    return _runMutation(() async {
      final result = await _api.adjustStock(
        _requireToken(),
        {
          'productId': productId,
          'targetQuantity': targetQuantity,
        },
      );
      final status = (result['status'] ?? 'unknown').toString();
      if (status == 'adjusted' ||
          status == 'already_adjusted' ||
          status == 'no_change') {
        await _refreshInternal();
      }
      return status;
    });
  }

  String _requireToken() {
    final token = _token;
    if (token == null) {
      throw const ApiException('Sign in again.', statusCode: 401);
    }
    return token;
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    if (_mutating) {
      throw const ApiException('Another operation is still in progress.');
    }

    _mutating = true;
    _error = null;
    notifyListeners();

    try {
      return await action();
    } on ApiException catch (error) {
      if (error.unauthorized) {
        await _handleExpiredSession();
      }
      rethrow;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  Future<void> _handleExpiredSession() async {
    _error = 'Your session expired. Sign in again.';
    _data = null;
    await _clearSession();
    notifyListeners();
  }
}
