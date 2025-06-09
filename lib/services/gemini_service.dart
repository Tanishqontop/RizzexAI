import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyC8XaIz5g6e9LPl1nQzIYVmkLCdXvY1x_E';
  static const String endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey';

  static Future<String> generateReplies(String chatText) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You're a girl pickup artist with 12 years of Experirience. Suggest 4 witty, charming, and engaging replies to the following message:\n\n$chatText",
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final replies =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return replies ?? "No reply generated.";
      } else {
        return "Gemini API Error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Failed to generate reply: $e";
    }
  }
}
