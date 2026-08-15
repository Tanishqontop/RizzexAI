import 'gemini_config.dart';

class BioUpgraderService {
  static Future<String> generateUpgradedBio(
    String inputBio,
    String style,
  ) async {
    return GeminiConfig.generateText(
      "You're a creative bio generator. Upgrade this dating app bio into something "
      'more compelling in a $style tone. Be brief, original, and attention-grabbing:\n\n'
      '"$inputBio"',
    );
  }
}
