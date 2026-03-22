import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ai_response.dart';
import '../models/entry.dart';

/// Service for communicating with the local FastAPI backend.
class ApiService {
  /// Backend base URL – Ollama + FastAPI running locally.
  static const String _baseUrl = 'http://localhost:8000';

  /// POST /analyze – send daily entry, get AI analysis back.
  Future<AIResponse> analyzeEntry(Entry entry) async {
    final uri = Uri.parse('$_baseUrl/analyze');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toApiJson()),
      ).timeout(const Duration(seconds: 120)); // Ollama can be slow

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AIResponse.fromJson(json);
      } else {
        throw ApiException(
          'Analysis failed (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Cannot reach backend: $e');
    }
  }

  /// POST /transcribe – stub voice transcription.
  Future<String> transcribe() async {
    final uri = Uri.parse('$_baseUrl/transcribe');

    try {
      final response = await http.post(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['text'] as String? ?? '';
      } else {
        throw ApiException('Transcription failed: ${response.body}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Transcription service unavailable: $e');
    }
  }

  /// Simple health check.
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
