import 'package:flutter/material.dart';

void main() {
  runApp(const SolarOpsApp());
}

class SolarOpsApp extends StatefulWidget {
  const SolarOpsApp({super.key});

  @override
  State<SolarOpsApp> createState() => _SolarOpsAppState();
}

class _SolarOpsAppState extends State<SolarOpsApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Ops',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: DashboardShell(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFF635BDF);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF7F7F8),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      fontFamily: 'sans-serif',
      dividerColor: const Color(0xFFEFEFF2),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F3F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.3),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1A1D),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF111113),
      dividerColor: const Color(0xFF29292D),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF202024),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.3),
        ),
      ),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Bills', 'Dispatch', 'Stock', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(
              isDark: widget.isDark,
              onToggleTheme: widget.onToggleTheme,
            ),
            const PlaceholderPage(
              title: 'Bills',
              icon: Icons.receipt_long_rounded,
              subtitle: 'Parsed invoices and review queue will appear here.',
            ),
            const PlaceholderPage(
              title: 'Dispatch',
              icon: Icons.local_shipping_outlined,
              subtitle: 'Driver assignments and delivery status will appear here.',
            ),
            const PlaceholderPage(
              title: 'Stock',
              icon: Icons.inventory_2_outlined,
              subtitle: 'Opening stock and inventory ledger will appear here.',
            ),
            const PlaceholderPage(
              title: 'Profile',
              icon: Icons.person_outline_rounded,
              subtitle: 'Account, company and app settings will appear here.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (var i = 0; i < _titles.length; i++)
            NavigationDestination(
              icon: Icon(
                [
                  Icons.grid_view_rounded,
                  Icons.receipt_long_outlined,
                  Icons.local_shipping_outlined,
                  Icons.inventory_2_outlined,
                  Icons.person_outline_rounded,
                ][i],
              ),
              selectedIcon: Icon(
                [
                  Icons.grid_view_rounded,
                  Icons.receipt_long_rounded,
                  Icons.local_shipping_rounded,
                  Icons.inventory_2_rounded,
                  Icons.person_rounded,
                ][i],
              ),
              label: _titles[i],
            ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.solar_power_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Solar Ops',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Change theme',
                    onPressed: onToggleTheme,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Search bills, products, vehicle...',
                  prefixIcon: Icon(Icons.search_rounded),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                ),
              ),
              const SizedBox(height: 18),
              const _StatsGrid(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'This week',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const Spacer(),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Day')),
                      ButtonSegment(value: 1, label: Text('Week')),
                      ButtonSegment(value: 2, label: Text('Month')),
                    ],
                    selected: const {1},
                    onSelectionChanged: (_) {},
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _WeeklyChart(),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    'Recent bills',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _RecentBills(),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _StatData(
        label: 'Bills today',
        value: '12',
        icon: Icons.receipt_long_outlined,
        trend: '+3',
        trendUp: true,
      ),
      _StatData(
        label: 'Pending review',
        value: '4',
        icon: Icons.fact_check_outlined,
        trend: '2 urgent',
        trendUp: false,
      ),
      _StatData(
        label: 'Dispatched',
        value: '9',
        icon: Icons.local_shipping_outlined,
        trend: '+12%',
        trendUp: true,
      ),
      _StatData(
        label: 'Stock alerts',
        value: '2',
        icon: Icons.inventory_2_outlined,
        trend: 'Check',
        trendUp: false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                child: _StatCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
  });

  final String label;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF1B1B1E) : const Color(0xFFF5F5F6);
    final trendColor = data.trendUp
        ? const Color(0xFF168966)
        : const Color(0xFFD55858);

    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: AppTheme.primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.trend,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 248,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LegendDot(color: AppTheme.primary, label: 'Delivered'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFAFC8F4), label: 'Received'),
            ],
          ),
          SizedBox(height: 18),
          Expanded(
            child: CustomPaint(
              painter: _BarChartPainter(),
              child: SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter();

  static const delivered = [8.0, 10.0, 6.0, 7.0, 10.0, 9.0, 11.0];
  static const received = [11.0, 12.0, 10.0, 10.0, 5.0, 11.0, 10.0];
  static const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF9A9AA1).withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const chartTop = 4.0;
    const chartBottom = 30.0;
    final chartHeight = size.height - chartBottom;

    for (var i = 0; i < 4; i++) {
      final y = chartTop + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final groupWidth = size.width / 7;
    final barWidth = groupWidth * 0.22;
    const maxValue = 12.0;

    for (var i = 0; i < 7; i++) {
      final center = groupWidth * i + groupWidth / 2;
      final deliveredHeight = delivered[i] / maxValue * (chartHeight - 10);
      final receivedHeight = received[i] / maxValue * (chartHeight - 10);

      final firstRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center - barWidth - 2,
          chartHeight - deliveredHeight,
          barWidth,
          deliveredHeight,
        ),
        const Radius.circular(4),
      );
      final secondRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center + 2,
          chartHeight - receivedHeight,
          barWidth,
          receivedHeight,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        firstRect,
        Paint()..color = AppTheme.primary,
      );
      canvas.drawRRect(
        secondRect,
        Paint()..color = const Color(0xFFAFC8F4),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Color(0xFF8A8A91),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(center - textPainter.width / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecentBills extends StatelessWidget {
  const _RecentBills();

  @override
  Widget build(BuildContext context) {
    const bills = [
      ('INV-240925-018', 'Solar panels · 18 qty', 'Reviewed'),
      ('INV-240925-017', 'Inverter · 6 qty', 'Pending'),
      ('INV-240925-016', 'Mounting kit · 22 qty', 'Dispatched'),
    ];

    return Column(
      children: [
        for (final bill in bills) ...[
          _BillTile(
            invoice: bill.$1,
            subtitle: bill.$2,
            status: bill.$3,
          ),
          if (bill != bills.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BillTile extends StatelessWidget {
  const _BillTile({
    required this.invoice,
    required this.subtitle,
    required this.status,
  });

  final String invoice;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (status) {
      'Reviewed' => const Color(0xFF168966),
      'Dispatched' => AppTheme.primary,
      _ => const Color(0xFFD48A24),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B1E) : const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.58),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
