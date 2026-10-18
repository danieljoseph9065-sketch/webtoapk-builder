import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'My Web App');
  static const String targetUrl = String.fromEnvironment('TARGET_URL', defaultValue: 'https://google.com');
  
  // Theme & Splash
  static const String themeColorHex = String.fromEnvironment('THEME_COLOR', defaultValue: '4F46E5');
  static const String splashBgColorHex = String.fromEnvironment('SPLASH_BG_COLOR', defaultValue: 'FFFFFF');
  static const int splashDurationSec = int.fromEnvironment('SPLASH_DURATION', defaultValue: 2);
  
  // Webview Features
  static const bool enableZoom = bool.fromEnvironment('ENABLE_ZOOM', defaultValue: true);
  static const bool enablePullToRefresh = bool.fromEnvironment('ENABLE_PULL_TO_REFRESH', defaultValue: true);
  
  // Navigation & UI
  static const bool showAppBar = bool.fromEnvironment('SHOW_APPBAR', defaultValue: false);
  static const bool showDrawer = bool.fromEnvironment('SHOW_DRAWER', defaultValue: false);
  static const bool showBottomNav = bool.fromEnvironment('SHOW_BOTTOM_NAV', defaultValue: false);
  static const String bottomNavItems = String.fromEnvironment('BOTTOM_NAV_ITEMS', defaultValue: 'home,back,forward,reload');
  
  // Floating Action Button
  static const bool showFab = bool.fromEnvironment('SHOW_FAB', defaultValue: false);
  static const String fabActionUrl = String.fromEnvironment('FAB_ACTION_URL', defaultValue: '');
  static const String fabIconType = String.fromEnvironment('FAB_ICON_TYPE', defaultValue: 'chat');

  // Color Parsers
  static Color get primaryColor => Color(int.parse('FF$themeColorHex', radix: 16));
  static Color get splashBgColor => Color(int.parse('FF$splashBgColorHex', radix: 16));
}
