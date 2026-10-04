import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'models.dart';
import 'api_client.dart';
import 'support_ui.dart';
import 'daily_forms.dart';
export 'support_ui.dart';

class SolarOpsRoot extends StatefulWidget {
  const SolarOpsRoot({super.key});
  @override
  State<SolarOpsRoot> createState() => _RootState();
}

class _RootState extends State<SolarOpsRoot> with WidgetsBindingObserver {
  late final AppController controller;
  DateTime? backgroundAt;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = AppController()..initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) backgroundAt = DateTime.now();
    if (state == AppLifecycleState.resumed && backgroundAt != null) {
      if (DateTime.now().difference(backgroundAt!) >
          const Duration(minutes: 1)) {
        controller.lock();
      }
      backgroundAt = null;
      if (!controller.locked) unawaited(controller.refresh(silent: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.initializing) {
            return const Scaffold(
              body: Center(
                child: Icon(Icons.solar_power, size: 56, color: appPurple),
              ),
            );
          }
          if (!controller.signedIn) return LoginScreen(controller: controller);
          if (controller.locked) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: controller.unlockApp,
                      child: const Text('Unlock Solar Ops'),
                    ),
                    if (controller.error != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(controller.error!),
                      ),
                    TextButton(
                      onPressed: controller.logout,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            );
          }
          return AppShell(controller: controller);
        },
      );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final keyInput = TextEditingController();
  @override
  void dispose() {
    keyInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.solar_power, size: 52, color: appPurple),
                    const SizedBox(height: 24),
                    const Text(
                      'Solar Ops',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Connect this phone once.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: keyInput,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Access key'),
                      onSubmitted: (_) =>
                          widget.controller.login(keyInput.text.trim()),
                    ),
                    if (widget.controller.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(widget.controller.error!),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: widget.controller.busy
                          ? null
                          : () => widget.controller.login(keyInput.text.trim()),
                      child: Text(
                        widget.controller.busy ? 'Connecting…' : 'Connect',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> saveAction(
  BuildContext context,
  AppController controller,
  Future<void> Function(String) action, {
  String success = 'Saved',
}) async {
  final error = await controller.runMutation(action);
  if (context.mounted) {
toast(context, error ?? success);
}
}

Future<String?> askText(
  BuildContext context,
  String title, {
  String? initial,
  bool number = false,
}) async {
  final input = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        controller: input,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        onSubmitted: (_) => Navigator.pop(context, input.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, input.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  input.dispose();
  return result;
}

Future<void> upload(
  BuildContext context,
  AppController controller, {
  String? tripId,
}) async {
  try {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
      withReadStream: true,
    );
    if (selected == null || !context.mounted) return;
    final file = selected.files.single;
    if (file.size > 4 * 1024 * 1024) {
      toast(context, 'Choose a PDF smaller than 4 MB');
      return;
    }
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.readStream != null) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in file.readStream!) {
        if (builder.length + chunk.length > 4 * 1024 * 1024) {
          throw Exception('File too large');
        }
        builder.add(chunk);
      }
      bytes = builder.takeBytes();
    }
    if (bytes == null) throw Exception('Could not read file');
    String result = 'Bill saved';
    final error = await controller.runMutation((token) async {
      result = await controller.api.uploadBill(
        token,
        file.name,
        bytes!,
        tripId: tripId,
      );
    });
    if (context.mounted) {
toast(context, error ?? result);
}
  } catch (_) {
    if (context.mounted) {
toast(context, 'Could not open file picker');
}
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _ShellState();
}

class _ShellState extends State<AppShell> {
  int index = 0;
  AppController get c => widget.controller;
  Future<void> companyPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All companies'),
              trailing:
                  c.selectedCompanyId == null ? const Icon(Icons.check) : null,
              onTap: () {
                c.selectCompany(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
                leading: const Icon(Icons.add),
                title: const Text("Create new company"),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                      context: this.context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => CreateCompanySheet(controller: c));
                }),
            ...?c.data?.stock.companies.map(
              (company) => ListTile(
                title: Text(company.name),
                subtitle: Text(company.gstin ?? ''),
                trailing: c.selectedCompanyId == company.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  c.selectCompany(company.id);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> menu(String item) async {
    if (item == 'drivers') {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => DriversPage(controller: c)),
      );
    }
    if (item == 'chat') {
      unawaited(c.loadConversations());
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ConversationsScreen(controller: c),
        ),
      );
    }
    if (item == 'lock') {
      final success = await c.setDeviceLock(!c.lockEnabled);
      if (mounted) {
        toast(
          context,
          success
              ? (c.lockEnabled ? 'Device lock enabled' : 'Device lock off')
              : c.error ?? 'Device lock unavailable',
        );
      }
    }
    if (item == 'logout') await c.logout();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: c, builder: (context, _) => buildShell(context));

  Widget buildShell(BuildContext context) {
    final data = c.data;
    String company = 'All companies';
    for (final item in data?.stock.companies ?? <StockCompany>[]) {
      if (item.id == c.selectedCompanyId) company = item.name;
    }
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: companyPicker,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  company,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: menu,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'drivers', child: Text('Drivers')),
              const PopupMenuItem(value: 'chat', child: Text('WhatsApp')),
              PopupMenuItem(
                value: 'lock',
                child: Text(
                  c.lockEnabled
                      ? 'Turn off device lock'
                      : 'Use fingerprint / device PIN',
                ),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.error ??
                        (data == null
                            ? 'Getting your data…'
                            : 'Synced ${dateTime(data.generatedAt)}'),
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.error != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: c.refreshing ? null : () => c.refresh(),
                  icon: c.refreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.refresh,
              child: data == null
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Pull down to try again')),
                      ],
                    )
                  : IndexedStack(
                      index: index,
                      children: [
                        TripsPage(controller: c),
                        SimpleStockPage(controller: c),
                        HistoryPage(controller: c),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

bool billMatches(Bill bill, String? companyId) =>
    companyId == null || bill.companyId == companyId;

class TripsPage extends StatelessWidget {
  const TripsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, data = c.data!;
    final trips = c.trips
        .where((t) =>
            t.entryMode == 'manual' ||
            t.status == 'collecting' ||
            t.bills.any((b) => !b.duplicate))
        .where(
          (t) =>
              c.selectedCompanyId == null ||
              t.companyId == c.selectedCompanyId ||
              t.bills.any(
                (b) =>
                    b.companyId == c.selectedCompanyId ||
                    data.stock.companies.any(
                      (company) =>
                          company.id == c.selectedCompanyId &&
                          company.gstin == b.companyGstin,
                    ),
              ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        FilledButton.icon(
          onPressed: c.busy
              ? null
              : () async {
                  final input = await showModalBottomSheet<ManualTripInput>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => ManualTripForm(controller: c));
                  if (input == null || !context.mounted) return;
                  final id = requestUuid();
                  final preview = DeliveryTrip.fromJson({
                    'id': id,
                    'companyId': input.companyId,
                    'name': input.place,
                    'driverId': input.driver.id,
                    'driverName': input.driver.name,
                    'status': 'ready',
                    'entryMode': 'manual',
                    'siteCount': input.sites,
                    'ownerName': input.owner,
                    'createdAt': DateTime.now().toIso8601String(),
                    'items': input.items
                        .map((i) => {...i, 'companyId': input.companyId})
                        .toList(),
                    'bills': []
                  });
                  final pending = c.saveTrip({
                    'action': 'manual_dispatch',
                    'requestId': id,
                    'companyId': input.companyId,
                    'destination': input.place,
                    'driverId': input.driver.id,
                    'siteCount': input.sites,
                    'ownerName': input.owner,
                    'items': input.items
                  }, preview);
                  Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => TripPage(controller: c, tripId: id)));
                  final error = await pending;
                  if (context.mounted) {
toast(context, error ?? 'Dispatch saved');
}
                },
          icon: const Icon(Icons.add),
          label: const Text('New trip'),
        ),
        TextButton.icon(
            onPressed: c.busy
                ? null
                : () async {
                    final id = requestUuid();
                    final preview = DeliveryTrip.fromJson({
                      'id': id,
                      'companyId': c.selectedCompanyId,
                      'name': 'New trip',
                      'status': 'collecting',
                      'bills': []
                    });
                    final pending = c.saveTrip({
                      'action': 'create_trip',
                      'requestId': id,
                      'companyId': c.selectedCompanyId
                    }, preview);
                    Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                TripPage(controller: c, tripId: id)));
                    final error = await pending;
                    if (context.mounted) {
toast(context, error ?? 'Trip created');
}
                  },
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Trip from bills')),
        const SizedBox(height: 18),
        if (trips.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('No trips yet. Add a dispatch or start from bills.'),
          ),
        ...trips.map(
          (t) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${t.driverName ?? 'Choose driver'} · ${t.entryMode == 'manual' ? '${t.siteCount} sites' : '${t.bills.where((b) => !b.duplicate).length} bills'}\n${c.savingTrips.contains(t.id) ? 'Saving…' : c.failedTripRequests.containsKey(t.id) ? 'Not saved · Retry' : t.entryMode == 'manual' ? 'Dispatch recorded' : t.bills.any((b) => b.needsAttention) ? 'Check bills' : t.status == 'ready' ? 'Ready to dispatch' : t.status == 'cancelled' ? 'Cancelled' : 'Add bills'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TripPage(controller: c, tripId: t.id),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TripPage extends StatelessWidget {
  const TripPage({super.key, required this.controller, required this.tripId});
  final AppController controller;
  final String tripId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          DeliveryTrip? trip;
          for (final t in controller.trips) {
            if (t.id == tripId) trip = t;
          }
          if (trip == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Trip')),
              body: Center(
                child: TextButton(
                  onPressed: controller.refresh,
                  child: const Text('Refresh'),
                ),
              ),
            );
          }
          final t = trip, c = controller;
          return Scaffold(
            appBar: AppBar(title: Text(t.name)),
            body: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (c.savingTrips.contains(t.id))
                  const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('Saving…')),
                if (c.failedTripRequests.containsKey(t.id)) ...[
                  Text(c.error ?? 'Not saved'),
                  FilledButton(
                      onPressed: c.busy
                          ? null
                          : () async {
                              final error = await c.saveTrip(
                                  c.failedTripRequests[t.id]!, t);
                              if (context.mounted) {
toast(context, error ?? 'Saved');
}
                            },
                      child: const Text('Retry save'))
                ],
                ...t.items.map((i) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.name),
                    trailing: Text('${qty(i.quantity)} ${i.unit}'))),
                if (t.entryMode == 'manual')
                  Text(
                      '${t.siteCount} sites${t.ownerName?.isNotEmpty == true ? ' · ${t.ownerName}' : ''}'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.driverName ?? 'Choose driver'),
                  leading: const Icon(Icons.person_outline),
                  trailing: const Icon(Icons.expand_more),
                  onTap: c.busy
                      ? null
                      : () async {
                          final driver = await showModalBottomSheet<Driver>(
                            context: context,
                            showDragHandle: true,
                            builder: (context) => SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ...?(c.data?.drivers.map(
                                    (d) => ListTile(
                                      title: Text(d.name),
                                      onTap: () => Navigator.pop(context, d),
                                    ),
                                  )),
                                  ListTile(
                                    title: const Text('+ Add driver'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              DriversPage(controller: c),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (driver != null && context.mounted) {
                            final error = await c.changeDriver(t, driver);
                            if (context.mounted) {
toast(context, error ?? 'Driver saved');
}
                          }
                        },
                ),
                if (t.vehicleNumber != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(t.vehicleNumber!),
                  ),
                ...t.bills.where((b) => !b.duplicate).map(
                      (b) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          b.needsAttention
                              ? Icons.error_outline
                              : Icons.receipt_long_outlined,
                        ),
                        title: Text(b.number),
                        subtitle: b.needsAttention
                            ? const Text('Needs checking')
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SimpleBillPage(
                                controller: c, billId: b.messageId),
                          ),
                        ),
                      ),
                    ),
                if (t.status == 'collecting' &&
                    t.entryMode != 'manual' &&
                    !c.savingTrips.contains(t.id) &&
                    !c.failedTripRequests.containsKey(t.id)) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed:
                        c.busy ? null : () => upload(context, c, tripId: t.id),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload bill'),
                  ),
                  TextButton(
                    onPressed: c.busy
                        ? null
                        : () async {
                            final linked = c.trips
                                .expand((t) => t.bills)
                                .map((b) => b.messageId)
                                .toSet();
                            final bill = await showModalBottomSheet<Bill>(
                              context: context,
                              showDragHandle: true,
                              builder: (context) => SafeArea(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: c.data!.bills
                                      .where(
                                        (b) =>
                                            !linked.contains(b.id) &&
                                            billMatches(
                                                b, c.selectedCompanyId) &&
                                            b.draft?.workflowStatus !=
                                                'cancelled',
                                      )
                                      .map(
                                        (b) => ListTile(
                                          title: Text(
                                            b.draft?.documentNumber ??
                                                b.fileName,
                                          ),
                                          onTap: () =>
                                              Navigator.pop(context, b),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            );
                            if (bill != null && context.mounted) {
                              await saveAction(context, c, (token) async {
                                await c.api.operation(token, {
                                  'action': 'attach_bill',
                                  'tripId': t.id,
                                  'messageId': bill.id,
                                });
                              });
                            }
                          },
                    child: const Text('Choose existing bill'),
                  ),
                ],
                if (t.status != 'ready' && t.status != 'cancelled')
                  FilledButton(
                    onPressed: c.busy
                        ? null
                        : () => saveAction(context, c, (token) async {
                              await c.api.operation(token, {
                                'action': 'update_trip',
                                'tripId': t.id,
                                'driverId': t.driverId,
                                'close': true,
                              });
                            }, success: 'Trip ready'),
                    child: const Text('Ready to dispatch'),
                  ),
                if (t.status == 'ready' &&
                    !c.savingTrips.contains(t.id) &&
                    !c.failedTripRequests.containsKey(t.id))
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                        t.entryMode == 'manual'
                            ? 'Dispatch recorded'
                            : 'Ready to dispatch',
                        textAlign: TextAlign.center),
                  ),
              ],
            ),
          );
        },
      );
}

class DriversPage extends StatelessWidget {
  const DriversPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Drivers')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: controller.busy
                ? null
                : () async {
                    final name = await askText(context, 'Driver name');
                    if (name != null && name.isNotEmpty && context.mounted) {
                      await saveAction(context, controller, (token) async {
                        final saved = await controller.api.operation(token, {
                          'action': 'driver',
                          'name': name,
                        });
                        controller.rememberDriver(Driver.fromJson(saved));
                      });
                    }
                  },
            icon: const Icon(Icons.add),
            label: const Text('Add driver'),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: (controller.data?.drivers ?? [])
                .map(
                  (d) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(d.name),
                  ),
                )
                .toList(),
          ),
        ),
      );
}

class SimpleStockPage extends StatefulWidget {
  const SimpleStockPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<SimpleStockPage> createState() => _StockState();
}

class _StockState extends State<SimpleStockPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, data = c.data!;
    final balances = data.stock.balances.where(
      (b) =>
          (c.selectedCompanyId == null || b.companyId == c.selectedCompanyId) &&
          b.productName.toLowerCase().contains(query.toLowerCase()),
    );
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search stock',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
            onPressed: c.busy
                ? null
                : () async {
                    final input = await showModalBottomSheet<StockEntry>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => StockEntrySheet(controller: c));
                    if (input == null || !context.mounted) return;
                    final requestId = requestUuid();
                    String? code;
                    Future<String?> submit(bool allow) =>
                        c.runMutation((token) async {
                          try {
                            await c.api.addOpeningStock(
                                token: token,
                                productId: input.product?.productId,
                                requestId: requestId,
                                companyId: input.companyId,
                                productName: input.name,
                                unit: input.unit,
                                quantity: input.quantity,
                                hsnSac: input.product?.hsnSac,
                                allowSimilarProduct: allow);
                          } on ApiException catch (e) {
                            code = e.code;
                            rethrow;
                          }
                        });
                    var error = await submit(false);
                    if (code == 'potential_product_duplicate' &&
                        context.mounted) {
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                                  title: const Text('Similar product exists'),
                                  content: const Text(
                                      'Choose the existing product unless this is genuinely a different model or product.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Go back')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Different product'))
                                  ]));
                      if (confirm == true) error = await submit(true);
                    }
                    if (context.mounted) {
toast(context, error ?? 'Stock saved');
}
                  },
            icon: const Icon(Icons.add),
            label: const Text('Add stock')),
        const SizedBox(height: 16),
        const Text('Today dispatched',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        if (!data.todayStock.any((i) =>
            c.selectedCompanyId == null || i.companyId == c.selectedCompanyId))
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('No dispatch recorded today')),
        ...data.todayStock
            .where((i) =>
                (c.selectedCompanyId == null ||
                    i.companyId == c.selectedCompanyId) &&
                i.name.toLowerCase().contains(query.toLowerCase()))
            .map((i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.name),
                subtitle: c.selectedCompanyId == null
                    ? Text(data.stock.companies
                        .where((x) => x.id == i.companyId)
                        .map((x) => x.name)
                        .join())
                    : null,
                trailing: Text('${qty(i.quantity)} ${i.unit}'))),
        const Divider(height: 28),
        const Text('Balance stock',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ...balances.map(
          (b) => Card(
            child: ListTile(
              title: Text(b.productName),
              subtitle:
                  c.selectedCompanyId == null ? Text(b.companyName) : null,
              trailing: Text(
                b.balanceKnown
                    ? '${qty(b.currentQuantity)} ${b.unit}'
                    : 'Not recorded',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: c.busy
                  ? null
                  : () async {
                      final target = await showDialog<double>(
                        context: context,
                        builder: (_) => StockAdjustmentDialog(
                          productName: b.productName,
                          unit: b.unit,
                          currentQuantity: b.currentQuantity,
                          currentKnown: b.balanceKnown,
                        ),
                      );
                      if (target != null && context.mounted) {
                        await saveAction(
                          context,
                          c,
                          (token) => c.api.adjustStock(
                            token: token,
                            productId: b.productId,
                            targetQuantity: target,
                          ),
                        );
                      }
                    },
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});
  final AppController controller;
  @override
  State<HistoryPage> createState() => _HistoryState();
}

class _HistoryState extends State<HistoryPage> {
  String query = '';
  List<Bill>? searchResults;
  bool searching = false;
  String? searchCompany;
  Future<void> search() async {
    if (query.trim().length < 2 || searching) return;
    final requested = query, company = widget.controller.selectedCompanyId;
    setState(() => searching = true);
    try {
      final results = await widget.controller.searchBills(requested);
      if (mounted &&
          query == requested &&
          company == widget.controller.selectedCompanyId) {
        setState(() => searchResults = results);
      }
    } catch (_) {
      if (mounted) toast(context, 'Could not search. Try again.');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (searchCompany != c.selectedCompanyId) {
      searchResults = null;
      searchCompany = c.selectedCompanyId;
    }
    final bills = (searchResults ?? c.data!.bills)
        .where(
          (b) =>
              billMatches(b, c.selectedCompanyId) &&
              '${b.draft?.documentNumber ?? ''} ${b.draft?.consigneeName ?? ''} ${b.draft?.vehicleNumber ?? ''}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    final visibleIds = bills.map((b) => b.id).toSet();
    final grouped = c.trips
        .where((t) =>
            (c.selectedCompanyId == null ||
                t.companyId == c.selectedCompanyId ||
                t.bills.any((b) => b.companyId == c.selectedCompanyId)) &&
            (query.isEmpty ||
                '${t.name} ${t.driverName ?? ''}'
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                t.bills.any((b) => visibleIds.contains(b.messageId))))
        .toList();
    final linked =
        c.trips.expand((t) => t.bills).map((b) => b.messageId).toSet();
    final totals = c.data!.todayTotals.where((r) =>
        c.selectedCompanyId == null || r.companyId == c.selectedCompanyId);
    final billCount = totals.fold<int>(0, (sum, r) => sum + r.billCount);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          '$billCount bills saved today',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Find trip, driver or bill',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() {
            query = v;
            searchResults = null;
          }),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => search(),
        ),
        if (query.trim().length >= 2)
          TextButton(
              onPressed: searching ? null : search,
              child: Text(searching ? 'Searching…' : 'Search all saved bills')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: c.busy ? null : () => upload(context, c),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload bill'),
        ),
        ...grouped.map((t) => Card(
            child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(t.name),
                subtitle: Text(
                    '${t.driverName ?? 'Choose driver'}\n${t.entryMode == 'manual' ? '${t.siteCount} sites' : t.bills.where((b) => !b.duplicate).map((b) => b.number).join(' · ')}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) =>
                            TripPage(controller: c, tripId: t.id)))))),
        if (bills.any((b) => !linked.contains(b.id)))
          const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text('Other bills',
                  style: TextStyle(fontWeight: FontWeight.w700))),
        ...bills.where((b) => !linked.contains(b.id)).map(
              (b) => Card(
                child: ListTile(
                  title: Text(b.draft?.documentNumber ?? b.fileName),
                  subtitle: Text(
                    b.draft?.consigneeName ?? b.companyName ?? 'Check bill',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    b.draft?.workflowStatus == 'cancelled'
                        ? 'Cancelled'
                        : b.draft?.stockStatus == 'applied'
                            ? 'Recorded'
                            : 'Check',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          SimpleBillPage(controller: c, billId: b.id),
                    ),
                  ),
                ),
              ),
            ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recent bills · Original PDFs are kept for 24 hours. Bill records stay saved.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

String requestUuid() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final s = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

class SimpleBillPage extends StatefulWidget {
  const SimpleBillPage({
    super.key,
    required this.controller,
    required this.billId,
  });
  final AppController controller;
  final String billId;
  @override
  State<SimpleBillPage> createState() => _BillPageState();
}

class _BillPageState extends State<SimpleBillPage> {
  AppController get controller => widget.controller;
  String get billId => widget.billId;
  @override
  void initState() {
    super.initState();
    controller.activeBillId = billId;
    unawaited(controller.loadBill(billId));
  }

  @override
  void dispose() {
    if (controller.activeBillId == billId) controller.activeBillId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final bill = controller.billById(billId);
          if (bill == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Bill')),
              body: Center(
                  child: TextButton(
                      onPressed: () => controller.loadBill(billId),
                      child: Text(controller.error ?? 'Loading bill…'))),
            );
          }
          final b = bill, d = b.draft, c = controller;
          return Scaffold(
            appBar: AppBar(title: Text(d?.documentNumber ?? 'Bill'), actions: [
              if (d != null && d.workflowStatus != 'cancelled')
                IconButton(
                    tooltip: 'Edit bill number',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: c.busy
                        ? null
                        : () async {
                            final value = await askText(context, 'Bill number',
                                initial: d.documentNumber);
                            if (value != null &&
                                value.isNotEmpty &&
                                context.mounted) {
                              await saveAction(
                                  context,
                                  c,
                                  (token) => c.api.editBill(token, {
                                        'action': 'number',
                                        'draftId': d.id,
                                        'value': value,
                                        'requestId': requestUuid()
                                      }));
                            }
                          })
            ]),
            body: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  d?.consigneeName ?? b.companyName ?? b.fileName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  d?.workflowStatus == 'cancelled'
                      ? 'Cancelled'
                      : d?.stockStatus == 'applied'
                          ? 'Saved · Stock updated'
                          : 'Check bill · Stock not confirmed',
                ),
                if (d != null) ...[
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.vehicleNumber ?? 'Add vehicle'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: c.busy || d.workflowStatus == 'cancelled'
                        ? null
                        : () async {
                            final value = await askText(
                              context,
                              'Vehicle',
                              initial: d.vehicleNumber,
                            );
                            if (value != null &&
                                value.isNotEmpty &&
                                context.mounted) {
                              await saveAction(
                                context,
                                c,
                                (token) => c.api.editBill(token, {
                                  'action': 'vehicle',
                                  'requestId': requestUuid(),
                                  'draftId': d.id,
                                  'value': value,
                                }),
                              );
                            }
                          },
                  ),
                  if (d.destination != null) Text(d.destination!),
                  const Divider(height: 30),
                  ...d.items.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.description),
                      subtitle: Text(
                        '${qty(item.quantity ?? 0)} ${item.unit ?? ''}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: c.busy || d.workflowStatus == 'cancelled'
                          ? null
                          : () async {
                              final value = await askText(
                                context,
                                'Quantity (${item.unit ?? ''})',
                                initial: item.quantity?.toString(),
                                number: true,
                              );
                              final quantity = double.tryParse(value ?? '');
                              if (quantity != null &&
                                  quantity > 0 &&
                                  context.mounted) {
                                await saveAction(
                                  context,
                                  c,
                                  (token) => c.api.editBill(token, {
                                    'action': 'quantity',
                                    'draftId': d.id,
                                    'itemId': item.id,
                                    'quantity': quantity,
                                    'requestId': requestUuid(),
                                  }),
                                );
                              }
                            },
                    ),
                  ),
                  if (d.canApprove)
                    FilledButton(
                      onPressed: c.busy
                          ? null
                          : () => saveAction(
                                context,
                                c,
                                (token) => c.api.approveBill(token, b.id),
                              ),
                      child: const Text('Confirm bill'),
                    ),
                  if (d.workflowStatus != 'cancelled' &&
                      d.stockStatus != 'applied')
                    TextButton(
                      onPressed: c.busy
                          ? null
                          : () => saveAction(
                                context,
                                c,
                                (token) => c.api.parseBill(token, b.id),
                              ),
                      child: const Text('Check again'),
                    ),
                  if (d.workflowStatus != 'cancelled')
                    TextButton(
                      onPressed: c.busy
                          ? null
                          : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Cancel bill?'),
                                  content: const Text(
                                    'Stock will be restored. The old record stays saved.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Keep bill'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Cancel bill'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                await saveAction(
                                  context,
                                  c,
                                  (token) => c.api.editBill(token, {
                                    'action': 'cancel',
                                    'requestId': requestUuid(),
                                    'draftId': d.id,
                                  }),
                                );
                              }
                            },
                      child: const Text('Cancel bill'),
                    ),
                ],
                if (b.storageAvailable)
                  TextButton.icon(
                    onPressed: c.busy
                        ? null
                        : () => BillDetailScreen(
                              controller: c,
                              billId: b.id,
                            ).openPdf(context, b),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Open PDF'),
                  ),
              ],
            ),
          );
        },
      );
}
