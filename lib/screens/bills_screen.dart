import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../app_controller.dart';
import '../models.dart';
import '../widgets/common.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BillRecord> _filtered() {
    final bills = widget.controller.data!.bills;
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return bills;

    return bills.where((bill) {
      final draft = bill.draft;
      final values = [
        bill.fileName,
        bill.senderName ?? '',
        bill.senderPhoneMasked,
        draft?.documentNumber ?? '',
        draft?.supplierName ?? '',
        draft?.vehicleNumber ?? '',
        draft?.destination ?? '',
      ].join(' ').toLowerCase();
      return values.contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bills = _filtered();

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeader(
              title: 'Bills',
              subtitle: 'Real inbound PDF documents from WhatsApp',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search file, company, document, vehicle…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          if (bills.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: _search.text.trim().isEmpty
                    ? 'No real PDF bills yet'
                    : 'No matching bills',
                message: _search.text.trim().isEmpty
                    ? 'Bills appear here only after a real PDF is captured by the WhatsApp backend.'
                    : 'Try a different search term.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _BillCard(
                    bill: bill,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BillDetailScreen(
                          controller: widget.controller,
                          billId: bill.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill, required this.onTap});

  final BillRecord bill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final draft = bill.draft;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft?.documentNumber ?? bill.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    draft?.supplierName ??
                        bill.senderName ??
                        bill.senderPhoneMasked,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusPill(
                        status:
                            draft?.workflowStatus ?? bill.processingStatus,
                      ),
                      if (draft != null)
                        StatusPill(status: draft.stockStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDateTime(bill.receivedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({
    super.key,
    required this.controller,
    required this.billId,
  });

  final AppController controller;
  final String billId;

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  BillRecord? get _bill {
    final data = widget.controller.data;
    if (data == null) return null;
    for (final bill in data.bills) {
      if (bill.id == widget.billId) return bill;
    }
    return null;
  }

  Future<void> _run(
    Future<String> Function() action,
  ) async {
    try {
      final message = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The operation failed.')),
      );
    }
  }

  Future<void> _viewPdf() async {
    final bill = _bill;
    if (bill == null) return;
    try {
      final url = await widget.controller.getMediaUrl(bill.id);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        throw const ApiException('Unable to open the PDF on this device.');
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final bill = _bill;
        if (bill == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bill')),
            body: const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Bill is unavailable',
              message: 'Refresh the operations data and try again.',
            ),
          );
        }

        final draft = bill.draft;
        final canApprove = draft?.parseStatus == 'ready_for_review' &&
            draft?.workflowStatus != 'cancelled';

        return Scaffold(
          appBar: AppBar(
            title: Text(draft?.documentNumber ?? 'Bill details'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.fileName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(bill.receivedAt),
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        StatusPill(status: bill.processingStatus),
                        if (draft != null)
                          StatusPill(status: draft.parseStatus),
                        if (draft != null)
                          StatusPill(status: draft.workflowStatus),
                        if (draft != null)
                          StatusPill(status: draft.stockStatus),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (draft == null)
                const SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not parsed yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'No structured draft exists for this PDF. Parse the real stored document to extract bill fields.',
                      ),
                    ],
                  ),
                )
              else ...[
                _DraftDetails(draft: draft),
                const SizedBox(height: 12),
                if (draft.items.isNotEmpty)
                  _ItemsCard(items: draft.items),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (bill.storageAvailable)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          widget.controller.mutating ? null : _viewPdf,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View PDF'),
                    ),
                  ),
                if (bill.storageAvailable) const SizedBox(width: 8),
                if (bill.storageAvailable)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.controller.mutating
                          ? null
                          : () => _run(
                                () => widget.controller.parseBill(bill.id),
                              ),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(draft == null ? 'Parse' : 'Parse again'),
                    ),
                  ),
                if (canApprove) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.controller.mutating
                          ? null
                          : () => _run(
                                () => widget.controller.approveBill(bill.id),
                              ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DraftDetails extends StatelessWidget {
  const _DraftDetails({required this.draft});

  final BillDraft draft;

  @override
  Widget build(BuildContext context) {
    String value(String? text) => text ?? 'Not detected';

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parsed bill data',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          DataRowLine(label: 'Company', value: value(draft.supplierName)),
          DataRowLine(label: 'GSTIN', value: value(draft.supplierGstin)),
          DataRowLine(label: 'Document', value: value(draft.documentNumber)),
          DataRowLine(label: 'Date', value: value(draft.documentDate)),
          DataRowLine(label: 'e-Way bill', value: value(draft.ewayBillNumber)),
          DataRowLine(label: 'Consignee', value: value(draft.consigneeName)),
          DataRowLine(label: 'Destination', value: value(draft.destination)),
          DataRowLine(label: 'Vehicle', value: value(draft.vehicleNumber)),
          DataRowLine(label: 'Verification', value: statusLabel(draft.verificationStatus)),
          DataRowLine(label: 'Total', value: formatMoney(draft.totalAmount)),
          if (draft.missingFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Missing: ' + draft.missingFields.join(', '),
              style: const TextStyle(
                color: Color(0xFFC47A00),
                fontWeight: FontWeight.w650,
              ),
            ),
          ],
          if (draft.parseError != null) ...[
            const SizedBox(height: 8),
            Text(
              draft.parseError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w650,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});

  final List<BillItem> items;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (item.hsnSac != null)
                          Text(
                            'HSN ' + item.hsnSac!,
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.quantity == null
                            ? '—'
                            : formatQuantity(item.quantity!) +
                                (item.unit == null ? '' : ' ' + item.unit!),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        formatMoney(item.amount),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
