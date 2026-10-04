import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_controller.dart';

Future<Uint8List> smallProfilePhoto(Uint8List bytes) async {
  if (bytes.length > 5 * 1024 * 1024) {
    throw Exception('Choose a photo smaller than 5 MB');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = min(1.0, 256 / max(descriptor.width, descriptor.height));
    final codec = await descriptor.instantiateCodec(
        targetWidth: max(1, (descriptor.width * scale).round()),
        targetHeight: max(1, (descriptor.height * scale).round()));
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final side = min(image.width, image.height).toDouble();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH((image.width - side) / 2, (image.height - side) / 2,
                side, side),
            const Rect.fromLTWH(0, 0, 128, 128),
            Paint());
        final picture = recorder.endRecording();
        final thumb = await picture.toImage(128, 128);
        try {
          final png = await thumb.toByteData(format: ui.ImageByteFormat.png);
          if (png == null || png.lengthInBytes > 98304) {
            throw Exception('Could not prepare this photo');
          }
          return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          thumb.dispose();
          picture.dispose();
        }
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

class CompanyProfilePage extends StatefulWidget {
  const CompanyProfilePage(
      {super.key, required this.controller, required this.companyId});
  final AppController controller;
  final String companyId;
  @override
  State<CompanyProfilePage> createState() => _CompanyProfileState();
}

class _CompanyProfileState extends State<CompanyProfilePage> {
  Map<String, dynamic>? profile;
  String? error;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final p = await widget.controller.companyProfile(widget.companyId);
      if (mounted) {
        setState(() {
          profile = p;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Could not load profile. Try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save(Map<String, dynamic> values) async {
    final e = await widget.controller
        .saveCompanyProfile({'companyId': widget.companyId, ...values});
    if (mounted) {
      if (e == null) {
        setState(() =>
            profile = widget.controller.companyProfiles[widget.companyId]);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e ?? 'Profile saved')));
    }
  }

  Future<void> photo() async {
    try {
      final picked = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);
      if (picked == null) return;
      final bytes = picked.files.single.bytes;
      if (bytes == null) throw Exception('Could not read photo');
      await save({'photo': base64Encode(await smallProfilePhoto(bytes))});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Choose a JPG or PNG photo smaller than 5 MB.')));
      }
    }
  }

  Future<void> name() async {
    final input = TextEditingController(text: profile?['label']?.toString());
    final value = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Display name'),
                content: TextField(controller: input, maxLength: 200),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, input.text.trim()),
                      child: const Text('Save'))
                ]));
    input.dispose();
    if (value != null && value.isNotEmpty) await save({'label': value});
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final p = profile, busy = widget.controller.busy;
        final photo = p?['photo'] as String?;
        return Scaffold(
            appBar: AppBar(title: const Text('Company profile')),
            body: p == null
                ? Center(
                    child: loading
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: load, child: Text(error ?? 'Retry')))
                : ListView(padding: const EdgeInsets.all(20), children: [
                    Center(
                        child: CircleAvatar(
                            radius: 48,
                            backgroundImage: photo == null
                                ? null
                                : MemoryImage(base64Decode(photo)),
                            child: photo == null
                                ? const Icon(Icons.business_outlined, size: 44)
                                : null)),
                    TextButton(
                        onPressed: busy ? null : this.photo,
                        child: const Text('Change photo')),
                    if (photo != null)
                      TextButton(
                          onPressed: busy ? null : () => save({'photo': null}),
                          child: const Text('Remove photo')),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p['label'].toString()),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: busy ? null : name),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('GSTIN'),
                        subtitle: Text(p['gstin']?.toString() ?? 'Not set')),
                    if (p['label'] != p['name']) Text(p['name'].toString()),
                  ]));
      });
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(children: [
            if (controller.selectedCompanyId != null)
              ListTile(
                  leading: const Icon(Icons.business_outlined),
                  title: const Text('Company profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => CompanyProfilePage(
                              controller: controller,
                              companyId: controller.selectedCompanyId!)))),
            SwitchListTile(
                title: const Text('Device lock'),
                subtitle: const Text('Fingerprint, PIN or pattern'),
                value: controller.lockEnabled,
                onChanged: controller.busy
                    ? null
                    : (v) async {
                        final ok = await controller.setDeviceLock(v);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(controller.error ??
                                  'Device lock unavailable')));
                        }
                      }),
            ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await controller.logout();
                  if (context.mounted) Navigator.pop(context);
                }),
          ])));
}
