import 'package:flutter/material.dart';

class AppConfig {
  // Core Info
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'My Web App');
  static const String targetUrl = String.fromEnvironment('TARGET_URL', defaultValue: 'https://google.com');
  
  // Theme & Splash
  static const String themeColorHex = String.fromEnvironment('THEME_COLOR', defaultValue: '4F46E5');
  static const String splashBgColorHex = String.fromEnvironment('SPLASH_BG_COLOR', defaultValue: 'FFFFFF');
  static const int splashDurationSec = int.fromEnvironment('SPLASH_DURATION', defaultValue: 2);
  
  // UI Features
  static const bool showAppBar = bool.fromEnvironment('SHOW_APPBAR', defaultValue: false);
  static const bool showBottomNav = bool.fromEnvironment('SHOW_BOTTOM_NAV', defaultValue: false);
  static const bool showFab = bool.fromEnvironment('SHOW_FAB', defaultValue: false);
  static const String fabActionUrl = String.fromEnvironment('FAB_ACTION_URL', defaultValue: '');
  
  // Permissions & Features
  static const bool enableAuth = bool.fromEnvironment('ENABLE_AUTH', defaultValue: false);
  static const bool enableCamera = bool.fromEnvironment('ENABLE_CAMERA', defaultValue: true);
  static const bool enableStorage = bool.fromEnvironment('ENABLE_STORAGE', defaultValue: true);
  static const bool enablePullToRefresh = bool.fromEnvironment('ENABLE_PULL_TO_REFRESH', defaultValue: true);

  // Helper Color Parsers
  static Color get primaryColor => Color(int.parse('FF$themeColorHex', radix: 16));
  static Color get splashBgColor => Color(int.parse('FF$splashBgColorHex', radix: 16));
}
