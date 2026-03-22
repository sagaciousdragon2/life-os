/// AI analysis response from the FastAPI backend.
class AIResponse {
  final Map<String, dynamic>? updatedFields;
  final List<Map<String, String>> newCategories;
  final String dailySummary;
  final String insight;
  final String suggestion;

  const AIResponse({
    this.updatedFields,
    this.newCategories = const [],
    required this.dailySummary,
    required this.insight,
    required this.suggestion,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> cats = [];
    if (json['new_categories'] != null) {
      cats = (json['new_categories'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }

    return AIResponse(
      updatedFields: json['updated_fields'] as Map<String, dynamic>?,
      newCategories: cats,
      dailySummary: json['daily_summary'] as String? ?? '',
      insight: json['insight'] as String? ?? '',
      suggestion: json['suggestion'] as String? ?? '',
    );
  }
}
