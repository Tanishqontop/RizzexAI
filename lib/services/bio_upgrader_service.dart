import 'dart:convert';
import 'package:http/http.dart' as http;

class BioUpgraderService {
  static const String apiKey = 'AIzaSyC8XaIz5g6e9LPl1nQzIYVmkLCdXvY1x_E';
  static const String endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey';

  static Future<String> generateUpgradedBio(
    String inputBio,
    String style,
  ) async {
    final prompt = '''
You're a creative bio generator. Upgrade this dating app bio into something more compelling in a $style tone. Be brief, original, and attention-grabbing:

"$inputBio"
''';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Error: ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
