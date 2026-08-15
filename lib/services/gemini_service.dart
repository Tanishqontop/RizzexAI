import 'gemini_config.dart';

class GeminiService {
  static Future<String> generateReplies(String chatText) async {
    return GeminiConfig.generateText(
      "You're a girl pickup artist with 12 years of Experirience. "
      'Suggest 4 witty, charming, and engaging replies to the following message:\n\n'
      '$chatText',
    );
  }
}
