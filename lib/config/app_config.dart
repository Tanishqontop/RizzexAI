/// App-wide constants for deep links, legal URLs, and store identity.
class AppConfig {
  AppConfig._();

  static const String androidPackageId = 'com.rizzexai.app';

  static const String authRedirectUrl = '$androidPackageId://login-callback/';

  /// Replace with your hosted privacy policy before Play Store submission.
  static const String privacyPolicyUrl = 'https://rizzexai.com/privacy';

  /// Replace with your hosted terms of service before Play Store submission.
  static const String termsOfServiceUrl = 'https://rizzexai.com/terms';

  static const String supportEmail = 'support@rizzexai.com';
}
