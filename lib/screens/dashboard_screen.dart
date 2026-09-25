import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onOpenBills,
  });

  final AppController controller;
  final VoidCallback onOpenBills;

  @override
  Widget build(BuildContext context) {
    final data = controller.data!;
    final dashboard = data.dashboard;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          PageHeader(
            title: 'Solar Ops',
            subtitle: 'Live operations · ' + formatDateTime(data.generatedAt),
            trailing: IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: controller.loading ? null : controller.refresh,
              icon: controller.loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                controller.error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      width: width,
                      icon: Icons.receipt_long_outlined,
                      label: 'Bills today',
                      value: dashboard.billsToday.toString(),
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.fact_check_outlined,
                      label: 'Needs review',
                      value: dashboard.pendingReview.toString(),
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.verified_outlined,
                      label: 'Recorded',
                      value: dashboard.recorded.toString(),
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.inventory_2_outlined,
                      label: 'Stock products',
                      value: dashboard.stockProducts.toString(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Bills · last 7 days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _RealBillsChart(days: dashboard.dailyBills),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Recent bills',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onOpenBills,
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (data.bills.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No PDF bills yet',
              message:
                  'This list stays empty until a real PDF arrives through the WhatsApp workflow.',
            )
          else
            ...data.bills.take(4).map(
                  (bill) => Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _BillPreview(bill: bill),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealBillsChart extends StatelessWidget {
  const _RealBillsChart({required this.days});

  final List<DailyBill> days;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        days.fold<int>(1, (value, day) => math.max(value, day.count));
    return SurfaceCard(
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((day) {
            final ratio = day.count / maxCount;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      day.count.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      height: 112 * ratio + 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _BillPreview extends StatelessWidget {
  const _BillPreview({required this.bill});

  final BillRecord bill;

  @override
  Widget build(BuildContext context) {
    final draft = bill.draft;
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  draft?.supplierName ?? formatDateTime(bill.receivedAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(
            status: draft?.workflowStatus ?? bill.processingStatus,
          ),
        ],
      ),
    );
  }
}
