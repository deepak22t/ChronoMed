import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ChronoMed Backend API Service
///
/// Connects the Flutter frontend dynamically to the FastAPI Python SQLite backend.
class ApiService {
  // Base URLs prioritized by environment
  static final List<String> _candidateBaseUrls = [
    if (kIsWeb) 'http://localhost:8000',
    'http://192.168.29.33:8000', // Local WiFi LAN IP for physical Android device
    'http://10.0.2.2:8000',      // Android Emulator loopback
    'http://127.0.0.1:8000',     // Localhost loopback
  ];

  static String? _resolvedBaseUrl;

  /// Resolves the working base URL by doing a quick health ping.
  static Future<String> getBaseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    for (final url in _candidateBaseUrls) {
      try {
        final res = await http.get(Uri.parse('$url/health')).timeout(
          const Duration(milliseconds: 1200),
        );
        if (res.statusCode == 200) {
          _resolvedBaseUrl = url;
          debugPrint('Connected to ChronoMed FastAPI Backend at: $url');
          return url;
        }
      } catch (_) {
        continue;
      }
    }

    // Default fallback
    _resolvedBaseUrl = _candidateBaseUrls.first;
    return _resolvedBaseUrl!;
  }

  /// Fetches the dynamic Today Timeline from FastAPI (Patient, Wave, Doses, Meals, Adherence)
  static Future<Map<String, dynamic>> fetchTodayTimeline({int patientId = 1}) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/v1/timeline/today?patient_id=$patientId');

    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load today timeline: ${response.statusCode} ${response.body}');
    }
  }

  /// Toggles a scheduled dose status in the SQLite database via FastAPI
  static Future<Map<String, dynamic>> toggleDose(String doseId) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/v1/timeline/doses/$doseId/toggle');

    final response = await http.post(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to toggle dose: ${response.statusCode} ${response.body}');
    }
  }

  /// Consults the ChronoMed Clinical AI Copilot via FastAPI
  static Future<Map<String, dynamic>> consultAi({
    required String query,
    int patientId = 1,
    List<Map<String, String>> history = const [],
  }) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/v1/ai/consult');

    final body = jsonEncode({
      'query': query,
      'patient_id': patientId,
      'conversation_history': history,
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } else {
      throw Exception('AI consult failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Fetches all medications from FastAPI
  static Future<List<dynamic>> fetchMedications() async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/api/v1/medications');

    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    } else {
      throw Exception('Failed to load medications: ${response.statusCode}');
    }
  }
}
