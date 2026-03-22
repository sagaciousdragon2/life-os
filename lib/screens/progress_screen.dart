import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entry.dart';
import '../providers/entry_provider.dart';

/// Progress tab – charts and visualizations of daily logging data.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(progressRangeProvider);
    final entriesAsync = ref.watch(progressEntriesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ProgressRange>(
              segments: const [
                ButtonSegment(value: ProgressRange.week, label: Text('7d')),
                ButtonSegment(value: ProgressRange.month, label: Text('30d')),
                ButtonSegment(value: ProgressRange.all, label: Text('All')),
              ],
              selected: {range},
              onSelectionChanged: (set) => ref.read(progressRangeProvider.notifier).state = set.first,
            ),
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading charts: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(child: Text('Not enough data to graph.', style: tt.bodyLarge?.copyWith(color: cs.outline)));
          }

          // Calculate aggregate data
          int mappedPctCount = 0;
          double totalPct = 0;
          for (final e in entries) {
            if (e.completionPercent != null) {
              totalPct += e.completionPercent!;
              mappedPctCount++;
            }
          }
          final avgCompletion = mappedPctCount > 0 ? (totalPct / mappedPctCount) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Big Radial Progress ─────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Avg. Task Completion', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 150,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 0,
                                  centerSpaceRadius: 60,
                                  sections: [
                                    PieChartSectionData(
                                      color: cs.primary,
                                      value: avgCompletion,
                                      title: '',
                                      radius: 12,
                                    ),
                                    PieChartSectionData(
                                      color: cs.surfaceContainerHighest,
                                      value: 100 - avgCompletion,
                                      title: '',
                                      radius: 12,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${avgCompletion.toStringAsFixed(0)}%',
                                style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Line Chart: Completion Trend + Mood Overlay ─────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completion % & Mood Trend', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: _TrendChart(entries: entries, colorScheme: cs),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<Entry> entries;
  final ColorScheme colorScheme;

  const _TrendChart({required this.entries, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(child: Text('Need at least 2 days of data.'));
    }

    final sorted = List<Entry>.from(entries)..sort((a, b) => a.date.compareTo(b.date));

    // Prepare line chart data
    final completionSpots = <FlSpot>[];
    final moodSpots = <FlSpot>[];

    for (int i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      final x = i.toDouble();

      if (e.completionPercent != null) {
        completionSpots.add(FlSpot(x, e.completionPercent!.toDouble()));
      }
      // Mood is 1-10, scale to 0-100 for overlay
      moodSpots.add(FlSpot(x, e.mood * 10.0));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (v) => FlLine(color: colorScheme.outlineVariant.withValues(alpha: 0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (val, _) {
                final int i = val.toInt();
                if (i < 0 || i >= sorted.length) return const Text('');
                final e = sorted[i];
                // Just show day number or small date
                final dt = DateTime.tryParse(e.date);
                if (dt == null) return const Text('');
                // Simplify to just day
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${dt.day}', style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 40,
              getTitlesWidget: (val, _) {
                return Text('${val.toInt()}%', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Completion line
          LineChartBarData(
            spots: completionSpots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          // Mood line
          LineChartBarData(
            spots: moodSpots,
            isCurved: true,
            color: Colors.amber, // Mood is gold
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }
}
