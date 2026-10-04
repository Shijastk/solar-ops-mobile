import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'api_client.dart';
import 'models.dart';
import 'request_id.dart';

class DraftPdf {
  DraftPdf(this.name, this.bytes) : requestId = requestUuid();
  final String name, requestId;
  final Uint8List bytes;
  String? messageId;
  bool duplicate = false;
}

Future<List<DraftPdf>> selectDraftPdfs() async {
  final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withReadStream: true);
  if (result == null) return [];
  final files = <DraftPdf>[];
  var total = 0;
  for (final file in result.files) {
    if (file.size > 4 * 1024 * 1024)
      throw const ApiException('Choose PDFs smaller than 4 MB');
    final builder = BytesBuilder(copy: false);
    if (file.bytes != null) {
      builder.add(file.bytes!);
    } else if (file.readStream != null) {
      await for (final chunk in file.readStream!) {
        builder.add(chunk);
        if (builder.length > 4 * 1024 * 1024)
          throw const ApiException('File too large');
      }
    } else {
      throw const ApiException('Could not read PDF');
    }
    total += builder.length;
    if (total > 24 * 1024 * 1024 || files.length >= 30)
      throw const ApiException('Choose up to 30 PDFs, 24 MB total');
    final bytes = builder.takeBytes();
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-')
      throw const ApiException('Choose a valid PDF');
    files.add(DraftPdf(file.name, bytes));
  }
  return files;
}

class BillTripDraftPage extends StatefulWidget {
  const BillTripDraftPage(
      {super.key, required this.controller, this.pickFiles = selectDraftPdfs});
  final AppController controller;
  final Future<List<DraftPdf>> Function() pickFiles;
  @override
  State<BillTripDraftPage> createState() => _BillTripDraftState();
}

class _BillTripDraftState extends State<BillTripDraftPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final requestId = requestUuid();
  final files = <DraftPdf>[];
  final existing = <Bill>[];
  String? companyId;
  Driver? driver;
  String? error, progress;
  bool saving = false, picking = false, allowPop = false, attemptedSave = false;
  Map<String, dynamic>? committedRequest;
  AppController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    companyId = c.selectedCompanyId ??
        (c.data!.stock.companies.length == 1
            ? c.data!.stock.companies.single.id
            : null);
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> addFiles() async {
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final selected = await widget.pickFiles();
      if (!mounted) return;
      final size = [...files, ...selected]
          .fold<int>(0, (sum, f) => sum + f.bytes.length);
      if (files.length + existing.length + selected.length > 30 ||
          size > 24 * 1024 * 1024)
        throw const ApiException('Choose up to 30 bills, 24 MB total');
      setState(() => files.addAll(selected));
    } catch (e) {
      if (mounted)
        setState(
            () => error = e is ApiException ? e.message : 'Could not open PDF');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> chooseExisting() async {
    if (companyId == null) {
      setState(() => error = 'Choose a company first');
      return;
    }
    final linked = c.trips
        .where((t) => !t.removed)
        .expand((t) => t.bills)
        .map((b) => b.messageId)
        .toSet();
    final company =
        c.data!.stock.companies.firstWhere((x) => x.id == companyId);
    final choices = c.data!.bills
        .where((b) =>
            b.draft != null &&
            b.draft!.workflowStatus != 'cancelled' &&
            b.draft!.stockStatus != 'duplicate_document' &&
            (b.companyId == companyId ||
                b.draft!.supplierGstin == company.gstin) &&
            !linked.contains(b.id) &&
            !existing.any((x) => x.id == b.id) &&
            !files.any((f) => f.messageId == b.id))
        .toList();
    final selected = await showModalBottomSheet<Bill>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              if (choices.isEmpty)
                const ListTile(title: Text('No ungrouped recent bills')),
              ...choices.map((b) => ListTile(
                  title: Text(b.draft!.documentNumber ?? b.fileName),
                  onTap: () => Navigator.pop(ctx, b))),
            ])));
    if (selected != null && mounted) setState(() => existing.add(selected));
  }

  Future<void> leave() async {
    if (saving || picking) return;
    if (files.isNotEmpty ||
        existing.isNotEmpty ||
        name.text.isNotEmpty ||
        driver != null) {
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Leave this draft?'),
                  content: Text(attemptedSave
                      ? 'No trip is confirmed. Some bills may already be saved in History. Retry Save to confirm this group.'
                      : 'No trip or stock change has been saved.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep editing')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Leave'))
                  ]));
      if (confirmed != true || !mounted) return;
    }
    setState(() => allowPop = true);
    Navigator.pop(context);
  }

  Future<void> save() async {
    if (saving || picking || !form.currentState!.validate()) return;
    if (files.isEmpty && existing.isEmpty) {
      setState(() => error = 'Add at least one bill');
      return;
    }
    setState(() {
      saving = true;
      attemptedSave = true;
      error = null;
    });
    try {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        if (file.messageId != null || file.duplicate) continue;
        setState(() =>
            progress = 'Uploading and checking bill ${i + 1}/${files.length}…');
        final result =
            await c.uploadDraftFile(file.name, file.bytes, file.requestId);
        if (!mounted) return;
        file.duplicate = result['duplicate'] == true;
        if (!file.duplicate) file.messageId = result['id']?.toString();
        if (!file.duplicate && file.messageId == null)
          throw const ApiException('Could not confirm bill. Retry save.');
      }
      final ids = {
        ...existing.map((b) => b.id),
        ...files.where((f) => f.messageId != null).map((f) => f.messageId!)
      }.toList();
      if (ids.isEmpty)
        throw const ApiException(
            'Already uploaded. No new trip created. Choose the original bill if you want to group it.');
      committedRequest ??= {
        'action': 'save_bill_trip',
        'requestId': requestId,
        'companyId': companyId,
        'driverId': driver!.id,
        'name': name.text.trim(),
        'messageIds': ids
      };
      setState(() => progress = 'Saving trip…');
      final trip = await c.commitBillDraft(committedRequest!);
      if (!mounted) return;
      setState(() => allowPop = true);
      Navigator.pop(context, trip);
    } catch (e) {
      if (mounted)
        setState(() => error = e is ApiException
            ? e.message
            : 'Could not confirm save. Retry with these same bills.');
    } finally {
      if (mounted)
        setState(() {
          saving = false;
          progress = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
          appBar: AppBar(
              title: const Text('Trip from bills'),
              leading: IconButton(
                  onPressed: saving || picking ? null : leave,
                  icon: const Icon(Icons.arrow_back))),
          body: Form(
              key: form,
              child: ListView(padding: const EdgeInsets.all(18), children: [
                const Text('PDFs upload only when you tap Save trip.'),
                const SizedBox(height: 16),
                if (c.selectedCompanyId == null &&
                    c.data!.stock.companies.length != 1)
                  DropdownButtonFormField<String>(
                      initialValue: companyId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Company'),
                      items: c.data!.stock.companies
                          .map((x) => DropdownMenuItem(
                              value: x.id,
                              child: Text(x.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      validator: (v) => v == null ? 'Choose a company' : null,
                      onChanged: saving ||
                              committedRequest != null ||
                              files.any((f) => f.messageId != null)
                          ? null
                          : (v) => setState(() {
                                companyId = v;
                                existing.clear();
                              })),
                DropdownButtonFormField<String>(
                    initialValue: driver?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Driver'),
                    items: c.data!.drivers
                        .map((d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    validator: (v) => v == null ? 'Choose a driver' : null,
                    onChanged: saving || committedRequest != null
                        ? null
                        : (v) => setState(() => driver =
                            c.data!.drivers.firstWhere((d) => d.id == v))),
                const SizedBox(height: 16),
                ...files.map((f) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.name),
                    subtitle: Text(f.duplicate
                        ? 'Already uploaded'
                        : f.messageId != null
                            ? 'Bill saved · trip not confirmed'
                            : 'Not uploaded'),
                    trailing: saving ||
                            committedRequest != null ||
                            f.messageId != null
                        ? null
                        : IconButton(
                            tooltip: 'Remove PDF',
                            onPressed: () => setState(() => files.remove(f)),
                            icon: const Icon(Icons.close)))),
                ...existing.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b.draft?.documentNumber ?? b.fileName),
                    trailing: saving || committedRequest != null
                        ? null
                        : IconButton(
                            tooltip: 'Remove bill',
                            onPressed: () => setState(() => existing.remove(b)),
                            icon: const Icon(Icons.close)))),
                OutlinedButton.icon(
                    onPressed: saving || picking || committedRequest != null
                        ? null
                        : addFiles,
                    icon: const Icon(Icons.attach_file),
                    label: Text(picking ? 'Opening PDFs…' : 'Add PDFs')),
                TextButton(
                    onPressed: saving || picking || committedRequest != null
                        ? null
                        : chooseExisting,
                    child: const Text('Choose saved bill')),
                ExpansionTile(title: const Text('More details'), children: [
                  TextFormField(
                      controller: name,
                      enabled: !saving && committedRequest == null,
                      maxLength: 160,
                      decoration: const InputDecoration(
                          labelText: 'Trip name (optional)'))
                ]),
                if (progress != null) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(progress!)
                ],
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error))),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: saving || picking ? null : save,
                    child: Text(saving
                        ? 'Saving…'
                        : committedRequest != null
                            ? 'Retry save'
                            : 'Save trip')),
              ]))));
}
