import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';

/// Full read-only detail view for a single daily entry.
class EntryDetailScreen extends StatelessWidget {
  final Entry entry;
  const EntryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final date = DateTime.tryParse(entry.date);
    final dateStr = date != null ? DateFormat('EEEE, MMMM d, yyyy').format(date) : entry.date;

    return Scaffold(
      appBar: AppBar(title: Text(dateStr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick stats row ──────────────────────────────────
            Row(
              children: [
                _StatChip(emoji: entry.moodEmoji, label: 'Mood ${entry.mood}'),
                const SizedBox(width: 8),
                _StatChip(emoji: '🎯', label: 'Focus ${entry.focus}'),
                const SizedBox(width: 8),
                _StatChip(emoji: '😴', label: '${entry.sleepHours}h sleep'),
                if (entry.completionPercent != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(emoji: '📊', label: '${entry.completionPercent}%'),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ── AI Analysis ─────────────────────────────────────
            if (entry.dailySummary != null || entry.insight != null || entry.suggestion != null) ...[
              _DetailSection(
                title: 'AI Analysis',
                icon: Icons.auto_awesome,
                iconColor: cs.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.dailySummary != null && entry.dailySummary!.isNotEmpty) ...[
                      _SubLabel('📋 Summary'),
                      Text(entry.dailySummary!),
                      const SizedBox(height: 8),
                    ],
                    if (entry.insight != null && entry.insight!.isNotEmpty) ...[
                      _SubLabel('💡 Insight'),
                      Text(entry.insight!),
                      const SizedBox(height: 8),
                    ],
                    if (entry.suggestion != null && entry.suggestion!.isNotEmpty) ...[
                      _SubLabel('🎯 Suggestion'),
                      Text(entry.suggestion!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Structured fields ───────────────────────────────
            if (entry.tasksPlanned.isNotEmpty)
              _DetailSection(
                title: 'Tasks Planned',
                icon: Icons.checklist,
                child: Text(entry.tasksPlanned),
              ),

            if (entry.tasksCompleted.isNotEmpty)
              _DetailSection(
                title: 'Tasks Completed',
                icon: Icons.task_alt,
                child: Text(entry.tasksCompleted),
              ),

            if (entry.obstacles.isNotEmpty)
              _DetailSection(
                title: 'Obstacles',
                icon: Icons.warning_amber,
                child: Text(entry.obstacles),
              ),

            if (entry.wins.isNotEmpty)
              _DetailSection(
                title: 'Wins',
                icon: Icons.emoji_events,
                child: Text(entry.wins),
              ),

            if (entry.diet.isNotEmpty)
              _DetailSection(
                title: 'Diet',
                icon: Icons.restaurant,
                child: Text(entry.diet),
              ),

            if (entry.freeform.isNotEmpty)
              _DetailSection(
                title: 'Brain Dump',
                icon: Icons.psychology,
                child: Text(entry.freeform),
              ),

            // ── New categories from AI ──────────────────────────
            if (entry.newCategories != null && entry.newCategories!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailSection(
                title: 'AI-Detected Categories',
                icon: Icons.category,
                iconColor: cs.tertiary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entry.newCategories!
                      .map((cat) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cat['category'] ?? '',
                                    style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cat['content'] ?? '')),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            // ── Photos ──────────────────────────────────────────
            if (entry.photosBase64.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailSection(
                title: 'Photos',
                icon: Icons.photo_library,
                child: SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.photosBase64.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) {
                      try {
                        final bytes = base64Decode(entry.photosBase64[i]);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(bytes, width: 140, height: 140, fit: BoxFit.cover),
                        );
                      } catch (_) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _StatChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$emoji $label', style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: iconColor ?? cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
