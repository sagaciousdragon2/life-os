import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../providers/entry_provider.dart';
import 'entry_detail_screen.dart';

/// History tab – calendar-style list of past entries.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(historyEntriesProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading history: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('No entries yet', style: tt.titleMedium?.copyWith(color: cs.outline)),
                  const SizedBox(height: 8),
                  Text('Start by logging today!', style: tt.bodyMedium?.copyWith(color: cs.outline)),
                ],
              ),
            );
          }

          // Group entries by month
          final grouped = _groupByMonth(entries);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final month = grouped.keys.elementAt(index);
              final monthEntries = grouped[month]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      month,
                      style: tt.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...monthEntries.map((entry) => _EntryCard(entry: entry)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<Entry>> _groupByMonth(List<Entry> entries) {
    final map = <String, List<Entry>>{};
    for (final entry in entries) {
      final date = DateTime.tryParse(entry.date);
      final key = date != null ? DateFormat('MMMM yyyy').format(date) : 'Unknown';
      map.putIfAbsent(key, () => []).add(entry);
    }
    return map;
  }
}

class _EntryCard extends StatelessWidget {
  final Entry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final date = DateTime.tryParse(entry.date);
    final dateStr = date != null ? DateFormat('EEE, MMM d').format(date) : entry.date;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Mood emoji circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(entry.moodEmoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateStr, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (entry.completionPercent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _completionColor(entry.completionPercent!).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${entry.completionPercent}%',
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _completionColor(entry.completionPercent!),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (entry.wins.isNotEmpty)
                      Text(
                        '🏆 ${entry.wins.split('\n').first}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (entry.obstacles.isNotEmpty)
                      Text(
                        '⚠️ ${entry.obstacles.split('\n').first}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    if (entry.dailySummary != null && entry.dailySummary!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entry.dailySummary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }

  Color _completionColor(int pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }
}
