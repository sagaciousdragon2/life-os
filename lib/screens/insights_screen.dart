import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entry_provider.dart';

/// Text-heavy Insights screen showing extracted AI patterns across ranges.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(insightRangeProvider);
    final entriesAsync = ref.watch(insightEntriesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Insights', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<InsightRange>(
              segments: const [
                ButtonSegment(value: InsightRange.daily, label: Text('Daily')),
                ButtonSegment(value: InsightRange.weekly, label: Text('Weekly')),
                ButtonSegment(value: InsightRange.monthly, label: Text('Monthly')),
              ],
              selected: {range},
              onSelectionChanged: (set) => ref.read(insightRangeProvider.notifier).state = set.first,
            ),
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading insights: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text('No insights available for this period.', style: tt.bodyLarge?.copyWith(color: cs.outline)),
            );
          }

          // Gather AI insights & summaries from these entries
          final insights = entries.where((e) => e.insight != null && e.insight!.isNotEmpty).toList();
          final suggestions = entries.where((e) => e.suggestion != null && e.suggestion!.isNotEmpty).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary cards
              _InsightSectionTitle(
                title: 'Patterns & Observations',
                icon: Icons.lightbulb,
                color: Colors.amber.shade700,
              ),
              if (insights.isEmpty)
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('No observations yet.', style: tt.bodyMedium?.copyWith(color: cs.outline))))
              else
                ...insights.map((e) => _InsightCard(
                  date: e.date,
                  content: e.insight!,
                  icon: Icons.auto_awesome,
                  color: cs.primaryContainer,
                )),

              const SizedBox(height: 24),

              _InsightSectionTitle(
                title: 'Actionable Suggestions',
                icon: Icons.ads_click,
                color: Colors.green,
              ),
              if (suggestions.isEmpty)
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('No suggestions yet.', style: tt.bodyMedium?.copyWith(color: cs.outline))))
              else
                ...suggestions.map((e) => _InsightCard(
                  date: e.date,
                  content: e.suggestion!,
                  icon: Icons.check_circle_outline,
                  color: cs.tertiaryContainer,
                )),
            ],
          );
        },
      ),
    );
  }
}

class _InsightSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _InsightSectionTitle({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String date;
  final String content;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.date,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(date, style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: tt.bodyMedium),
          ],
        ),
      ),
    );
  }
}
