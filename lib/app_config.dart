class AppConfig {
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'My Web App');
  static const String targetUrl = String.fromEnvironment('TARGET_URL', defaultValue: 'https://google.com');
  static const bool enableAuth = bool.fromEnvironment('ENABLE_AUTH', defaultValue: false);
}
