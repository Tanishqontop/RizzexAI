import 'gemini_config.dart';

class ZodiacService {
  static Future<String> getRizzForecast(String sign) async {
    return GeminiConfig.generateText(
      'Give a fun, romantic, zodiac-based Rizz forecast for someone who is a $sign. '
      'Keep it charming, light-hearted, and flirtatious.',
    );
  }
}
