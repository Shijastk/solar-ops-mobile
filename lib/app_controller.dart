import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'session_store.dart';

class AppController extends ChangeNotifier {
  AppController({SolarOpsApi? api, SessionStore? store})
      : api = api ?? SolarOpsApi(),
        store = store ?? SessionStore();

  final SolarOpsApi api;
  final SessionStore store;

  String? _token;
  BootstrapData? data;
  bool initializing = true;
  bool busy = false;
  String? error;

  bool get signedIn => _token != null;

  Future<void> initialize() async {
    try {
      final session = await store.read();
      if (session != null && session.isValid) {
        _token = session.token;
        await refresh(silent: true);
      } else if (session != null) {
        await store.clear();
      }
    } catch (e) {
      error = 'Unable to restore session';
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String accessKey) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final session = await api.createSession(accessKey);
      _token = session.token;
      await store.save(session.token, session.expiresAt);
      data = await api.bootstrap(session.token);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Unable to connect to Solar Ops';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    data = null;
    error = null;
    await store.clear();
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    final token = _token;
    if (token == null) return;
    if (!silent) {
      busy = true;
      error = null;
      notifyListeners();
    }

    try {
      data = await api.bootstrap(token);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Unable to refresh data';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> runMutation(Future<void> Function(String token) action) async {
    final token = _token;
    if (token == null) return 'Session expired';
    busy = true;
    error = null;
    notifyListeners();

    try {
      await action(token);
      data = await api.bootstrap(token);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      error = e.message;
      return e.message;
    } catch (_) {
      const message = 'Request failed. Check your connection and try again.';
      error = message;
      return message;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
