import 'package:flutter/material.dart';

class AppConfig {
  // Core Info
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'My Web App');
  static const String targetUrl = String.fromEnvironment('TARGET_URL', defaultValue: 'https://google.com');
  
  // Theme & Splash
  static const String themeColorHex = String.fromEnvironment('THEME_COLOR', defaultValue: '4F46E5');
  static const String splashBgColorHex = String.fromEnvironment('SPLASH_BG_COLOR', defaultValue: 'FFFFFF');
  static const int splashDurationSec = int.fromEnvironment('SPLASH_DURATION', defaultValue: 2);
  
  // Top App Bar & Side Drawer Menu
  static const bool showAppBar = bool.fromEnvironment('SHOW_APPBAR', defaultValue: true);
  static const bool showDrawer = bool.fromEnvironment('SHOW_DRAWER', defaultValue: true);
  static const String drawerMenuJson = String.fromEnvironment('DRAWER_MENU', defaultValue: '');

  // Floating Action Button (FAB)
  static const bool showFab = bool.fromEnvironment('SHOW_FAB', defaultValue: false);
  static const String fabActionUrl = String.fromEnvironment('FAB_ACTION_URL', defaultValue: '');
  static const String fabIconType = String.fromEnvironment('FAB_ICON_TYPE', defaultValue: 'chat'); // chat, call, share, refresh
  
  // Dynamic Bottom Navigation Bar
  static const bool showBottomNav = bool.fromEnvironment('SHOW_BOTTOM_NAV', defaultValue: false);
  static const String bottomNavItems = String.fromEnvironment('BOTTOM_NAV_ITEMS', defaultValue: 'home,back,forward,reload'); // comma separated: home, back, forward, reload, share

  // Hardware Permissions Toggles (For runtime checks)
  static const bool enableLocation = bool.fromEnvironment('ENABLE_LOCATION', defaultValue: true);
  static const bool enableCamera = bool.fromEnvironment('ENABLE_CAMERA', defaultValue: true);
  static const bool enableStorage = bool.fromEnvironment('ENABLE_STORAGE', defaultValue: true);
  static const bool enableMic = bool.fromEnvironment('ENABLE_MIC', defaultValue: false);

  // Parsers
  static Color get primaryColor => Color(int.parse('FF$themeColorHex', radix: 16));
  static Color get splashBgColor => Color(int.parse('FF$splashBgColorHex', radix: 16));
}
