import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_controller.dart';
import 'models.dart';

const appPurple = Color(0xFF635BDF);

class CompanySnapshot {
  const CompanySnapshot({
    required this.company,
    required this.bills,
    required this.dispatches,
    required this.balances,
  });

  final StockCompany company;
  final List<Bill> bills;
  final List<DispatchRecord> dispatches;
  final List<StockBalance> balances;

  int get pendingReview => bills.where((bill) {
        final draft = bill.draft;
        return draft != null &&
            (draft.workflowStatus == 'review_required' ||
                draft.parseStatus == 'ready_for_review' ||
                draft.parseStatus == 'needs_review');
      }).length;

  factory CompanySnapshot.fromData(BootstrapData data, StockCompany company) {
    return CompanySnapshot(
      company: company,
      bills: data.bills.where((bill) => bill.companyId == company.id).toList(),
      dispatches: data.dispatches
          .where((dispatch) => dispatch.companyId == company.id)
          .toList(),
      balances: data.stock.balances
          .where((balance) => balance.companyId == company.id)
          .toList(),
    );
  }
}

class CompanyFilterField extends StatelessWidget {
  const CompanyFilterField({
    super.key,
    required this.companies,
    required this.selectedCompanyId,
    required this.onChanged,
  });

  final List<StockCompany> companies;
  final String? selectedCompanyId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedCompanyId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Company',
        prefixIcon: Icon(Icons.business_outlined),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            'All companies',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...companies.map(
          (company) => DropdownMenuItem<String?>(
            value: company.id,
            child: Text(
              company.name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
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
    BuildContext context,
    Future<void> Function(String) request,
  ) async {
    final message = await controller.runMutation(request);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? 'Updated successfully')));
  }

  Future<void> openPdf(BuildContext context, Bill bill) async {
    final message = await controller.runMutation((token) async {
      final url = await controller.api.mediaUrl(token, bill.id);
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Unable to open PDF');
    });
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
                    Text(
                      draft?.supplierName ?? bill.senderName ?? 'WhatsApp bill',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(bill.fileName),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusPill(text: bill.processingStatus),
                        if (draft != null)
                          StatusPill(text: draft.workflowStatus),
                        if (draft != null) StatusPill(text: draft.stockStatus),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${dateTime(bill.receivedAt)} · ${bill.senderPhoneMasked}',
                      style: muted(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (bill.storageAvailable)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.busy
                            ? null
                            : () => openPdf(context, bill),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Open PDF'),
                      ),
                    ),
                  if (bill.storageAvailable) const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.busy
                          ? null
                          : () => action(
                                context,
                                (token) =>
                                    controller.api.parseBill(token, bill.id),
                              ),
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
                          : () => action(
                                context,
                                (token) =>
                                    controller.api.approveBill(token, bill.id),
                              ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve parsed data'),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const SectionTitle(title: 'Document'),
                const SizedBox(height: 10),
                DetailsGrid(
                  items: [
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
                  ],
                ),
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
                  ...draft.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SurfaceCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: appPurple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (item.hsnSac != null)
                                        'HSN ${item.hsnSac}',
                                      if (item.quantity != null)
                                        '${qty(item.quantity!)} ${item.unit ?? ''}',
                                      if (item.rate != null)
                                        'Rate ${money(item.rate)}',
                                    ].join(' · '),
                                    style: muted(context),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              money(item.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SurfaceCard(
                  child: Column(
                    children: [
                      AmountRow(label: 'Taxable', value: draft.taxableAmount),
                      AmountRow(label: 'CGST', value: draft.cgstAmount),
                      AmountRow(label: 'SGST', value: draft.sgstAmount),
                      const Divider(height: 24),
                      AmountRow(
                        label: 'Total',
                        value: draft.totalAmount,
                        strong: true,
                      ),
                    ],
                  ),
                ),
                if (draft.missingFields.isNotEmpty ||
                    draft.parseError != null ||
                    draft.stockError != null) ...[
                  const SizedBox(height: 14),
                  ErrorBox(
                    message: [
                      if (draft.missingFields.isNotEmpty)
                        'Missing: ${draft.missingFields.join(', ')}',
                      if (draft.parseError != null) draft.parseError!,
                      if (draft.stockError != null) draft.stockError!,
                    ].join('\\n'),
                  ),
                ],
              ],
            ],
          ),
        );
      },
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
        final items = controller.conversations;
        return Scaffold(
          appBar: AppBar(
            title: const Text('WhatsApp'),
            actions: [
              IconButton(
                onPressed: controller.loadConversations,
                icon: const Icon(Icons.refresh_rounded),
              ),
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
                    final latest =
                        item.timeline.isEmpty ? null : item.timeline.last;
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
                              (item.senderName ?? 'W')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: appPurple,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.senderName ?? 'WhatsApp sender',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: muted(context),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.senderPhoneMasked,
                                  style: muted(context),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat(
                              'h:mm a',
                            ).format(item.latestReceivedAt.toLocal()),
                            style: muted(context),
                          ),
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
    for (final item in widget.controller.conversations) {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Reply sent')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final item = conversation();
        if (item == null) {
          return const Scaffold(
            body: Center(child: Text('Conversation unavailable')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.senderName ?? 'WhatsApp sender'),
                Text(
                  item.senderPhoneMasked,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: item.timeline.length,
                  itemBuilder: (context, index) {
                    final event =
                        item.timeline[item.timeline.length - 1 - index];
                    return Align(
                      alignment: event.inbound
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: event.inbound
                              ? Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh
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
                                  const Icon(
                                    Icons.picture_as_pdf_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(event.fileName!)),
                                ],
                              )
                            else
                              Text(
                                event.inbound
                                    ? (event.textBody ??
                                        event.messageType ??
                                        'Message')
                                    : (event.body ?? 'Message'),
                              ),
                            const SizedBox(height: 5),
                            Text(
                              DateFormat(
                                    'h:mm a',
                                  ).format(event.time.toLocal()) +
                                  (!event.inbound && event.status != null
                                      ? ' · ${event.status}'
                                      : ''),
                              style: const TextStyle(fontSize: 10),
                            ),
                            if (event.errorMessage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                event.errorMessage!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
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
                              onPressed: widget.controller.busy
                                  ? null
                                  : () => send(item),
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

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.productName,
    required this.unit,
    required this.currentQuantity,
  });

  final String productName;
  final String unit;
  final double currentQuantity;

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  late final TextEditingController quantityController;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(
      text: qty(widget.currentQuantity),
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  void submit() {
    final value = double.tryParse(quantityController.text.trim());
    if (value == null || value < 0) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust ${widget.productName}'),
      content: TextField(
        controller: quantityController,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          labelText: 'Current physical quantity (${widget.unit})',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: submit, child: const Text('Save')),
      ],
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
            const Text(
              'Add stock',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: companyId,
              decoration: const InputDecoration(labelText: 'Existing company'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Create new company'),
                ),
                ...widget.companies.map(
                  (company) => DropdownMenuItem<String?>(
                    value: company.id,
                    child: Text(company.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => companyId = value),
            ),
            if (companyId == null) ...[
              const SizedBox(height: 10),
              TextField(
                controller: companyName,
                decoration: const InputDecoration(labelText: 'Company name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: gstin,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Company GSTIN'),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: product,
              decoration: const InputDecoration(labelText: 'Product name'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const ['NOS', 'PCS', 'SET', 'BOX']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => unit = value ?? 'NOS'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: hsn,
                    decoration: const InputDecoration(labelText: 'HSN / SAC'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Current stock'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allowCompany,
              onChanged: (value) =>
                  setState(() => allowCompany = value ?? false),
              title: const Text('Similar company is genuinely different'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allowProduct,
              onChanged: (value) =>
                  setState(() => allowProduct = value ?? false),
              title: const Text('Similar product is genuinely different'),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submit,
                child: const Text('Save stock'),
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final good = const {
      'recorded',
      'approved',
      'stored',
      'verified',
      'sent',
      'delivered',
      'read',
      'adjusted',
    }.contains(text);
    final color = good ? const Color(0xFF168966) : appPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: muted(context)),
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
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: SurfaceCard(
                    child: LabeledText(label: item.$1, value: item.$2 ?? '—'),
                  ),
                ),
              )
              .toList(),
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
          Text(
            label,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            money(value),
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              fontSize: strong ? 18 : 14,
            ),
          ),
        ],
      );
}

Future<void> openBill(
  BuildContext context,
  AppController controller,
  String billId,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillDetailScreen(controller: controller, billId: billId),
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
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ).format(value);
}

String qty(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(3);
