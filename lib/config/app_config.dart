/// App-wide constants for deep links, legal URLs, and store identity.
class AppConfig {
  AppConfig._();

  static const String androidPackageId = 'com.rizzexai.app';

  static const String authRedirectUrl = '$androidPackageId://login-callback/';

  static const String websiteBaseUrl = 'https://rizzex-ai-website.vercel.app';

  static const String privacyPolicyUrl = '$websiteBaseUrl/privacy';

  static const String termsOfServiceUrl = '$websiteBaseUrl/terms';

  static const String childSafetyStandardsUrl = '$websiteBaseUrl/child-safety';

  static const String externalDeleteAccountUrl = '$websiteBaseUrl/delete-account';

  static const String supportEmail = 'tanbusin@gmail.com';

  static const String secondaryContactEmail = 'tanbusin@gmail.com';

  static const String developerName = 'Tanishq Pratap';

  static const String developerLocation = 'Bengaluru, Karnataka, India';
}
