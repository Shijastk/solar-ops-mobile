import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../widgets/common.dart';

class DispatchScreen extends StatelessWidget {
  const DispatchScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final dispatches = controller.data!.dispatches;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeader(
              title: 'Dispatch',
              subtitle: 'Vehicle and destination fields parsed from real bills',
            ),
          ),
          if (dispatches.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No parsed dispatch data',
                message:
                    'No driver or delivery state is invented here. Vehicle, destination and consignee details appear only after a real bill is parsed.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: SliverList.separated(
                itemCount: dispatches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = dispatches[index];
                  return SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.documentNumber ?? item.fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            StatusPill(status: item.workflowStatus),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DataRowLine(
                          label: 'Company',
                          value: item.companyName ?? 'Not detected',
                        ),
                        DataRowLine(
                          label: 'Vehicle',
                          value: item.vehicleNumber ?? 'Not detected',
                        ),
                        DataRowLine(
                          label: 'Destination',
                          value: item.destination ?? 'Not detected',
                        ),
                        DataRowLine(
                          label: 'Consignee',
                          value: item.consigneeName ?? 'Not detected',
                        ),
                        DataRowLine(
                          label: 'Stock',
                          value: statusLabel(item.stockStatus),
                        ),
                        DataRowLine(
                          label: 'Received',
                          value: formatDateTime(item.receivedAt),
                        ),
                      ],
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
