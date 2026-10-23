import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConvertedWebApp());
}

Color parseHexColor(String hex, Color fallback) {
  try {
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.parse(clean, radix: 16));
  } catch (_) {
    return fallback;
  }
}

class BottomTabItem {
  final String title;
  final String iconKey;
  final String url;
  BottomTabItem({required this.title, required this.iconKey, required this.url});
}

List<BottomTabItem> parseCustomBottomButtons() {
  final raw = AppConfig.bottomButtonsData.trim();
  final List<BottomTabItem> items = [];
  if (raw.isNotEmpty) {
    final parts = raw.split(';;');
    for (final part in parts) {
      if (part.trim().isEmpty) continue;
      final fields = part.split('|');
      final title = fields.isNotEmpty && fields[0].trim().isNotEmpty ? fields[0].trim() : 'Home';
      final icon = fields.length > 1 && fields[1].trim().isNotEmpty ? fields[1].trim() : 'home';
      final url = fields.length > 2 && fields[2].trim().isNotEmpty ? fields[2].trim() : AppConfig.targetUrl;
      items.add(BottomTabItem(title: title, iconKey: icon, url: url));
    }
  }
  if (items.isEmpty) {
    items.addAll([
      BottomTabItem(title: 'Home', iconKey: 'home', url: AppConfig.targetUrl),
      BottomTabItem(title: 'Shop', iconKey: 'shop', url: AppConfig.targetUrl),
      BottomTabItem(title: 'Offers', iconKey: 'offer', url: AppConfig.targetUrl),
      BottomTabItem(title: 'Support', iconKey: 'chat', url: AppConfig.targetUrl),
    ]);
  }
  final count = AppConfig.bottomButtonsCount.clamp(2, 5);
  return items.take(count).toList();
}

IconData resolveIconData(String key) {
  switch (key.toLowerCase()) {
    case 'home':
      return Icons.home_rounded;
    case 'shop':
      return Icons.storefront_rounded;
    case 'cart':
      return Icons.shopping_cart_rounded;
    case 'offer':
      return Icons.local_offer_rounded;
    case 'chat':
    case 'whatsapp':
      return Icons.chat_bubble_rounded;
    case 'call':
      return Icons.phone_rounded;
    case 'profile':
    case 'user':
      return Icons.person_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'reload':
      return Icons.refresh_rounded;
    case 'share':
      return Icons.share_rounded;
    default:
      return Icons.language_rounded;
  }
}

class ConvertedWebApp extends StatelessWidget {
  const ConvertedWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = parseHexColor(AppConfig.themeColor, const Color(0xFF4F46E5));
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor, primary: themeColor),
        useMaterial3: true,
      ),
      home: const DynamicSplashScreen(),
    );
  }
}

class DynamicSplashScreen extends StatefulWidget {
  const DynamicSplashScreen({super.key});

  @override
  State<DynamicSplashScreen> createState() => _DynamicSplashScreenState();
}

class _DynamicSplashScreenState extends State<DynamicSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    final seconds = AppConfig.splashDuration.clamp(1, 10);
    Timer(Duration(seconds: seconds), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainWebShell()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = parseHexColor(AppConfig.splashBg, const Color(0xFF1E1B4B));
    final themeColor = parseHexColor(AppConfig.themeColor, const Color(0xFF4F46E5));
    final isLight = AppConfig.splashBg.toUpperCase() == '#FFFFFF';
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.45),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  AppConfig.appName.isNotEmpty ? AppConfig.appName[0].toUpperCase() : 'W',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            if (AppConfig.splashDesign == 'progress_bar')
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  color: themeColor,
                  backgroundColor: textColor.withOpacity(0.2),
                ),
              )
            else
              CircularProgressIndicator(color: textColor),
          ],
        ),
      ),
    );
  }
}

class MainWebShell extends StatefulWidget {
  const MainWebShell({super.key});

  @override
  State<MainWebShell> createState() => _MainWebShellState();
}

class _MainWebShellState extends State<MainWebShell> {
  late final WebViewController _controller;
  late final List<BottomTabItem> _bottomTabs;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;

  bool get _hasTopBar =>
      AppConfig.showAppBar ||
      ['drawer', 'bottom_drawer', 'all', 'drawer_fab'].contains(AppConfig.layoutDesign);

  bool get _hasDrawer =>
      AppConfig.showDrawer ||
      ['drawer', 'bottom_drawer', 'all', 'drawer_fab'].contains(AppConfig.layoutDesign);

  bool get _hasBottomNav =>
      AppConfig.showBottomNav ||
      ['bottom_nav', 'bottom_drawer', 'all'].contains(AppConfig.layoutDesign);

  bool get _hasFab =>
      AppConfig.showFab ||
      ['fab_only', 'all', 'drawer_fab'].contains(AppConfig.layoutDesign);

  @override
  void initState() {
    super.initState();
    _bottomTabs = parseCustomBottomButtons();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(AppConfig.enableZoom)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (err) {
            if (err.isForMainFrame == true) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_formatUrl(AppConfig.targetUrl)));
  }

  String _formatUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'https://flutter.dev';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  void _onBottomTabTap(int index) {
    setState(() => _selectedIndex = index);
    final tab = _bottomTabs[index];
    if (tab.iconKey.toLowerCase() == 'reload') {
      _controller.reload();
      return;
    }
    final target = tab.url.trim().isEmpty ? AppConfig.targetUrl : tab.url;
    _controller.loadRequest(Uri.parse(_formatUrl(target)));
  }

  void _onFabPressed() {
    if (AppConfig.fabActionType == 'whatsapp' && AppConfig.fabPhone.trim().isNotEmpty) {
      final phone = AppConfig.fabPhone.replaceAll(RegExp(r'[^0-9]'), '');
      _controller.loadRequest(Uri.parse('https://wa.me/$phone'));
    } else if (AppConfig.fabUrl.trim().isNotEmpty) {
      _controller.loadRequest(Uri.parse(_formatUrl(AppConfig.fabUrl)));
    } else {
      _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = parseHexColor(AppConfig.themeColor, const Color(0xFF4F46E5));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        appBar: _hasTopBar
            ? AppBar(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                title: Text(
                  AppConfig.appName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => _controller.reload(),
                  ),
                ],
              )
            : null,
        drawer: _hasDrawer
            ? Drawer(
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: themeColor),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          AppConfig.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    ..._bottomTabs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return ListTile(
                        leading: Icon(resolveIconData(item.iconKey), color: themeColor),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(context);
                          _onBottomTabTap(i);
                        },
                      );
                    }),
                  ],
                ),
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              if (_hasError)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 64, color: themeColor),
                        const SizedBox(height: 16),
                        const Text(
                          'No Internet Connection',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please check your internet connection and try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _controller.reload(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  color: themeColor,
                  minHeight: 3,
                ),
            ],
          ),
        ),
        floatingActionButton: _hasFab
            ? FloatingActionButton.extended(
                backgroundColor: AppConfig.fabActionType == 'whatsapp'
                    ? const Color(0xFF10B981)
                    : themeColor,
                foregroundColor: Colors.white,
                onPressed: _onFabPressed,
                icon: Icon(resolveIconData(AppConfig.fabActionType)),
                label: Text(
                  AppConfig.fabTitle.isNotEmpty ? AppConfig.fabTitle : 'Support',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
        bottomNavigationBar: _hasBottomNav
            ? BottomNavigationBar(
                currentIndex: _selectedIndex.clamp(0, _bottomTabs.length - 1),
                selectedItemColor: themeColor,
                unselectedItemColor: const Color(0xFF64748B),
                type: BottomNavigationBarType.fixed,
                onTap: _onBottomTabTap,
                items: _bottomTabs
                    .map(
                      (btn) => BottomNavigationBarItem(
                        icon: Icon(resolveIconData(btn.iconKey)),
                        label: btn.title,
                      ),
                    )
                    .toList(),
              )
            : null,
      ),
    );
  }
}
