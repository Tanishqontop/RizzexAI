import 'dart:convert';
import 'package:http/http.dart' as http;

class ZodiacService {
  static const String apiKey = 'AIzaSyC8XaIz5g6e9LPl1nQzIYVmkLCdXvY1x_E';
  static const String endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=$apiKey';

  static Future<String> getRizzForecast(String sign) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Give a fun, romantic, zodiac-based Rizz forecast for someone who is a $sign. Keep it charming, light-hearted, and flirtatious.",
              },
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
  }
}
