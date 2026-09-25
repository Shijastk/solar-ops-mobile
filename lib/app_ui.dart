
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_controller.dart';
import 'models.dart';

const appPurple = Color(0xFF635BDF);

class SolarOpsRoot extends StatefulWidget {
  const SolarOpsRoot({super.key});

  @override
  State<SolarOpsRoot> createState() => _SolarOpsRootState();
}

class _SolarOpsRootState extends State<SolarOpsRoot> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.initializing) return const SplashScreen();
        if (!controller.signedIn) return LoginScreen(controller: controller);
        return AppShell(controller: controller);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.solar_power_rounded, size: 54, color: appPurple),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final keyController = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final key = keyController.text.trim();
    if (key.isEmpty) return;
    FocusScope.of(context).unfocus();
    await widget.controller.login(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: appPurple.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.solar_power_rounded,
                        color: appPurple, size: 30),
                  ),
                  const SizedBox(height: 24),
                  const Text('Solar Ops',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2)),
                  const SizedBox(height: 8),
                  Text(
                    'Use the same operations access key as the web dashboard.',
                    style: muted(context),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: keyController,
                    obscureText: obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      labelText: 'Operations access key',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                    ),
                  ),
                  if (widget.controller.error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBox(message: widget.controller.error!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.controller.busy ? null : submit,
                      child: widget.controller.busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Sign in'),
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
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.controller.data;
    if (data == null) {
      return Scaffold(
        body: Center(
          child: FilledButton.icon(
            onPressed: widget.controller.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload Solar Ops'),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: [
            DashboardScreen(controller: widget.controller, data: data),
            BillsScreen(controller: widget.controller),
            DispatchScreen(controller: widget.controller),
            StockScreen(controller: widget.controller),
            MoreScreen(controller: widget.controller),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 72,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Bills'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Dispatch'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.data,
  });

  final AppController controller;
  final BootstrapData data;

  @override
  Widget build(BuildContext context) {
    final dashboard = controller.data?.dashboard ?? data.dashboard;
    final live = controller.data ?? data;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          AppHeader(
            title: 'Solar Ops',
            subtitle: live.runtime.healthy ? 'Live operations' : 'Check server config',
            healthy: live.runtime.healthy,
            onRefresh: controller.refresh,
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(message: controller.error!),
          ],
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricCard(width: width, icon: Icons.receipt_long_outlined,
                      value: dashboard.billsToday.toString(), label: 'Bills today'),
                  MetricCard(width: width, icon: Icons.fact_check_outlined,
                      value: dashboard.pendingReview.toString(), label: 'Pending review'),
                  MetricCard(width: width, icon: Icons.verified_outlined,
                      value: dashboard.recorded.toString(), label: 'Recorded'),
                  MetricCard(width: width, icon: Icons.inventory_2_outlined,
                      value: dashboard.stockProducts.toString(), label: 'Stock products'),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Last 7 days'),
          const SizedBox(height: 12),
          DailyChart(items: dashboard.dailyBills),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Recent bills'),
          const SizedBox(height: 10),
          if (live.bills.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bills yet',
              body: 'Incoming WhatsApp PDFs will appear here.',
            )
          else
            ...live.bills.take(4).map((bill) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BillTile(
                bill: bill,
                onTap: () => openBill(context, controller, bill.id),
              ),
            )),
          const SizedBox(height: 16),
          StatusStrip(
            label: 'WhatsApp inbound',
            value: '${dashboard.inboundMessages} loaded',
            positive: live.runtime.healthy,
          ),
          const SizedBox(height: 10),
          StatusStrip(
            label: 'Automation',
            value: live.runtime.automationEnabled
                ? (live.runtime.automationReady ? 'Ready' : 'Not ready')
                : 'Disabled',
            positive: !live.runtime.automationEnabled || live.runtime.automationReady,
          ),
        ],
      ),
    );
  }
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final source = widget.controller.data?.bills ?? const <Bill>[];
    final q = query.trim().toLowerCase();
    final bills = source.where((bill) {
      if (q.isEmpty) return true;
      return [
        bill.fileName,
        bill.senderName,
        bill.draft?.supplierName,
        bill.draft?.documentNumber,
        bill.draft?.vehicleNumber,
        bill.draft?.destination,
      ].whereType<String>().any((value) => value.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          AppHeader(
            title: 'Bills',
            subtitle: '${source.length} PDFs from WhatsApp',
            onRefresh: widget.controller.refresh,
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search company, bill, vehicle...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (bills.isEmpty)
            const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching bills',
              body: 'Try a different search.',
            )
          else
            ...bills.map((bill) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: BillTile(
                bill: bill,
                onTap: () => openBill(context, widget.controller, bill.id),
              ),
            )),
        ],
      ),
    );
  }
}

Future<void> openBill(
    BuildContext context, AppController controller, String billId) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillDetailScreen(controller: controller, billId: billId),
    ),
  );
}

class BillDetailScreen extends StatelessWidget {
  const BillDetailScreen({
    super.key,
    required this.controller,
    required this.billId,
  });

  final AppController controller;
  final String billId;

  Bill? findBill() {
    for (final bill in controller.data?.bills ?? const <Bill>[]) {
      if (bill.id == billId) return bill;
    }
    return null;
  }

  Future<void> action(
      BuildContext context, Future<void> Function(String) request) async {
    final message = await controller.runMutation(request);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Updated successfully')),
    );
  }

  Future<void> openPdf(BuildContext context, Bill bill) async {
    final message = await controller.runMutation((token) async {
      final url = await controller.api.mediaUrl(token, bill.id);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Unable to open PDF');
    });
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bill = findBill();
        if (bill == null) {
          return const Scaffold(body: Center(child: Text('Bill unavailable')));
        }
        final draft = bill.draft;

        return Scaffold(
          appBar: AppBar(title: const Text('Bill details')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
            children: [
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(draft?.supplierName ?? bill.senderName ?? 'WhatsApp bill',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(bill.fileName),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(text: bill.processingStatus),
                        if (draft != null) StatusPill(text: draft.workflowStatus),
                        if (draft != null) StatusPill(text: draft.stockStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('${dateTime(bill.receivedAt)} · ${bill.senderPhoneMasked}',
                        style: muted(context)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (bill.storageAvailable)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.busy ? null : () => openPdf(context, bill),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Open PDF'),
                      ),
                    ),
                  if (bill.storageAvailable) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => action(context,
                              (token) => controller.api.parseBill(token, bill.id)),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(draft == null ? 'Parse bill' : 'Parse again'),
                    ),
                  ),
                ],
              ),
              if (draft == null) ...[
                const SizedBox(height: 22),
                const EmptyState(
                  icon: Icons.document_scanner_outlined,
                  title: 'No parsed data yet',
                  body: 'Run Parse bill to extract structured data.',
                ),
              ] else ...[
                if (draft.canApprove) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => action(context,
                              (token) => controller.api.approveBill(token, bill.id)),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve parsed data'),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const SectionTitle(title: 'Document'),
                const SizedBox(height: 10),
                DetailsGrid(items: [
                  ('Document no.', draft.documentNumber),
                  ('Date', draft.documentDate),
                  ('e-Way bill', draft.ewayBillNumber),
                  ('Vehicle', draft.vehicleNumber),
                  ('Destination', draft.destination),
                  ('Supplier GSTIN', draft.supplierGstin),
                  ('Consignee', draft.consigneeName),
                  ('Consignee GSTIN', draft.consigneeGstin),
                  ('Buyer', draft.buyerName),
                  ('Buyer GSTIN', draft.buyerGstin),
                ]),
                if (draft.consigneeAddress != null) ...[
                  const SizedBox(height: 10),
                  SurfaceCard(
                    child: LabeledText(
                      label: 'Consignee address',
                      value: draft.consigneeAddress!,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const SectionTitle(title: 'Products'),
                const SizedBox(height: 10),
                if (draft.items.isEmpty)
                  const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No product lines',
                    body: 'The parser did not return product rows.',
                  )
                else
                  ...draft.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurfaceCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: appPurple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description,
                                    style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (item.hsnSac != null) 'HSN ${item.hsnSac}',
                                    if (item.quantity != null)
                                      '${qty(item.quantity!)} ${item.unit ?? ''}',
                                    if (item.rate != null) 'Rate ${money(item.rate)}',
                                  ].join(' · '),
                                  style: muted(context),
                                ),
                              ],
                            ),
                          ),
                          Text(money(item.amount),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  )),
                const SizedBox(height: 8),
                SurfaceCard(
                  child: Column(
                    children: [
                      AmountRow(label: 'Taxable', value: draft.taxableAmount),
                      AmountRow(label: 'CGST', value: draft.cgstAmount),
                      AmountRow(label: 'SGST', value: draft.sgstAmount),
                      const Divider(height: 24),
                      AmountRow(label: 'Total', value: draft.totalAmount, strong: true),
                    ],
                  ),
                ),
                if (draft.missingFields.isNotEmpty ||
                    draft.parseError != null ||
                    draft.stockError != null) ...[
                  const SizedBox(height: 14),
                  ErrorBox(message: [
                    if (draft.missingFields.isNotEmpty)
                      'Missing: ${draft.missingFields.join(', ')}',
                    if (draft.parseError != null) draft.parseError!,
                    if (draft.stockError != null) draft.stockError!,
                  ].join('\\n')),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final source = widget.controller.data?.dispatches ?? const <DispatchRecord>[];
    final q = query.toLowerCase().trim();
    final rows = source.where((item) {
      if (q.isEmpty) return true;
      return [
        item.documentNumber,
        item.companyName,
        item.destination,
        item.consigneeName,
        item.vehicleNumber,
      ].whereType<String>().any((value) => value.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          AppHeader(
            title: 'Dispatch',
            subtitle: '${source.length} parsed dispatch records',
            onRefresh: widget.controller.refresh,
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search vehicle, company, destination...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No dispatch records',
              body: 'Parsed bills with dispatch data will appear here.',
            )
          else
            ...rows.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, color: appPurple),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.documentNumber ?? item.fileName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        StatusPill(text: item.workflowStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.companyName ?? 'Company not parsed',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (item.consigneeName != null) item.consigneeName!,
                        if (item.destination != null) item.destination!,
                      ].join(' · '),
                      style: muted(context),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.pin_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(item.vehicleNumber ?? 'Vehicle not parsed'),
                        const Spacer(),
                        StatusPill(text: item.stockStatus),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String query = '';

  Future<void> adjust(StockBalance balance) async {
    final field = TextEditingController(text: qty(balance.currentQuantity));
    final target = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust ${balance.productName}'),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Current physical quantity (${balance.unit})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(field.text.trim());
              if (value != null && value >= 0) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    field.dispose();
    if (target == null || !mounted) return;

    final message = await widget.controller.runMutation(
      (token) => widget.controller.api.adjustStock(
        token: token,
        productId: balance.productId,
        targetQuantity: target,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message ?? 'Stock updated')));
    }
  }

  Future<void> addOpening() async {
    final stock = widget.controller.data?.stock;
    if (stock == null) return;
    final input = await showModalBottomSheet<OpeningStockInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => OpeningStockSheet(companies: stock.companies),
    );
    if (input == null || !mounted) return;

    final message = await widget.controller.runMutation(
      (token) => widget.controller.api.addOpeningStock(
        token: token,
        companyId: input.companyId,
        companyName: input.companyName,
        companyGstin: input.companyGstin,
        productName: input.productName,
        unit: input.unit,
        hsnSac: input.hsnSac,
        quantity: input.quantity,
        allowSimilarCompany: input.allowSimilarCompany,
        allowSimilarProduct: input.allowSimilarProduct,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Opening stock added')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.controller.data?.stock ??
        const StockData(companies: [], balances: []);
    final q = query.toLowerCase().trim();
    final balances = stock.balances.where((item) {
      if (q.isEmpty) return true;
      return [
        item.companyName,
        item.productName,
        item.hsnSac,
        item.companyGstin,
      ].whereType<String>().any((value) => value.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          AppHeader(
            title: 'Stock',
            subtitle: '${stock.balances.length} configured products',
            onRefresh: widget.controller.refresh,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: widget.controller.busy ? null : addOpening,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add opening stock'),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search product or company...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (balances.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No stock products',
              body: 'Add opening stock to create the first ledger product.',
            )
          else
            ...balances.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: appPurple.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: appPurple),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(
                            '${item.companyName}${item.hsnSac == null ? '' : ' · HSN ${item.hsnSac}'}',
                            style: muted(context),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${qty(item.currentQuantity)} ${item.unit}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        TextButton(
                          onPressed: widget.controller.busy ? null : () => adjust(item),
                          child: const Text('Adjust'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        const AppHeader(title: 'More', subtitle: 'Messages and settings'),
        const SizedBox(height: 18),
        MenuTile(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'WhatsApp conversations',
          subtitle: '${data?.conversations.length ?? 0} conversations',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationsScreen(controller: controller),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (data != null)
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connection',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                const SizedBox(height: 10),
                InfoRow(label: 'API',
                    value: data.runtime.healthy ? 'Healthy' : 'Check config'),
                InfoRow(label: 'Last synced', value: dateTime(data.generatedAt)),
                InfoRow(
                  label: 'Session expires',
                  value: data.sessionExpiresAt == null
                      ? 'Unknown'
                      : dateTime(data.sessionExpiresAt!),
                ),
                InfoRow(
                  label: 'Automation',
                  value: data.runtime.automationEnabled
                      ? (data.runtime.automationReady ? 'Ready' : 'Not ready')
                      : 'Disabled',
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        MenuTile(
          icon: Icons.logout_rounded,
          title: 'Sign out',
          subtitle: 'Remove the saved mobile session',
          onTap: controller.logout,
        ),
      ],
    );
  }
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final items = controller.data?.conversations ?? const <Conversation>[];
        return Scaffold(
          appBar: AppBar(
            title: const Text('WhatsApp'),
            actions: [
              IconButton(onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          body: items.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations',
                  body: 'Incoming WhatsApp messages will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final latest = item.timeline.isEmpty ? null : item.timeline.last;
                    final preview = latest == null
                        ? 'Message'
                        : latest.inbound
                            ? (latest.textBody ??
                                latest.fileName ??
                                latest.messageType ??
                                'Message')
                            : (latest.body ?? 'Message');
                    return SurfaceCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(
                            controller: controller,
                            conversationKey: item.key,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: appPurple.withValues(alpha: .12),
                            child: Text(
                              (item.senderName ?? 'W').substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  color: appPurple, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.senderName ?? 'WhatsApp sender',
                                    style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text(preview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: muted(context)),
                                const SizedBox(height: 3),
                                Text(item.senderPhoneMasked, style: muted(context)),
                              ],
                            ),
                          ),
                          Text(DateFormat('h:mm a')
                              .format(item.latestReceivedAt.toLocal()),
                              style: muted(context)),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.controller,
    required this.conversationKey,
  });

  final AppController controller;
  final String conversationKey;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final reply = TextEditingController();

  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  Conversation? conversation() {
    for (final item in widget.controller.data?.conversations ?? const <Conversation>[]) {
      if (item.key == widget.conversationKey) return item;
    }
    return null;
  }

  Future<void> send(Conversation item) async {
    final messageId = item.latestInboundMessageId;
    final body = reply.text.trim();
    if (messageId == null || body.isEmpty) return;
    final error = await widget.controller.runMutation(
      (token) => widget.controller.api.sendReply(
        token: token,
        messageId: messageId,
        body: body,
      ),
    );
    if (!mounted) return;
    if (error == null) reply.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error ?? 'Reply sent')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final item = conversation();
        if (item == null) {
          return const Scaffold(body: Center(child: Text('Conversation unavailable')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.senderName ?? 'WhatsApp sender'),
                Text(item.senderPhoneMasked,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  itemCount: item.timeline.length,
                  itemBuilder: (context, index) {
                    final event = item.timeline[index];
                    return Align(
                      alignment: event.inbound
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .78),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: event.inbound
                              ? Theme.of(context).colorScheme.surfaceContainerHigh
                              : appPurple.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event.inbound && event.fileName != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf_outlined, size: 18),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(event.fileName!)),
                                ],
                              )
                            else
                              Text(event.inbound
                                  ? (event.textBody ?? event.messageType ?? 'Message')
                                  : (event.body ?? 'Message')),
                            const SizedBox(height: 5),
                            Text(
                              DateFormat('h:mm a').format(event.time.toLocal()) +
                                  (!event.inbound && event.status != null
                                      ? ' · ${event.status}'
                                      : ''),
                              style: const TextStyle(fontSize: 10),
                            ),
                            if (event.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(event.errorMessage!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.error)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: item.canReply
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: reply,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                  hintText: 'Reply on WhatsApp...',
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: widget.controller.busy ? null : () => send(item),
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        )
                      : SurfaceCard(
                          child: Text(
                            'Free-form reply unavailable: the 24-hour WhatsApp service window is closed.',
                            textAlign: TextAlign.center,
                            style: muted(context),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OpeningStockInput {
  const OpeningStockInput({
    this.companyId,
    this.companyName,
    this.companyGstin,
    required this.productName,
    required this.unit,
    this.hsnSac,
    required this.quantity,
    required this.allowSimilarCompany,
    required this.allowSimilarProduct,
  });

  final String? companyId;
  final String? companyName;
  final String? companyGstin;
  final String productName;
  final String unit;
  final String? hsnSac;
  final double quantity;
  final bool allowSimilarCompany;
  final bool allowSimilarProduct;
}

class OpeningStockSheet extends StatefulWidget {
  const OpeningStockSheet({super.key, required this.companies});
  final List<StockCompany> companies;

  @override
  State<OpeningStockSheet> createState() => _OpeningStockSheetState();
}

class _OpeningStockSheetState extends State<OpeningStockSheet> {
  String? companyId;
  final companyName = TextEditingController();
  final gstin = TextEditingController();
  final product = TextEditingController();
  final hsn = TextEditingController();
  final quantityController = TextEditingController();
  String unit = 'NOS';
  bool allowCompany = false;
  bool allowProduct = false;

  @override
  void dispose() {
    companyName.dispose();
    gstin.dispose();
    product.dispose();
    hsn.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void submit() {
    final amount = double.tryParse(quantityController.text.trim());
    if (product.text.trim().isEmpty || amount == null || amount <= 0) return;
    if (companyId == null &&
        (companyName.text.trim().isEmpty || gstin.text.trim().isEmpty)) {
      return;
    }
    Navigator.pop(
      context,
      OpeningStockInput(
        companyId: companyId,
        companyName: companyId == null ? companyName.text.trim() : null,
        companyGstin: companyId == null ? gstin.text.trim() : null,
        productName: product.text.trim(),
        unit: unit,
        hsnSac: hsn.text.trim().isEmpty ? null : hsn.text.trim(),
        quantity: amount,
        allowSimilarCompany: allowCompany,
        allowSimilarProduct: allowProduct,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add opening stock',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: companyId,
              decoration: const InputDecoration(labelText: 'Existing company'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Create new company')),
                ...widget.companies.map((company) => DropdownMenuItem<String?>(
                      value: company.id,
                      child: Text(company.name),
                    )),
              ],
              onChanged: (value) => setState(() => companyId = value),
            ),
            if (companyId == null) ...[
              const SizedBox(height: 10),
              TextField(controller: companyName,
                  decoration: const InputDecoration(labelText: 'Company name')),
              const SizedBox(height: 10),
              TextField(controller: gstin,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Company GSTIN')),
            ],
            const SizedBox(height: 10),
            TextField(controller: product,
                decoration: const InputDecoration(labelText: 'Product name')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const ['NOS', 'PCS', 'SET', 'BOX']
                        .map((item) =>
                            DropdownMenuItem(value: item, child: Text(item)))
                        .toList(),
                    onChanged: (value) => setState(() => unit = value ?? 'NOS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(controller: hsn,
                      decoration: const InputDecoration(labelText: 'HSN / SAC')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Opening quantity'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allowCompany,
              onChanged: (value) => setState(() => allowCompany = value ?? false),
              title: const Text('Similar company is genuinely different'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allowProduct,
              onChanged: (value) => setState(() => allowProduct = value ?? false),
              title: const Text('Similar product is genuinely different'),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: submit, child: const Text('Add opening stock')),
            ),
          ],
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.healthy,
    this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool? healthy;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: appPurple.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.solar_power_rounded, color: appPurple),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.6)),
              Row(
                children: [
                  if (healthy != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: healthy! ? const Color(0xFF168966) : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(child: Text(subtitle, style: muted(context))),
                ],
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton.filledTonal(
              onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.width,
    required this.icon,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: appPurple),
            const SizedBox(height: 15),
            Text(value,
                style: const TextStyle(
                    fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 3),
            Text(label, style: muted(context)),
          ],
        ),
      ),
    );
  }
}

class DailyChart extends StatelessWidget {
  const DailyChart({super.key, required this.items});
  final List<DailyBillCount> items;

  @override
  Widget build(BuildContext context) {
    final maxCount = items.fold<int>(
        1, (max, item) => item.count > max ? item.count : max);
    return SurfaceCard(
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: items.map((item) {
            final ratio = item.count / maxCount;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(item.count.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    height: 110 * ratio + 8,
                    width: 20,
                    decoration: BoxDecoration(
                      color: appPurple,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(item.label, style: muted(context)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BillTile extends StatelessWidget {
  const BillTile({super.key, required this.bill, required this.onTap});
  final Bill bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final draft = bill.draft;
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: appPurple.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined, color: appPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(draft?.supplierName ?? bill.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (draft?.documentNumber != null) draft!.documentNumber!,
                    if (draft?.vehicleNumber != null) draft!.vehicleNumber!,
                    dateTime(bill.receivedAt),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(text: draft?.workflowStatus ?? bill.processingStatus),
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.4));
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final good = const {
      'recorded', 'approved', 'stored', 'verified',
      'sent', 'delivered', 'read', 'adjusted'
    }.contains(text);
    final color = good ? const Color(0xFF168966) : appPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text.replaceAll('_', ' '),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 42, color: appPurple),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: muted(context)),
          ],
        ),
      );
}

class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Row(
          children: [
            Icon(positive ? Icons.check_circle_outline : Icons.info_outline,
                color: positive ? const Color(0xFF168966) : Colors.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class DetailsGrid extends StatelessWidget {
  const DetailsGrid({super.key, required this.items});
  final List<(String, String?)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) => SizedBox(
            width: width,
            child: SurfaceCard(
              child: LabeledText(label: item.$1, value: item.$2 ?? '—'),
            ),
          )).toList(),
        );
      },
    );
  }
}

class LabeledText extends StatelessWidget {
  const LabeledText({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: muted(context)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double? value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w500)),
          const Spacer(),
          Text(money(value),
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                  fontSize: strong ? 18 : 14)),
        ],
      );
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: muted(context))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: appPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: muted(context)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
}

TextStyle muted(BuildContext context) => TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .58),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

String dateTime(DateTime value) =>
    DateFormat('dd MMM, h:mm a').format(value.toLocal());

String money(double? value) {
  if (value == null) return '—';
  return NumberFormat.currency(
          locale: 'en_IN', symbol: '₹', decimalDigits: 2)
      .format(value);
}

String qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(3);
