import 'dart:convert';

/// Represents a single daily journal entry.
class Entry {
  final String id;
  final String date; // ISO‑8601 date string (yyyy-MM-dd)
  final int mood; // 1–10
  final int focus; // 1–10
  final double sleepHours;
  final String tasksPlanned;
  final String tasksCompleted;
  final String obstacles;
  final String wins;
  final String diet;
  final String freeform;
  final List<String> photosBase64; // base64-encoded images
  final int? completionPercent;

  // AI-generated fields (populated after analysis)
  final String? dailySummary;
  final String? insight;
  final String? suggestion;
  final List<Map<String, String>>? newCategories;

  const Entry({
    required this.id,
    required this.date,
    required this.mood,
    required this.focus,
    required this.sleepHours,
    required this.tasksPlanned,
    required this.tasksCompleted,
    required this.obstacles,
    required this.wins,
    required this.diet,
    required this.freeform,
    this.photosBase64 = const [],
    this.completionPercent,
    this.dailySummary,
    this.insight,
    this.suggestion,
    this.newCategories,
  });

  /// Create an [Entry] from a database row.
  factory Entry.fromMap(Map<String, dynamic> map) {
    List<String> photos = [];
    if (map['photos_base64'] != null && (map['photos_base64'] as String).isNotEmpty) {
      photos = List<String>.from(jsonDecode(map['photos_base64']));
    }

    List<Map<String, String>>? categories;
    if (map['new_categories'] != null && (map['new_categories'] as String).isNotEmpty) {
      final decoded = jsonDecode(map['new_categories']) as List;
      categories = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    return Entry(
      id: map['id'] as String,
      date: map['date'] as String,
      mood: map['mood'] as int,
      focus: map['focus'] as int,
      sleepHours: (map['sleep_hours'] as num).toDouble(),
      tasksPlanned: map['tasks_planned'] as String? ?? '',
      tasksCompleted: map['tasks_completed'] as String? ?? '',
      obstacles: map['obstacles'] as String? ?? '',
      wins: map['wins'] as String? ?? '',
      diet: map['diet'] as String? ?? '',
      freeform: map['freeform'] as String? ?? '',
      photosBase64: photos,
      completionPercent: map['completion_percent'] as int?,
      dailySummary: map['daily_summary'] as String?,
      insight: map['insight'] as String?,
      suggestion: map['suggestion'] as String?,
      newCategories: categories,
    );
  }

  /// Convert to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mood': mood,
      'focus': focus,
      'sleep_hours': sleepHours,
      'tasks_planned': tasksPlanned,
      'tasks_completed': tasksCompleted,
      'obstacles': obstacles,
      'wins': wins,
      'diet': diet,
      'freeform': freeform,
      'photos_base64': jsonEncode(photosBase64),
      'completion_percent': completionPercent,
      'daily_summary': dailySummary,
      'insight': insight,
      'suggestion': suggestion,
      'new_categories': newCategories != null ? jsonEncode(newCategories) : null,
    };
  }

  /// Convert to JSON for the backend API.
  Map<String, dynamic> toApiJson() {
    return {
      'date': date,
      'mood': mood,
      'focus': focus,
      'sleep_hours': sleepHours,
      'tasks_planned': tasksPlanned,
      'tasks_completed': tasksCompleted,
      'obstacles': obstacles,
      'wins': wins,
      'diet': diet,
      'freeform': freeform,
      'photos_base64': photosBase64,
    };
  }

  /// Create a copy with updated fields (immutable-friendly).
  Entry copyWith({
    String? id,
    String? date,
    int? mood,
    int? focus,
    double? sleepHours,
    String? tasksPlanned,
    String? tasksCompleted,
    String? obstacles,
    String? wins,
    String? diet,
    String? freeform,
    List<String>? photosBase64,
    int? completionPercent,
    String? dailySummary,
    String? insight,
    String? suggestion,
    List<Map<String, String>>? newCategories,
  }) {
    return Entry(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      focus: focus ?? this.focus,
      sleepHours: sleepHours ?? this.sleepHours,
      tasksPlanned: tasksPlanned ?? this.tasksPlanned,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      obstacles: obstacles ?? this.obstacles,
      wins: wins ?? this.wins,
      diet: diet ?? this.diet,
      freeform: freeform ?? this.freeform,
      photosBase64: photosBase64 ?? this.photosBase64,
      completionPercent: completionPercent ?? this.completionPercent,
      dailySummary: dailySummary ?? this.dailySummary,
      insight: insight ?? this.insight,
      suggestion: suggestion ?? this.suggestion,
      newCategories: newCategories ?? this.newCategories,
    );
  }

  /// Mood emoji helper.
  String get moodEmoji {
    const emojis = ['😫', '😢', '😞', '😐', '🙂', '😊', '😄', '😁', '🤩', '🔥'];
    final idx = (mood - 1).clamp(0, 9);
    return emojis[idx];
  }
}
