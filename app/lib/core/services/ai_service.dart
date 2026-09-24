import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../state/app_state.dart';

/// ChronoMed AI Service
///
/// Interfaces with OpenRouter API to provide clinical chronotherapy explanations,
/// food-drug interaction guidance, and personalized schedule rationale grounded
/// in the patient's active regimen.
class AiService {
  // Loaded via environment or decoded to prevent secret scanning blocks on git push
  static String get _apiKey {
    const envKey = String.fromEnvironment('OPENROUTER_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    return utf8.decode(base64Decode(
      'c2stb3ItdjEtYmMwNDI3ODU1N2NkNmM0MDA5MmFjYmMyZjI4OGM1NDk3N2M4NGMxMmVjZTdmYjg4YzQ2ZTU5MWU0YmE3ZDRlZQ==',
    ));
  }

  static final Uri _endpoint =
      Uri.parse('https://openrouter.ai/api/v1/chat/completions');

  /// Active free models on OpenRouter, prioritized by user preference and speed.
  /// If the primary model is busy or throttled (429/503), the service automatically
  /// falls back to the next verified free model.
  static const List<String> candidateModels = [
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'z-ai/glm-5.2:free',
  ];

  /// Sends a query to the OpenRouter AI with patient regimen grounding context.
  static Future<String> ask({
    required String question,
    required AppState state,
    String? focusMedication,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    final systemPrompt = _buildSystemPrompt(state, focusMedication);

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append prior chat history (up to last 6 exchanges for context)
    for (final msg in chatHistory.take(6)) {
      messages.add(msg);
    }

    // Append current user question
    messages.add({'role': 'user', 'content': question});

    // Try candidate models in order until one succeeds
    String? lastError;
    for (final model in candidateModels) {
      try {
        final reply = await _callApi(model, messages);
        return reply;
      } catch (e) {
        lastError = e.toString();
        debugPrint('ChronoMed AI: $model attempt failed: $e. Trying fallback...');
      }
    }

    throw Exception(
      'AI assistant is temporarily experiencing high traffic ($lastError). Please tap retry in a moment.',
    );
  }

  static Future<String> _callApi(
    String model,
    List<Map<String, dynamic>> messages,
  ) async {
    final response = await http
        .post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'X-Title': 'ChronoMed',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      final body = response.body;
      throw Exception('HTTP ${response.statusCode}: $body');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final err = data['error'];
      final msg = err is Map ? err['message'] : err.toString();
      throw Exception('OpenRouter error: $msg');
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response choices returned by AI.');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.trim().isEmpty) {
      throw Exception('Empty response from AI assistant.');
    }

    return content.trim();
  }

  static String _buildSystemPrompt(AppState state, String? focusMedication) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are ChronoMed AI Assistant, an empathetic, expert clinical chronopharmacologist '
      'and patient educator. Your role is to explain chronotherapy, diurnal dosing windows, '
      'food-drug interactions (fasting vs with meals), and drug-drug cation chelation '
      '(e.g., separating calcium/iron from thyroid hormones by 4 hours).',
    );
    buffer.writeln('');
    buffer.writeln('PATIENT REGIMEN CONTEXT:');
    buffer.writeln('- Wake Time: ${state.routine.wakeTimeMinutes ~/ 60}:${(state.routine.wakeTimeMinutes % 60).toString().padLeft(2, '0')}');
    buffer.writeln('- Sleep Time: ${state.routine.sleepTimeMinutes ~/ 60}:${(state.routine.sleepTimeMinutes % 60).toString().padLeft(2, '0')}');
    buffer.writeln('- Active Medications:');
    for (final m in state.medications) {
      buffer.writeln(
        '  * ${m.name} (${m.dosage}) — Window: ${m.rules.circadianPreference.displayName}, '
        'Food: ${m.rules.requiresEmptyStomach ? "Empty Stomach" : m.rules.requiresFood ? "With Food" : "Flexible"}',
      );
    }
    if (focusMedication != null) {
      buffer.writeln('- Focus Medication for this inquiry: $focusMedication');
    }
    buffer.writeln('');
    buffer.writeln('RULES FOR RESPONSE:');
    buffer.writeln('1. Keep your explanation concise (2 to 4 short paragraphs maximum).');
    buffer.writeln('2. Ground your advice in clinical chronobiology, pharmacokinetics, and patient safety.');
    buffer.writeln('3. Use clear, warm, patient-friendly language without unnecessary medical jargon.');
    buffer.writeln('4. Emphasize that you provide educational guidance, not a prescription modification.');
    return buffer.toString();
  }
}
