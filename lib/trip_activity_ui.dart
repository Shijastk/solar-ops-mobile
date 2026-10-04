import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripActivity {
  TripActivity(dynamic value) : raw = value is Map ? value : const {};
  final Map raw;
  bool get available =>
      DateTime.tryParse(raw['today']?.toString() ?? '') != null;
  DateTime get today => DateTime.parse(raw['today'].toString());
  int count(String key, String? companyId, {String? day}) {
    final rows = raw[key];
    if (rows is! List) return 0;
    return rows
        .whereType<Map>()
        .where((r) =>
            r['companyId'] == companyId && (day == null || r['day'] == day))
        .fold<int>(
            0,
            (sum, r) =>
                sum + (r['count'] is num ? (r['count'] as num).toInt() : 0));
  }
}

class TripSummaryCards extends StatelessWidget {
  const TripSummaryCards({super.key, required this.data, this.companyId});
  final dynamic data;
  final String? companyId;
  @override
  Widget build(BuildContext context) {
    final activity = TripActivity(data);
    Widget card(String title, String value) => Expanded(
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(value,
                          style: Theme.of(context).textTheme.headlineSmall),
                    ]))));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      card(
          'Completed today',
          activity.available
              ? '${activity.count('daily', companyId, day: activity.raw['today'].toString())} trips'
              : 'Unavailable'),
      card(
          'To complete',
          activity.available
              ? '${activity.count('pending', companyId)} trips'
              : 'Unavailable'),
    ]);
  }
}

class TripActivityChart extends StatefulWidget {
  const TripActivityChart({super.key, required this.data, this.companyId});
  final dynamic data;
  final String? companyId;
  @override
  State<TripActivityChart> createState() => _ChartState();
}

class _ChartState extends State<TripActivityChart> {
  int days = 7;
  String? selectedDay;
  @override
  void didUpdateWidget(covariant TripActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) selectedDay = null;
  }

  @override
  Widget build(BuildContext context) {
    final activity = TripActivity(widget.data);
    if (!activity.available)
      return const Text('Trip activity unavailable. Refresh to try again.');
    final dates = List.generate(
        days, (i) => activity.today.subtract(Duration(days: days - i - 1)));
    final counts = dates
        .map((d) => activity.count('daily', widget.companyId,
            day: DateFormat('yyyy-MM-dd').format(d)))
        .toList();
    final maximum = counts.fold<int>(1, (max, n) => n > max ? n : max);
    final selectedIndex = selectedDay == null
        ? -1
        : dates.indexWhere(
            (d) => DateFormat('yyyy-MM-dd').format(d) == selectedDay);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Completed trips',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days'))
          ],
          selected: {
            days
          },
          onSelectionChanged: (v) => setState(() {
                days = v.single;
                selectedDay = null;
              })),
      const SizedBox(height: 12),
      Text(selectedIndex < 0
          ? '${counts.fold<int>(0, (sum, n) => sum + n)} completed trips · last $days days'
          : '${DateFormat('d MMM').format(dates[selectedIndex])}: ${counts[selectedIndex]} completed trips'),
      const SizedBox(height: 12),
      SizedBox(
          height: 154,
          child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                      width: days == 7 ? constraints.maxWidth : days * 38.0,
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(days, (i) {
                            final label =
                                '${DateFormat('d MMM').format(dates[i])}: ${counts[i]} completed trips';
                            return Expanded(
                                child: Semantics(
                                    button: true,
                                    label: label,
                                    selected: selectedIndex == i,
                                    child: InkWell(
                                        onTap: () => setState(() =>
                                            selectedDay =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(dates[i])),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text('${counts[i]}',
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                      height: counts[i] == 0
                                                          ? 2
                                                          : 105 *
                                                              counts[i] /
                                                              maximum,
                                                      decoration: BoxDecoration(
                                                          color: selectedIndex ==
                                                                  i
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primaryContainer,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      4))),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                      DateFormat('d')
                                                          .format(dates[i]),
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                ])))));
                          })))))),
      const SizedBox(height: 8),
      Text(
          '${DateFormat('d MMM').format(dates.first)} – ${DateFormat('d MMM').format(dates.last)} · India time',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
