import 'package:flutter/material.dart';
import 'api_client.dart';
import 'app_controller.dart';
import 'models.dart';

List<ProductChoice> companyProducts(BootstrapData data, String? companyId) {
  final result = <String, ProductChoice>{};
  for (final b in data.stock.balances.where((b) => b.companyId == companyId)) {
    final p = ProductChoice.fromJson({
      'productId': b.productId,
      'companyId': b.companyId,
      'productName': b.productName,
      'unit': b.unit,
      'hsnSac': b.hsnSac
    });
    result['${p.name.toLowerCase()}:${p.unit}'] = p;
  }
  for (final p in data.products.where((p) => p.companyId == companyId)) {
    result.putIfAbsent('${p.name.toLowerCase()}:${p.unit}', () => p);
  }
  return result.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

class ManualTripInput {
  ManualTripInput(this.companyId, this.place, this.driver, this.sites,
      this.owner, this.items, this.name);
  final String companyId, place, owner, name;
  final Driver driver;
  final int sites;
  final List<Map<String, dynamic>> items;
}

class ManualTripForm extends StatefulWidget {
  const ManualTripForm({super.key, required this.controller});
  final AppController controller;
  @override
  State<ManualTripForm> createState() => _ManualTripFormState();
}

class _ItemInput {
  ProductChoice? product;
  final name = TextEditingController(), quantity = TextEditingController();
  String unit = 'NOS';
  bool newEntry = false;
  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class _ManualTripFormState extends State<ManualTripForm> {
  final form = GlobalKey<FormState>();
  final place = TextEditingController(),
      sites = TextEditingController(text: '1'),
      owner = TextEditingController(),
      tripName = TextEditingController();
  final lines = [_ItemInput()];
  String? companyId;
  Driver? driver;
  bool ownerVisible = false, nameVisible = false;
  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    companyId = c.selectedCompanyId ??
        (c.data!.stock.companies.length == 1
            ? c.data!.stock.companies.single.id
            : null);
  }

  @override
  void dispose() {
    place.dispose();
    sites.dispose();
    owner.dispose();
    tripName.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> addDriver() async {
    final input = TextEditingController();
    final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Driver name'),
                content: TextField(controller: input, autofocus: true),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, input.text.trim()),
                      child: const Text('Add'))
                ]));
    input.dispose();
    if (name == null || name.isEmpty) return;
    Driver? saved;
    final error = await widget.controller.runMutation((token) async {
      final json = await widget.controller.api
          .operation(token, {'action': 'driver', 'name': name});
      saved = Driver.fromJson(json);
      widget.controller.rememberDriver(saved!);
    });
    if (mounted) {
      if (error == null) {
        setState(() => driver = saved);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(
        context,
        ManualTripInput(
            companyId!,
            place.text.trim(),
            driver!,
            int.parse(sites.text),
            owner.text.trim(),
            lines
                .map((l) => {
                      'productId': l.product?.productId,
                      'productName': l.product?.name ?? l.name.text.trim(),
                      'unit': l.product?.unit ?? l.unit,
                      'quantity': double.parse(l.quantity.text)
                    })
                .toList(), tripName.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, products = companyProducts(c.data!, companyId);
    return Padding(
        padding: EdgeInsets.fromLTRB(
            18, 0, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('New trip',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (c.selectedCompanyId == null &&
                          c.data!.stock.companies.length != 1)
                        DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: companyId,
                            decoration:
                                const InputDecoration(labelText: 'Company'),
                            items: c.data!.stock.companies
                                .map((x) => DropdownMenuItem(
                                    value: x.id,
                                    child: Text(x.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            validator: (v) =>
                                v == null ? 'Choose a company' : null,
                            onChanged: (v) => setState(() {
                                  companyId = v;
                                  for (final l in lines) {
                                    l.product = null;
                                  }
                                })),
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: place,
                          decoration: const InputDecoration(labelText: 'Place'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter a place'
                              : null,
                          maxLength: 200),
                      DropdownButtonFormField<String>(
                          key: ValueKey(driver?.id),
                          initialValue: driver?.id,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Driver'),
                          items: c.data!.drivers
                              .map((d) => DropdownMenuItem(
                                  value: d.id, child: Text(d.name)))
                              .toList(),
                          validator: (v) =>
                              v == null ? 'Choose a driver' : null,
                          onChanged: (v) => setState(() => driver =
                              c.data!.drivers.firstWhere((d) => d.id == v))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: c.busy ? null : addDriver,
                              child: const Text('+ Add driver'))),
                      ...lines.asMap().entries.map((entry) {
                        final l = entry.value;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: l.product?.key ??
                                          (l.newEntry || products.isEmpty
                                              ? 'new'
                                              : null),
                                      decoration: InputDecoration(
                                          labelText: lines.length == 1
                                              ? 'Product'
                                              : 'Product ${entry.key + 1}'),
                                      items: [
                                        ...products.map((p) => DropdownMenuItem(
                                            value: p.key,
                                            child: Text('${p.name} · ${p.unit}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis))),
                                        const DropdownMenuItem(
                                            value: 'new',
                                            child: Text('Enter product name'))
                                      ],
                                      validator: (v) =>
                                          v == null ? 'Choose a product' : null,
                                      onChanged: (v) => setState(() {
                                            l.newEntry = v == 'new';
                                            l.product = v == 'new'
                                                ? null
                                                : products.firstWhere(
                                                    (p) => p.key == v);
                                          })),
                                  if (l.product == null &&
                                      (l.newEntry || products.isEmpty)) ...[
                                    const SizedBox(height: 10),
                                    TextFormField(
                                        controller: l.name,
                                        decoration: const InputDecoration(
                                            labelText: 'Product name'),
                                        validator: (v) => l.product == null &&
                                                (v == null || v.trim().isEmpty)
                                            ? 'Enter a product'
                                            : null,
                                        maxLength: 200),
                                    DropdownButtonFormField<String>(
                                        initialValue: l.unit,
                                        decoration: const InputDecoration(
                                            labelText: 'Unit'),
                                        items: ['NOS', 'SET', 'PCS', 'BOX']
                                            .map((u) => DropdownMenuItem(
                                                value: u, child: Text(u)))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => l.unit = v!))
                                  ],
                                  const SizedBox(height: 10),
                                  TextFormField(
                                      controller: l.quantity,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                          labelText:
                                              'Quantity (${l.product?.unit ?? l.unit})'),
                                      validator: quantityError),
                                  if (lines.length > 1)
                                    Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                            onPressed: () => setState(() {
                                                  lines.remove(l);
                                                  l.dispose();
                                                }),
                                            child:
                                                const Text('Remove product')))
                                ]));
                      }),
                      if (lines.length < 30)
                        TextButton(
                            onPressed: () =>
                                setState(() => lines.add(_ItemInput())),
                            child: const Text('+ Add product')),
                      TextFormField(
                          controller: sites,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sites'),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n == null || n < 1 || n > 1000
                                ? 'Enter 1–1000 sites'
                                : null;
                          }),
                      if (!ownerVisible)
                        Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                                onPressed: () =>
                                    setState(() => ownerVisible = true),
                                child:
                                    const Text('Add owner name (optional)'))),
                      if (ownerVisible)
                        TextFormField(
                            controller: owner,
                            decoration: const InputDecoration(
                                labelText: 'Owner name (optional)'),
                            maxLength: 120),
                      if (!nameVisible)
                        TextButton(onPressed:()=>setState(()=>nameVisible=true),
                          child:const Text('Add trip name (optional)')),
                      if(nameVisible)
                        TextFormField(controller:tripName,maxLength:160,
                          decoration:const InputDecoration(labelText:'Trip name (optional)')),
                      const SizedBox(height: 18),
                      FilledButton(
                          onPressed: c.busy ? null : submit,
                          child: const Text('Save dispatch')),
                    ]))));
  }
}

String? quantityError(String? value) {
  final n = double.tryParse(value ?? '');
  return n == null ||
          !n.isFinite ||
          n <= 0 ||
          n > 1000000000 ||
          (n * 1000 - (n * 1000).round()).abs() > .0001
      ? 'Enter a positive quantity (up to 3 decimals)'
      : null;
}

class StockEntry {
  StockEntry(this.companyId, this.product, this.name, this.unit, this.quantity,
      this.allowSimilar);
  final String companyId, name, unit;
  final ProductChoice? product;
  final double quantity;
  final bool allowSimilar;
}

class StockEntrySheet extends StatefulWidget {
  const StockEntrySheet({super.key, required this.controller});
  final AppController controller;
  @override
  State<StockEntrySheet> createState() => _StockEntryState();
}

class _StockEntryState extends State<StockEntrySheet> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), quantity = TextEditingController();
  String? companyId;
  ProductChoice? product;
  String unit = 'NOS';
  bool allowSimilar = false, newEntry = false;
  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    companyId = c.selectedCompanyId ??
        (c.data!.stock.companies.length == 1
            ? c.data!.stock.companies.single.id
            : null);
  }

  @override
  void dispose() {
    name.dispose();
    quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, products = companyProducts(c.data!, companyId);
    return Padding(
        padding: EdgeInsets.fromLTRB(
            18, 0, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            child: Form(
                key: form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Add stock',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (c.selectedCompanyId == null &&
                          c.data!.stock.companies.length != 1)
                        DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: companyId,
                            decoration:
                                const InputDecoration(labelText: 'Company'),
                            items: c.data!.stock.companies
                                .map((x) => DropdownMenuItem(
                                    value: x.id,
                                    child: Text(x.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis)))
                                .toList(),
                            validator: (v) =>
                                v == null ? 'Choose a company' : null,
                            onChanged: (v) => setState(() {
                                  companyId = v;
                                  product = null;
                                })),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                          key: ValueKey(companyId),
                          isExpanded: true,
                          initialValue: product?.key ??
                              (newEntry || products.isEmpty ? 'new' : null),
                          decoration:
                              const InputDecoration(labelText: 'Product'),
                          items: [
                            ...products.map((p) => DropdownMenuItem(
                                value: p.key,
                                child: Text('${p.name} · ${p.unit}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis))),
                            const DropdownMenuItem(
                                value: 'new', child: Text('New product'))
                          ],
                          validator: (v) =>
                              v == null ? 'Choose a product' : null,
                          onChanged: (v) => setState(() {
                                newEntry = v == 'new';
                                product = v == 'new'
                                    ? null
                                    : products.firstWhere((p) => p.key == v);
                              })),
                      if (product == null &&
                          (newEntry || products.isEmpty)) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                                labelText: 'Product name'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter a product name'
                                : null),
                        DropdownButtonFormField<String>(
                            initialValue: unit,
                            decoration:
                                const InputDecoration(labelText: 'Unit'),
                            items: ['NOS', 'SET', 'PCS', 'BOX']
                                .map((u) =>
                                    DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) => setState(() => unit = v!))
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                          controller: quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                              labelText: product?.productId != null
                                  ? 'Quantity received (${product!.unit})'
                                  : 'Current stock (${product?.unit ?? unit})'),
                          validator: quantityError),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: () {
                            if (form.currentState!.validate()) {
                              Navigator.pop(
                                  context,
                                  StockEntry(
                                      companyId!,
                                      product,
                                      product?.name ?? name.text.trim(),
                                      product?.unit ?? unit,
                                      double.parse(quantity.text),
                                      allowSimilar));
                            }
                          },
                          child: const Text('Save stock')),
                    ]))));
  }
}

class CreateCompanySheet extends StatefulWidget {
  const CreateCompanySheet({super.key, required this.controller});
  final AppController controller;
  @override
  State<CreateCompanySheet> createState() => _CreateCompanyState();
}

class _CreateCompanyState extends State<CreateCompanySheet> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), gstin = TextEditingController();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    gstin.dispose();
    super.dispose();
  }

  Future<void> save({bool allowSimilar = false}) async {
    if (!form.currentState!.validate() || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    String? code;
    Map<String, dynamic>? saved;
    final failure = await widget.controller.runMutation((token) async {
      try {
        saved = await widget.controller.api.operation(token, {
          'action': 'company',
          'name': name.text.trim(),
          'gstin': gstin.text.trim(),
          'allowSimilar': allowSimilar
        });
        widget.controller.rememberCompany(saved!);
      } on ApiException catch (e) {
        code = e.code;
        rethrow;
      }
    });
    if (!mounted) return;
    setState(() => saving = false);
    if (failure == null) {
      Navigator.pop(context);
      return;
    }
    if (code == 'potential_company_duplicate') {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Similar company exists'),
                  content: const Text(
                      'Check the existing company first. Is this genuinely a different company with a different GSTIN?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Go back')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Different company'))
                  ]));
      if (confirm == true && mounted) {
        await save(allowSimilar: true);
        return;
      }
    }
    if (mounted) setState(() => error = failure);
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          18, 0, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
          child: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Create company',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: name,
                        decoration:
                            const InputDecoration(labelText: 'Company name'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter a name'
                            : null,
                        maxLength: 200),
                    const SizedBox(height: 10),
                    TextFormField(
                        controller: gstin,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'GSTIN'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter GSTIN'
                            : null),
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(error!)),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: saving ? null : save,
                        child: Text(saving ? 'Saving…' : 'Create company'))
                  ]))));
}
