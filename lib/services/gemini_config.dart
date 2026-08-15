import 'dart:convert';
import 'package:http/http.dart' as http;

/// Shared Gemini API settings. Models are tried in order until one succeeds.
///
/// Provide the key at build/run time:
/// `flutter run --dart-define-from-file=env.json`
/// or
/// `flutter run --dart-define=GEMINI_API_KEY=your_key`
class GeminiConfig {
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1/models';

  /// Preferred models for `generateContent` on the v1 API.
  static const List<String> generateContentModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  static Uri generateContentUri(String model) => Uri.parse(
        '$baseUrl/$model:generateContent?key=$apiKey',
      );

  static Future<String> generateText(String prompt) async {
    if (apiKey.isEmpty) {
      return 'Gemini API key is not configured. '
          'Run with --dart-define=GEMINI_API_KEY=your_key '
          'or --dart-define-from-file=env.json';
    }

    Object? lastError;

    for (final model in generateContentModels) {
      try {
        final response = await http.post(
          generateContentUri(model),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          final text = _extractText(response.body);
          if (text != null && text.isNotEmpty) {
            return text;
          }
          lastError = 'Empty response from $model';
          continue;
        }

        if (response.statusCode == 404) {
          lastError =
              _parseErrorMessage(response.body) ?? 'Model $model not found';
          continue;
        }

        return 'Gemini API Error (${response.statusCode}) using $model:\n${response.body}';
      } catch (e) {
        lastError = e;
      }
    }

    return 'Could not reach Gemini. Tried: ${generateContentModels.join(', ')}.'
        '${lastError != null ? '\nLast error: $lastError' : ''}';
  }

  static String? _extractText(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['candidates']?[0]?['content']?['parts']?[0]?['text']
        as String?;
  }

  static String? _parseErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
