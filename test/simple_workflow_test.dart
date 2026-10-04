import 'dart:async';
import 'fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/api_client.dart';
import 'package:solar_ops_mobile/app_controller.dart';
import 'package:solar_ops_mobile/app_ui.dart';
import 'package:solar_ops_mobile/models.dart';
import 'package:solar_ops_mobile/session_store.dart';

class MemoryStore extends SessionStore {
  StoredSession? session = StoredSession(
      token: 'saved-token',
      expiresAt: DateTime.now().add(const Duration(days: 30)));
  Map<String, dynamic>? cache = sampleData();
  bool lockValue = false;
  String? company;
  @override
  Future<StoredSession?> read() async => session;
  @override
  Future<Map<String, dynamic>?> readCache() async => cache;
  @override
  Future<bool> readLock() async => lockValue;
  @override
  Future<String?> readCompany() async => company;
  @override
  Future<void> saveCompany(String? id) async {
    company = id;
  }

  @override
  Future<void> saveCache(Map<String, dynamic> data) async {
    cache = data;
  }

  @override
  Future<void> saveLock(bool enabled) async {
    lockValue = enabled;
  }

  @override
  Future<void> clear() async {
    cache = null;
    session = null;
    company = null;
  }
}

class DelayedApi extends SolarOpsApi {
  final pending = Completer<BootstrapData>();
  int requests = 0;
  @override
  Future<BootstrapData> bootstrap(String token) {
    requests++;
    return pending.future;
  }
}

class FakeUnlock extends DeviceUnlock {
  bool result = false;
  @override
  Future<bool> authenticate() async => result;
}

void main() {
  test(
      'empty and removed trips are hidden; products and active bills remain searchable',
      () {
    final empty = DeliveryTrip.fromJson(
        {'id': 'empty', 'status': 'collecting', 'bills': []});
    expect(empty.visible, false);
    final manual = DeliveryTrip.fromJson({
      'id': 'manual',
      'entryMode': 'manual',
      'name': 'Custom',
      'destination': 'Tirur',
      'driverName': 'Driver A',
      'items': [
        {'productName': 'Panel', 'quantity': 3, 'unit': 'NOS'}
      ]
    });
    expect(manual.visible, true);
    expect(manual.matches('tirur'), true);
    expect(manual.matches('panel'), true);
    expect(manual.matches('driver a'), true);
    expect(
        DeliveryTrip.fromJson({...manual.raw, 'removedAt': '2026-10-04'})
            .visible,
        false);
    expect(
        DeliveryTrip.fromJson({
          'bills': [
            {'duplicate': true},
            {'cancelled': true}
          ]
        }).visible,
        false);
  });
  test('completion preview is immediate and rolls back a rejected save',
      () async {
    final api = MutationApi();
    final controller = AppController(api: api, store: MemoryStore());
    await controller.initialize();
    final old = controller.trips.first;
    final saving = controller.tripAction(old, 'complete');
    expect(controller.trips.first.completed, true);
    api.write.completeError(const ApiException('Rejected', statusCode: 409));
    expect(await saving, 'Rejected');
    expect(controller.trips.first.completed, false);
    for (final read in api.reads) {
      if (!read.isCompleted) {
        read.complete(BootstrapData.fromJson(sampleData()));
      }
    }
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
  });
  test('cached launch finishes before network and keeps data when offline',
      () async {
    final api = DelayedApi(), store = MemoryStore();
    final c = AppController(api: api, store: store);
    await c.initialize();
    expect(c.initializing, false);
    expect(c.data!.bills.first.draft!.documentNumber, 'INV-1');
    expect(api.requests, 1);
    api.pending.completeError(const ApiException('Offline', statusCode: 503));
    await Future<void>.delayed(Duration.zero);
    expect(c.data, isNotNull);
    expect(c.error, 'Offline');
    c.dispose();
  });
  test('a rejected session clears cached data and token', () async {
    final api = DelayedApi(), store = MemoryStore();
    final c = AppController(api: api, store: store);
    await c.initialize();
    api.pending.completeError(const ApiException('Expired', statusCode: 401));
    await Future<void>.delayed(Duration.zero);
    expect(c.signedIn, false);
    expect(c.data, isNull);
    expect(store.cache, isNull);
    c.dispose();
  });
  test(
      'device lock only enables after authentication and blocks data refresh until unlock',
      () async {
    final api = DelayedApi(),
        store = MemoryStore()..lockValue = true,
        unlock = FakeUnlock();
    final c = AppController(api: api, store: store, unlock: unlock);
    await c.initialize();
    expect(c.locked, true);
    expect(api.requests, 0);
    await c.unlockApp();
    expect(c.locked, true);
    unlock.result = true;
    await c.unlockApp();
    expect(c.locked, false);
    expect(api.requests, 1);
    api.pending.complete(BootstrapData.fromJson(sampleData()));
    await Future<void>.delayed(Duration.zero);
    c.dispose();
  });
  test(
      'driver changes render before write and acknowledged writes do not wait for refresh',
      () async {
    final api = MutationApi(),
        c = AppController(api: api, store: MemoryStore());
    await c.initialize();
    final old = c.trips.first;
    const driver = Driver(id: 'new-driver', name: 'New driver');
    final pending = c.changeDriver(old, driver);
    expect(c.trips.first.driverName, 'New driver');
    expect(c.savingTrips.contains(old.id), true);
    api.write.complete(
        {...old.raw, 'driverId': driver.id, 'driverName': driver.name});
    expect(await pending, isNull);
    expect(c.busy, false);
    expect(c.trips.first.driverName, 'New driver');
    api.reads.first.complete(BootstrapData.fromJson(sampleData()));
    await Future<void>.delayed(Duration.zero);
    expect(c.trips.first.driverName, 'New driver');
    for (final read in api.reads) {
      if (!read.isCompleted) read.completeError(const ApiException('Offline'));
    }
    await Future<void>.delayed(Duration.zero);
    c.dispose();
  });
  test('rejected driver write restores old selection', () async {
    final api = MutationApi(),
        c = AppController(api: api, store: MemoryStore());
    await c.initialize();
    final old = c.trips.first;
    final pending =
        c.changeDriver(old, const Driver(id: 'new-driver', name: 'New driver'));
    api.write.completeError(
        const ApiException('Driver unavailable', statusCode: 409));
    expect(await pending, 'Driver unavailable');
    expect(c.trips.first.driverName, old.driverName);
    for (final read in api.reads) {
      if (!read.isCompleted) read.completeError(const ApiException('Offline'));
    }
    await Future<void>.delayed(Duration.zero);
    c.dispose();
  });
  testWidgets(
      'three work pages and top company switching filter trips, stock and grouped history',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore();
    final c = AppController(store: store)
      ..data = BootstrapData.fromJson(sampleData());
    addTearDown(c.dispose);
    await tester.pumpWidget(MaterialApp(home: AppShell(controller: c)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Tirur'), findsOneWidget);
    await tester.tap(find.text('All companies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second Solar Company Limited'));
    await tester.pumpAndSettle();
    expect(find.text('Tirur'), findsNothing);
    expect(find.text('Palakkad'), findsOneWidget);
    await tester.tap(find.text('Stock'));
    await tester.pumpAndSettle();
    expect(find.text('Second panel'), findsOneWidget);
    expect(find.text('First panel'), findsNothing);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('INV-2'), findsOneWidget);
    expect(find.textContaining('INV-1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class MutationApi extends SolarOpsApi {
  final write = Completer<Map<String, dynamic>>();
  final reads = <Completer<BootstrapData>>[];
  @override
  Future<BootstrapData> bootstrap(String token) {
    final next = Completer<BootstrapData>();
    reads.add(next);
    return next.future;
  }

  @override
  Future<Map<String, dynamic>> operation(
          String token, Map<String, dynamic> payload) =>
      write.future;
}
