import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'api_client.dart';
import 'models.dart';
import 'session_store.dart';

class DeviceUnlock {
  final LocalAuthentication _auth = LocalAuthentication();
  Future<bool> authenticate() async {
    if (kIsWeb || !await _auth.isDeviceSupported()) return false;
    return _auth.authenticate(
      localizedReason: 'Unlock Solar Ops',
      options: const AuthenticationOptions(stickyAuth: true),
    );
  }
}

class AppController extends ChangeNotifier {
  AppController({SolarOpsApi? api, SessionStore? store, DeviceUnlock? unlock})
      : api = api ?? SolarOpsApi(),
        store = store ?? SessionStore(),
        unlock = unlock ?? DeviceUnlock();
  final SolarOpsApi api;
  final SessionStore store;
  final DeviceUnlock unlock;
  String? _token;
  BootstrapData? data;
  final Map<String, Bill> extraBills = {};
  String? activeBillId;
  Bill? billById(String id) {
    for (final b in data?.bills ?? <Bill>[]) {
      if (b.id == id) return b;
    }
    return extraBills[id];
  }

  Future<void> loadBill(String id) async {
    final token = _token;
    if (token == null || billById(id) != null) return;
    try {
      extraBills[id] = await api.billDetails(token, id);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Could not load bill';
    }
    changed();
  }

  Future<List<Bill>> searchBills(String query) async {
    final token = _token;
    if (token == null) return [];
    try {
      final bills = await api.searchBills(token, query, selectedCompanyId);
      for (final b in bills) {
        extraBills[b.id] = b;
      }
      return bills;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      rethrow;
    }
  }

  List<Conversation>? chatData;
  List<Conversation> get conversations => chatData ?? data?.conversations ?? [];
  bool initializing = true;
  bool busy = false;
  bool refreshing = false;
  bool lockEnabled = false;
  bool locked = false;
  String? selectedCompanyId;
  String? error;
  bool _disposed = false;
  bool get signedIn => _token != null;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final values = await Future.wait<Object?>([
        store.read(),
        store.readCache(),
        store.readLock(),
        store.readCompany(),
      ]);
      final session = values[0] as StoredSession?;
      lockEnabled = values[2] as bool;
      if (session != null && session.isValid) {
        _token = session.token;
        final cache = values[1] as Map<String, dynamic>?;
        if (cache != null) data = BootstrapData.fromJson(cache);
        selectedCompanyId = values[3] as String?;
        locked = lockEnabled;
      } else {
        await store.clear();
      }
    } catch (_) {
      error = 'Could not restore saved data';
    }
    initializing = false;
    changed();
    if (signedIn && !locked) unawaited(refresh(silent: true));
  }

  Future<bool> login(String accessKey) async {
    if (busy) return false;
    busy = true;
    error = null;
    changed();
    try {
      final session = await api.createSession(accessKey);
      await store.save(session.token, session.expiresAt);
      _token = session.token;
      locked = false;
      await refresh(silent: true);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Could not connect. Try again.';
      return false;
    } finally {
      busy = false;
      changed();
    }
  }

  Future<void> logout() async {
    _token = null;
    data = null;
    chatData = null;
    extraBills.clear();
    activeBillId = null;
    selectedCompanyId = null;
    locked = false;
    error = null;
    await store.clear();
    changed();
  }

  Future<void> selectCompany(String? id) async {
    selectedCompanyId = id;
    changed();
    await store.saveCompany(id);
  }

  Future<bool> setDeviceLock(bool enabled) async {
    try {
      if (enabled && !await unlock.authenticate()) {
        error = 'Set a device PIN, pattern or fingerprint first.';
        changed();
        return false;
      }
      await store.saveLock(enabled);
      lockEnabled = enabled;
      error = null;
      changed();
      return true;
    } catch (_) {
      error = 'Device unlock is unavailable on this device.';
      changed();
      return false;
    }
  }

  void lock() {
    if (lockEnabled && signedIn) {
      locked = true;
      changed();
    }
  }

  Future<void> unlockApp() async {
    try {
      if (await unlock.authenticate()) {
        locked = false;
        error = null;
        changed();
        unawaited(refresh(silent: true));
      }
    } catch (_) {
      error = 'Could not unlock. Use the device PIN or try again.';
      changed();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    final token = _token;
    if (token == null || refreshing || locked) return;
    refreshing = true;
    if (!silent) error = null;
    changed();
    try {
      final fresh = await api.bootstrap(token);
      if (_token != token) return;
      data = fresh;
      final detailId = activeBillId;
      if (detailId != null && !fresh.bills.any((b) => b.id == detailId)) {
        try {
          extraBills[detailId] = await api.billDetails(token, detailId);
        } catch (_) {/* The overview still synced. */}
      }
      if (selectedCompanyId != null &&
          !fresh.stock.companies.any((c) => c.id == selectedCompanyId)) {
        selectedCompanyId = null;
      }
      error = null;
      // Cache failure must not turn a successful sync into a failed server request.
      try {
        await store.saveCache(fresh.raw);
      } catch (_) {
        /* Next launch can still refresh. */
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Offline. Showing saved data.';
    } finally {
      refreshing = false;
      changed();
    }
  }

  Future<void> loadConversations() async {
    final token = _token;
    if (token == null) return;
    try {
      chatData = await api.conversations(token);
      error = null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Could not load WhatsApp';
    }
    changed();
  }

  Future<String?> runMutation(
    Future<void> Function(String token) action,
  ) async {
    final token = _token;
    if (token == null || locked) return 'Unlock to continue';
    if (busy) return 'Please wait';
    busy = true;
    error = null;
    changed();
    try {
      await action(token);
      // An acknowledged write remains successful if the following refresh is offline.
      await refresh(silent: true);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      error = e.message;
      return e.message;
    } catch (_) {
      const message =
          'Could not confirm the change. Refresh before trying again.';
      error = message;
      return message;
    } finally {
      busy = false;
      changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    api.dispose();
    super.dispose();
  }
}
