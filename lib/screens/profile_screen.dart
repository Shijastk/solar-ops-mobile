import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final AppController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final data = controller.data!;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const PageHeader(
            title: 'Profile & app',
            subtitle: 'Connection, session and local appearance',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined,
                          color: primaryColor),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Backend connection',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusPill(
                        status: data.runtime.healthy
                            ? 'healthy'
                            : 'check_config',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DataRowLine(
                    label: 'Last sync',
                    value: formatDateTime(data.generatedAt),
                  ),
                  DataRowLine(
                    label: 'Session expires',
                    value: controller.sessionExpiresAt == null
                        ? 'Unknown'
                        : formatDateTime(controller.sessionExpiresAt!),
                  ),
                  DataRowLine(
                    label: 'Automation',
                    value: data.runtime.automationEnabled
                        ? (data.runtime.automationReady
                            ? 'Enabled · ready'
                            : 'Enabled · not ready')
                        : 'Disabled',
                  ),
                  DataRowLine(
                    label: 'API',
                    value: controller.apiBaseUrl,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: SurfaceCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Dark mode',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Stored only for this running app session'),
                value: isDark,
                onChanged: (_) => onToggleTheme(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: OutlinedButton.icon(
              onPressed: controller.mutating ? null : controller.logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Solar Ops Mobile 0.2.0 · Operational data is loaded from the protected Solar Ops backend. No Supabase or Meta secret is stored in the app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
