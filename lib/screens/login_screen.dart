import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final AppController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accessKeyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _accessKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.controller.login(_accessKeyController.text);
    _accessKeyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Change theme',
                      onPressed: widget.onToggleTheme,
                      icon: Icon(
                        widget.isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.solar_power_rounded,
                      color: primaryColor,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Solar Ops',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to load live bills, dispatch details and stock from the protected operations backend.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SurfaceCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Operations access key',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 9),
                          TextFormField(
                            controller: _accessKeyController,
                            obscureText: _obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter the Operations access key.'
                                    : null,
                            decoration: InputDecoration(
                              hintText: 'Enter access key',
                              prefixIcon: const Icon(Icons.key_outlined),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Show access key'
                                    : 'Hide access key',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          if (controller.error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              controller.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: controller.loading ? null : _submit,
                            icon: controller.loading
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_open_rounded),
                            label: Text(
                              controller.loading
                                  ? 'Connecting…'
                                  : 'Connect securely',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The access key is exchanged for a short-lived signed session. The key itself is not stored by the app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
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
