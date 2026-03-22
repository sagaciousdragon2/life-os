import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/entry.dart';
import '../models/ai_response.dart';
import '../services/api_service.dart';
import '../services/database.dart';

// ── Singletons ──────────────────────────────────────────────────────────

final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());
final apiProvider = Provider<ApiService>((ref) => ApiService());

// ── Today form state ────────────────────────────────────────────────────

/// Holds the mutable state of today's entry form.
class TodayFormState {
  final int mood;
  final int focus;
  final double sleepHours;
  final String tasksPlanned;
  final String tasksCompleted;
  final String obstacles;
  final String wins;
  final String diet;
  final String freeform;
  final List<File> photoFiles;
  final bool isSubmitting;
  final AIResponse? aiResponse;
  final String? errorMessage;

  const TodayFormState({
    this.mood = 5,
    this.focus = 5,
    this.sleepHours = 7.0,
    this.tasksPlanned = '',
    this.tasksCompleted = '',
    this.obstacles = '',
    this.wins = '',
    this.diet = '',
    this.freeform = '',
    this.photoFiles = const [],
    this.isSubmitting = false,
    this.aiResponse = null,
    this.errorMessage = null,
  });

  TodayFormState copyWith({
    int? mood,
    int? focus,
    double? sleepHours,
    String? tasksPlanned,
    String? tasksCompleted,
    String? obstacles,
    String? wins,
    String? diet,
    String? freeform,
    List<File>? photoFiles,
    bool? isSubmitting,
    AIResponse? aiResponse,
    String? errorMessage,
    bool clearError = false,
    bool clearAI = false,
  }) {
    return TodayFormState(
      mood: mood ?? this.mood,
      focus: focus ?? this.focus,
      sleepHours: sleepHours ?? this.sleepHours,
      tasksPlanned: tasksPlanned ?? this.tasksPlanned,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      obstacles: obstacles ?? this.obstacles,
      wins: wins ?? this.wins,
      diet: diet ?? this.diet,
      freeform: freeform ?? this.freeform,
      photoFiles: photoFiles ?? this.photoFiles,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      aiResponse: clearAI ? null : (aiResponse ?? this.aiResponse),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier for the Today entry form.
class TodayFormNotifier extends StateNotifier<TodayFormState> {
  final Ref ref;

  TodayFormNotifier(this.ref) : super(const TodayFormState()) {
    _loadExistingEntry();
  }

  /// If there's already an entry for today, load it into the form.
  Future<void> _loadExistingEntry() async {
    final db = ref.read(databaseProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final existing = await db.getEntryByDate(today);
    if (existing != null) {
      state = TodayFormState(
        mood: existing.mood,
        focus: existing.focus,
        sleepHours: existing.sleepHours,
        tasksPlanned: existing.tasksPlanned,
        tasksCompleted: existing.tasksCompleted,
        obstacles: existing.obstacles,
        wins: existing.wins,
        diet: existing.diet,
        freeform: existing.freeform,
      );
    }
  }

  void setMood(int v) => state = state.copyWith(mood: v);
  void setFocus(int v) => state = state.copyWith(focus: v);
  void setSleepHours(double v) => state = state.copyWith(sleepHours: v);
  void setTasksPlanned(String v) => state = state.copyWith(tasksPlanned: v);
  void setTasksCompleted(String v) => state = state.copyWith(tasksCompleted: v);
  void setObstacles(String v) => state = state.copyWith(obstacles: v);
  void setWins(String v) => state = state.copyWith(wins: v);
  void setDiet(String v) => state = state.copyWith(diet: v);
  void setFreeform(String v) => state = state.copyWith(freeform: v);

  /// Pick photos from gallery (max 3).
  Future<void> pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      final files = images.take(3).map((xfile) => File(xfile.path)).toList();
      state = state.copyWith(photoFiles: files);
    }
  }

  /// Take a photo with camera.
  Future<void> takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      final current = List<File>.from(state.photoFiles);
      if (current.length < 3) {
        current.add(File(image.path));
        state = state.copyWith(photoFiles: current);
      }
    }
  }

  /// Remove a photo by index.
  void removePhoto(int index) {
    final current = List<File>.from(state.photoFiles);
    if (index < current.length) {
      current.removeAt(index);
      state = state.copyWith(photoFiles: current);
    }
  }

  /// Stub voice transcription.
  Future<void> transcribeVoice() async {
    final api = ref.read(apiProvider);
    try {
      final text = await api.transcribe();
      state = state.copyWith(
        freeform: '${state.freeform}\n[Voice] $text'.trim(),
      );
    } catch (_) {
      // Fallback: append placeholder text
      state = state.copyWith(
        freeform: '${state.freeform}\n[Voice] (transcription placeholder — mic recorded)'.trim(),
      );
    }
  }

  /// Calculate completion percentage from planned vs completed tasks.
  int? _calcCompletion() {
    final planned = state.tasksPlanned.trim().split('\n').where((l) => l.trim().isNotEmpty).length;
    final completed = state.tasksCompleted.trim().split('\n').where((l) => l.trim().isNotEmpty).length;
    if (planned == 0) return null;
    return ((completed / planned) * 100).round().clamp(0, 100);
  }

  /// Submit entry: convert photos → base64, call backend, save to DB.
  Future<void> submitEntry() async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearAI: true);

    try {
      // Encode photos to base64
      final photosB64 = <String>[];
      for (final file in state.photoFiles) {
        final bytes = await file.readAsBytes();
        photosB64.add(base64Encode(bytes));
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final completion = _calcCompletion();

      final entry = Entry(
        id: const Uuid().v4(),
        date: today,
        mood: state.mood,
        focus: state.focus,
        sleepHours: state.sleepHours,
        tasksPlanned: state.tasksPlanned,
        tasksCompleted: state.tasksCompleted,
        obstacles: state.obstacles,
        wins: state.wins,
        diet: state.diet,
        freeform: state.freeform,
        photosBase64: photosB64,
        completionPercent: completion,
      );

      // Call backend for AI analysis
      final api = ref.read(apiProvider);
      AIResponse? aiResp;
      try {
        aiResp = await api.analyzeEntry(entry);
      } catch (_) {
        // Backend unavailable – save without AI analysis
      }

      // Merge AI response into the entry
      final enrichedEntry = entry.copyWith(
        dailySummary: aiResp?.dailySummary,
        insight: aiResp?.insight,
        suggestion: aiResp?.suggestion,
        newCategories: aiResp?.newCategories,
        completionPercent: completion,
      );

      // Save to local DB
      final db = ref.read(databaseProvider);
      await db.upsertEntry(enrichedEntry);

      state = state.copyWith(isSubmitting: false, aiResponse: aiResp);

      // Invalidate history so it reloads
      ref.invalidate(historyEntriesProvider);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  /// Reset form for a new day.
  void resetForm() {
    state = const TodayFormState();
  }
}

final todayFormProvider = StateNotifierProvider<TodayFormNotifier, TodayFormState>(
  (ref) => TodayFormNotifier(ref),
);

// ── History ─────────────────────────────────────────────────────────────

final historyEntriesProvider = FutureProvider<List<Entry>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getAllEntries();
});

// ── Insights ────────────────────────────────────────────────────────────

enum InsightRange { daily, weekly, monthly }

final insightRangeProvider = StateProvider<InsightRange>((ref) => InsightRange.weekly);

final insightEntriesProvider = FutureProvider<List<Entry>>((ref) async {
  final range = ref.watch(insightRangeProvider);
  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd');

  late String start;
  switch (range) {
    case InsightRange.daily:
      start = fmt.format(now);
      break;
    case InsightRange.weekly:
      start = fmt.format(now.subtract(const Duration(days: 7)));
      break;
    case InsightRange.monthly:
      start = fmt.format(now.subtract(const Duration(days: 30)));
      break;
  }

  return db.getEntriesInRange(start, fmt.format(now));
});

// ── Progress ────────────────────────────────────────────────────────────

enum ProgressRange { week, month, all }

final progressRangeProvider = StateProvider<ProgressRange>((ref) => ProgressRange.week);

final progressEntriesProvider = FutureProvider<List<Entry>>((ref) async {
  final range = ref.watch(progressRangeProvider);
  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd');

  late String start;
  switch (range) {
    case ProgressRange.week:
      start = fmt.format(now.subtract(const Duration(days: 7)));
      break;
    case ProgressRange.month:
      start = fmt.format(now.subtract(const Duration(days: 30)));
      break;
    case ProgressRange.all:
      start = '2000-01-01';
      break;
  }

  return db.getEntriesInRange(start, fmt.format(now));
});
