import 'package:flutter/material.dart';

import '../api.dart';
import '../app_controller.dart';
import '../models.dart';
import '../widgets/common.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openAdd(BuildContext context) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OpeningStockSheet(controller: controller),
    );
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _openAdjust(
    BuildContext context,
    StockBalance balance,
  ) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AdjustStockSheet(
        controller: controller,
        balance: balance,
      ),
    );
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balances = controller.data!.stock.balances;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Stock',
                subtitle: 'Current balance from the immutable stock ledger',
                trailing: IconButton.filledTonal(
                  tooltip: 'Add opening stock',
                  onPressed: controller.mutating
                      ? null
                      : () => _openAdd(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            if (balances.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No stock products',
                  message:
                      'Use Add stock to create the first GSTIN-backed opening balance.',
                  action: FilledButton.icon(
                    onPressed: () => _openAdd(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add stock'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: balances.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final balance = balances[index];
                    return SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      balance.productName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      balance.companyName,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatQuantity(
                                      balance.currentQuantity,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    balance.unit,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              StatusPill(status: 'current'),
                              if (balance.hsnSac != null)
                                StatusPill(
                                  status: 'HSN ' + balance.hsnSac!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'GSTIN ' + balance.companyGstin,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: controller.mutating
                                    ? null
                                    : () =>
                                        _openAdjust(context, balance),
                                icon: const Icon(Icons.tune_rounded, size: 18),
                                label: const Text('Adjust'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: balances.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed:
                  controller.mutating ? null : () => _openAdd(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add stock'),
            ),
    );
  }
}

class _OpeningStockSheet extends StatefulWidget {
  const _OpeningStockSheet({required this.controller});

  final AppController controller;

  @override
  State<_OpeningStockSheet> createState() => _OpeningStockSheetState();
}

class _OpeningStockSheetState extends State<_OpeningStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _gstin = TextEditingController();
  final _product = TextEditingController();
  final _hsn = TextEditingController();
  final _quantity = TextEditingController();

  String? _companyId;
  String _unit = 'NOS';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _companyName.dispose();
    _gstin.dispose();
    _product.dispose();
    _hsn.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create anyway'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
      _error = null;
    });

    var allowCompany = false;
    var allowProduct = false;

    try {
      while (mounted) {
        final result = await widget.controller.addOpeningStock(
          companyId: _companyId,
          companyName:
              _companyId == null ? _companyName.text.trim() : null,
          companyGstin: _companyId == null ? _gstin.text.trim() : null,
          productName: _product.text.trim(),
          unit: _unit,
          hsnSac: _hsn.text.trim().isEmpty ? null : _hsn.text.trim(),
          quantity: double.parse(_quantity.text.trim()),
          allowSimilarCompany: allowCompany,
          allowSimilarProduct: allowProduct,
        );

        final status = (result['status'] ?? 'unknown').toString();

        if (status == 'potential_company_duplicate' && !allowCompany) {
          final proceed = await _confirm(
            'Similar company found',
            'A very similar company already exists. Only continue if this is genuinely a different GSTIN-backed company.',
          );
          if (!proceed) break;
          allowCompany = true;
          continue;
        }

        if (status == 'potential_product_duplicate' && !allowProduct) {
          final proceed = await _confirm(
            'Similar product found',
            'A very similar product already exists for this company and unit. Only continue if this is genuinely a different product.',
          );
          if (!proceed) break;
          allowProduct = true;
          continue;
        }

        if (status == 'opening_created') {
          if (mounted) {
            Navigator.pop(context, 'Opening stock saved.');
          }
          return;
        }

        if (status == 'opening_exists') {
          setState(() {
            _error =
                'Opening stock already exists. Use Adjust on the existing product.';
          });
          break;
        }

        setState(() {
          _error = 'Opening stock was not saved: ' + statusLabel(status) + '.';
        });
        break;
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Opening stock could not be saved.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = widget.controller.data!.stock.companies;
    final creatingCompany = _companyId == null;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add opening stock',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w850,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose an existing GSTIN-backed company or create a new company.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _companyId,
                decoration: const InputDecoration(
                  labelText: 'Existing company',
                ),
                items: companies
                    .map(
                      (company) => DropdownMenuItem(
                        value: company.id,
                        child: Text(
                          company.name + ' · ' + company.gstin,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _companyId = value),
                hint: const Text('Create a new company'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyName,
                enabled: creatingCompany,
                decoration: InputDecoration(
                  labelText: 'New company name',
                  hintText:
                      creatingCompany ? 'Required' : 'Using selected company',
                ),
                validator: (value) => creatingCompany &&
                        (value == null || value.trim().isEmpty)
                    ? 'Company name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gstin,
                enabled: creatingCompany,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Company GSTIN *',
                  hintText: creatingCompany
                      ? '15-character GSTIN'
                      : 'Using saved GSTIN',
                ),
                validator: (value) {
                  if (!creatingCompany) return null;
                  final gstin = (value ?? '').trim().toUpperCase();
                  if (gstin.isEmpty) return 'GSTIN is required.';
                  final valid = RegExp(
                    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]Z[0-9A-Z]$',
                  ).hasMatch(gstin);
                  return valid ? null : 'Enter a valid 15-character GSTIN.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _product,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Product name is required.'
                        : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: const InputDecoration(labelText: 'Unit'),
                items: const ['NOS', 'PCS', 'SET', 'BOX']
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _unit = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hsn,
                decoration:
                    const InputDecoration(labelText: 'HSN / SAC (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Opening quantity'),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  return parsed == null || parsed <= 0
                      ? 'Enter a quantity greater than zero.'
                      : null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save opening stock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdjustStockSheet extends StatefulWidget {
  const _AdjustStockSheet({
    required this.controller,
    required this.balance,
  });

  final AppController controller;
  final StockBalance balance;

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _target = TextEditingController(
    text: formatQuantity(widget.balance.currentQuantity),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final status = await widget.controller.adjustStock(
        productId: widget.balance.productId,
        targetQuantity: double.parse(_target.text.trim()),
      );
      if (!mounted) return;
      final message = switch (status) {
        'adjusted' => 'Stock adjusted with an audit ledger entry.',
        'already_adjusted' => 'This adjustment was already applied.',
        'no_change' => 'Stock already matches that quantity.',
        _ => 'Adjustment result: ' + statusLabel(status),
      };
      Navigator.pop(context, message);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Stock could not be adjusted.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Adjust stock',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.balance.productName,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _target,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target physical quantity (' +
                    widget.balance.unit +
                    ')',
              ),
              validator: (value) {
                final parsed = double.tryParse((value ?? '').trim());
                return parsed == null || parsed < 0
                    ? 'Enter zero or a positive quantity.'
                    : null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_rounded),
              label: Text(_saving ? 'Saving…' : 'Save adjustment'),
            ),
          ],
        ),
      ),
    );
  }
}
