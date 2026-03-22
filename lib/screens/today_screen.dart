import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/entry_provider.dart';

/// Main entry form – the "Today" tab.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _plannedCtrl = TextEditingController();
  final _completedCtrl = TextEditingController();
  final _obstaclesCtrl = TextEditingController();
  final _winsCtrl = TextEditingController();
  final _dietCtrl = TextEditingController();
  final _freeformCtrl = TextEditingController();

  bool _extrasExpanded = false;

  @override
  void initState() {
    super.initState();
    // Sync controllers with provider once when state is first available
    Future.microtask(() {
      final s = ref.read(todayFormProvider);
      _plannedCtrl.text = s.tasksPlanned;
      _completedCtrl.text = s.tasksCompleted;
      _obstaclesCtrl.text = s.obstacles;
      _winsCtrl.text = s.wins;
      _dietCtrl.text = s.diet;
      _freeformCtrl.text = s.freeform;
    });
  }

  @override
  void dispose() {
    _plannedCtrl.dispose();
    _completedCtrl.dispose();
    _obstaclesCtrl.dispose();
    _winsCtrl.dispose();
    _dietCtrl.dispose();
    _freeformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(todayFormProvider);
    final notifier = ref.read(todayFormProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Keep freeform controller in sync (e.g. after voice transcription)
    if (_freeformCtrl.text != formState.freeform) {
      _freeformCtrl.text = formState.freeform;
      _freeformCtrl.selection = TextSelection.collapsed(offset: formState.freeform.length);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Today', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset form',
            onPressed: () {
              notifier.resetForm();
              _plannedCtrl.clear();
              _completedCtrl.clear();
              _obstaclesCtrl.clear();
              _winsCtrl.clear();
              _dietCtrl.clear();
              _freeformCtrl.clear();
            },
          ),
        ],
      ),
      body: formState.isSubmitting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your day with AI…'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Stats ────────────────────────────────────
                  _SectionTitle('Quick Stats', icon: Icons.speed),
                  const SizedBox(height: 8),
                  _MoodSlider(
                    value: formState.mood,
                    onChanged: notifier.setMood,
                  ),
                  const SizedBox(height: 12),
                  _FocusSlider(
                    value: formState.focus,
                    onChanged: notifier.setFocus,
                  ),
                  const SizedBox(height: 12),
                  _SleepPicker(
                    value: formState.sleepHours,
                    onChanged: notifier.setSleepHours,
                  ),

                  const SizedBox(height: 24),

                  // ── Productivity ───────────────────────────────────
                  _SectionTitle('Productivity', icon: Icons.task_alt),
                  const SizedBox(height: 8),
                  _MultilineField(
                    controller: _plannedCtrl,
                    label: 'Tasks Planned (one per line)',
                    onChanged: notifier.setTasksPlanned,
                  ),
                  const SizedBox(height: 12),
                  _MultilineField(
                    controller: _completedCtrl,
                    label: 'Tasks Completed (one per line)',
                    onChanged: notifier.setTasksCompleted,
                  ),
                  const SizedBox(height: 4),
                  _CompletionBadge(
                    planned: formState.tasksPlanned,
                    completed: formState.tasksCompleted,
                  ),

                  const SizedBox(height: 24),

                  // ── Obstacles & Wins ───────────────────────────────
                  _SectionTitle('Obstacles', icon: Icons.warning_amber),
                  const SizedBox(height: 8),
                  _MultilineField(
                    controller: _obstaclesCtrl,
                    label: 'What got in the way?',
                    onChanged: notifier.setObstacles,
                  ),

                  const SizedBox(height: 24),

                  _SectionTitle('Wins / Good Things', icon: Icons.emoji_events),
                  const SizedBox(height: 8),
                  _MultilineField(
                    controller: _winsCtrl,
                    label: "What went well today?",
                    onChanged: notifier.setWins,
                  ),

                  const SizedBox(height: 24),

                  // ── Diet ───────────────────────────────────────────
                  _SectionTitle('Diet / What I Ate', icon: Icons.restaurant),
                  const SizedBox(height: 8),
                  _MultilineField(
                    controller: _dietCtrl,
                    label: 'Meals, snacks, hydration…',
                    onChanged: notifier.setDiet,
                  ),

                  const SizedBox(height: 24),

                  // ── Extras (expandable) ────────────────────────────
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: _extrasExpanded,
                      onExpansionChanged: (v) => setState(() => _extrasExpanded = v),
                      leading: Icon(Icons.add_circle_outline, color: cs.primary),
                      title: const Text('Extras (Voice · Photos · Brain Dump)'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Voice + Camera row
                              Row(
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: notifier.transcribeVoice,
                                    icon: const Icon(Icons.mic),
                                    label: const Text('Record'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: notifier.takePhoto,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: notifier.pickPhotos,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Photo thumbnails
                              if (formState.photoFiles.isNotEmpty) ...[
                                SizedBox(
                                  height: 100,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: formState.photoFiles.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                                    itemBuilder: (ctx, i) => Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            formState.photoFiles[i],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => notifier.removePhoto(i),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Freeform brain dump
                              _MultilineField(
                                controller: _freeformCtrl,
                                label: 'Brain dump — thoughts, notes, anything…',
                                maxLines: 6,
                                onChanged: notifier.setFreeform,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Error message ──────────────────────────────────
                  if (formState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        formState.errorMessage!,
                        style: TextStyle(color: cs.error),
                      ),
                    ),

                  // ── AI Response preview ────────────────────────────
                  if (formState.aiResponse != null) _AIPreviewCard(formState.aiResponse!),
                ],
              ),
            ),
      floatingActionButton: formState.isSubmitting
          ? null
          : FloatingActionButton.extended(
              heroTag: 'save_day',
              onPressed: () => notifier.submitEntry(),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Save Day'),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Private helper widgets
// ═══════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, {required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MoodSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _MoodSlider({required this.value, required this.onChanged});

  static const _emojis = ['😫', '😢', '😞', '😐', '🙂', '😊', '😄', '😁', '🤩', '🔥'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mood', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '${_emojis[value - 1]}  $value/10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _FocusSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Focus', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '🎯 $value/10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => onChanged(v.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepPicker extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _SleepPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sleep', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  '😴 ${value.toStringAsFixed(1)} hrs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            Slider(
              value: value,
              min: 0,
              max: 14,
              divisions: 28, // 0.5-hour steps
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _MultilineField({
    required this.controller,
    required this.label,
    this.maxLines = 3,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final String planned;
  final String completed;
  const _CompletionBadge({required this.planned, required this.completed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = planned.trim().split('\n').where((l) => l.trim().isNotEmpty).length;
    final c = completed.trim().split('\n').where((l) => l.trim().isNotEmpty).length;
    if (p == 0) return const SizedBox.shrink();

    final pct = ((c / p) * 100).round().clamp(0, 100);
    final color = pct >= 80 ? Colors.green : (pct >= 50 ? Colors.orange : cs.error);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.pie_chart, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Completion: $pct%  ($c / $p tasks)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AIPreviewCard extends StatelessWidget {
  final dynamic aiResponse; // AIResponse
  const _AIPreviewCard(this.aiResponse);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      color: cs.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'AI Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aiResponse.dailySummary.isNotEmpty) ...[
              Text('📋 Summary', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(aiResponse.dailySummary),
              const SizedBox(height: 12),
            ],
            if (aiResponse.insight.isNotEmpty) ...[
              Text('💡 Insight', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(aiResponse.insight),
              const SizedBox(height: 12),
            ],
            if (aiResponse.suggestion.isNotEmpty) ...[
              Text('🎯 Suggestion', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(aiResponse.suggestion),
            ],
          ],
        ),
      ),
    );
  }
}
