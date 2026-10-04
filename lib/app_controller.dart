import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'api_client.dart';
import 'models.dart';
import 'session_store.dart';
import 'request_id.dart';

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
  int _writeVersion = 0;
  bool _refreshAgain = false;
  final Map<String, DeliveryTrip> _tripOverrides = {};
  final Set<String> savingTrips = {};
  // Uploads are local to the draft page, not the app-wide mutation lock.
  Future<Map<String, dynamic>> uploadDraftFile(
      String name, Uint8List bytes, String requestId) async {
    final token = _token;
    if (token == null || locked) throw const ApiException('Unlock to continue');
    _writeVersion++;
    try {
      return await api.uploadBillResult(token, name, bytes,
          requestId: requestId);
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      rethrow;
    }
  }

  Future<DeliveryTrip> commitBillDraft(Map<String, dynamic> payload) async {
    DeliveryTrip? result;
    final failure = await runMutation((token) async {
      final json = await api.operation(token, payload);
      if (json['id'] == null) {
        throw const ApiException('Could not confirm saved trip. Retry save.');
      }
      result = DeliveryTrip.fromJson(json);
      _tripOverrides[result!.id] = result!;
    });
    if (failure != null) throw ApiException(failure);
    _cacheTrips();
    changed();
    return result!;
  }

  final Map<String, Map<String, dynamic>> failedTripRequests = {};
  List<DeliveryTrip> get trips => [
        ..._tripOverrides.values
            .where((t) => !(data?.trips.any((x) => x.id == t.id) ?? false)),
        ...?data?.trips.map((t) => _tripOverrides[t.id] ?? t),
      ];
  void _cacheTrips() {
    final current = data;
    if (current != null) {
      unawaited(store.saveCache({
        ...current.raw,
        'trips': trips
            .where((t) =>
                !failedTripRequests.containsKey(t.id) &&
                !savingTrips.contains(t.id))
            .map((t) => t.raw)
            .toList()
      }).catchError((Object _) {}));
    }
  }

  void rememberDriver(Driver driver) {
    final current = data;
    if (current == null) return;
    data = BootstrapData.fromJson({
      ...current.raw,
      'drivers': [
        ...current.drivers
            .where((d) => d.id != driver.id)
            .map((d) => {'id': d.id, 'name': d.name}),
        {'id': driver.id, 'name': driver.name}
      ]
    });
    changed();
  }

  void rememberCompany(Map<String, dynamic> company) {
    final current = data;
    if (current == null) return;
    final stock = Map<String, dynamic>.from(current.raw['stock'] as Map);
    stock['companies'] = [
      ...current.stock.companies
          .where((c) => c.id != company['id'])
          .map((c) => {'id': c.id, 'name': c.name, 'gstin': c.gstin}),
      company
    ];
    data = BootstrapData.fromJson({...current.raw, 'stock': stock});
    unawaited(selectCompany(company['id'].toString()));
    changed();
  }

  Future<String?> changeDriver(DeliveryTrip trip, Driver driver) async {
    if (busy) return 'Please wait';
    _tripOverrides[trip.id] = trip.withDriver(driver);
    savingTrips.add(trip.id);
    changed();
    final result = await runMutation((token) async {
      final saved = await api.operation(token, {
        'action': 'update_trip',
        'tripId': trip.id,
        'driverId': driver.id,
        'close': false
      });
      if (saved['id'] != null) {
        _tripOverrides[trip.id] = DeliveryTrip.fromJson(saved);
      }
    });
    savingTrips.remove(trip.id);
    if (result != null) _tripOverrides[trip.id] = trip;
    _cacheTrips();
    changed();
    return result;
  }

  Future<String?> tripAction(DeliveryTrip trip, String action,
      {String? name}) async {
    if (busy) return 'Please wait';
    _tripOverrides[trip.id] = DeliveryTrip.fromJson({
      ...trip.raw,
      if (action == 'rename') 'name': name,
      if (action == 'complete') 'completedAt': DateTime.now().toIso8601String(),
      if (action == 'remove') 'removedAt': DateTime.now().toIso8601String(),
    });
    savingTrips.add(trip.id);
    changed();
    final result = await runMutation((token) async {
      final saved = await api.operation(token, {
        'action': 'trip_action',
        'tripId': trip.id,
        'requestId': requestUuid(),
        'operation': action,
        if (name != null) 'name': name,
      });
      _tripOverrides[trip.id] = DeliveryTrip.fromJson(saved);
    });
    savingTrips.remove(trip.id);
    if (result != null && signedIn) _tripOverrides[trip.id] = trip;
    _cacheTrips();
    changed();
    return result;
  }

  final Map<String, Map<String, dynamic>> companyProfiles = {};
  Future<Map<String, dynamic>> companyProfile(String id) async {
    if (companyProfiles.containsKey(id)) return companyProfiles[id]!;
    final token = _token;
    if (token == null) throw const ApiException('Sign in to continue');
    try {
      final profile = await api.companyProfile(token, id);
      if (_token == token) companyProfiles[id] = profile;
      return profile;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await logout();
      rethrow;
    }
  }

  Future<String?> saveCompanyProfile(Map<String, dynamic> payload) =>
      runMutation((token) async {
        final profile = await api
            .operation(token, {'action': 'company_profile', ...payload});
        companyProfiles[profile['id'].toString()] = profile;
        rememberCompany({
          'id': profile['id'],
          'name': profile['label'],
          'gstin': profile['gstin']
        });
      });

  Future<String?> saveTrip(
      Map<String, dynamic> payload, DeliveryTrip preview) async {
    if (busy) return 'Please wait';
    _tripOverrides[preview.id] = preview;
    failedTripRequests.remove(preview.id);
    savingTrips.add(preview.id);
    changed();
    final result = await runMutation((token) async {
      final saved = await api.operation(token, payload);
      if (saved['id'] == null) {
        throw const ApiException(
            'Saved trip could not be loaded. Refresh before retrying.');
      }
      _tripOverrides.remove(preview.id);
      _tripOverrides[saved['id'].toString()] = DeliveryTrip.fromJson(saved);
    });
    savingTrips.remove(preview.id);
    if (result != null && signedIn) {
      _tripOverrides[preview.id] = preview;
      failedTripRequests[preview.id] = payload;
    }
    _cacheTrips();
    changed();
    return result;
  }

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
      if (signedIn) unawaited(refresh(silent: true));
    }
  }

  Future<void> logout() async {
    _token = null;
    data = null;
    chatData = null;
    extraBills.clear();
    _tripOverrides.clear();
    savingTrips.clear();
    failedTripRequests.clear();
    companyProfiles.clear();
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
    if (token == null || locked) return;
    if (refreshing || busy) {
      _refreshAgain = true;
      return;
    }
    final version = _writeVersion;
    refreshing = true;
    if (!silent) error = null;
    changed();
    try {
      final fresh = await api.bootstrap(token);
      if (_token != token) return;
      if (_writeVersion != version || busy) {
        _refreshAgain = true;
        return;
      }
      _tripOverrides.removeWhere((id, _) =>
          !failedTripRequests.containsKey(id) && !savingTrips.contains(id));
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
      if (_refreshAgain && !busy) {
        _refreshAgain = false;
        unawaited(refresh(silent: true));
      }
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
    _writeVersion++;
    error = null;
    changed();
    var acknowledged = false;
    try {
      await action(token);
      acknowledged = true;
      // An acknowledged write remains successful if the following refresh is offline.
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
      if (acknowledged || _refreshAgain) {
        _refreshAgain = false;
        unawaited(refresh(silent: true));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    api.dispose();
    super.dispose();
  }
}
