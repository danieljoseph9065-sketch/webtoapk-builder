import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase init: $e");
  }
  runApp(const DynamicWebApp());
}

class DynamicWebApp extends StatelessWidget {
  const DynamicWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppConfig.primaryColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppConfig.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: AppConfig.splashDurationSec), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWebScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.splashBgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language, size: 80, color: AppConfig.primaryColor),
            const SizedBox(height: 20),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(color: AppConfig.primaryColor),
          ],
        ),
      ),
    );
  }
}

class MainWebScreen extends StatefulWidget {
  const MainWebScreen({super.key});

  @override
  State<MainWebScreen> createState() => _MainWebScreenState();
}

class _MainWebScreenState extends State<MainWebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _currentNavIndex = 0;
  List<String> _navItemsList = [];

  @override
  void initState() {
    super.initState();
    _parseNav();
    _initWeb();
  }

  void _parseNav() {
    if (AppConfig.showBottomNav && AppConfig.bottomNavItems.isNotEmpty) {
      _navItemsList = AppConfig.bottomNavItems.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
  }

  void _initWeb() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(AppConfig.enableZoom)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.parse(request.url);
            // Handle external schemes (WhatsApp, Mail, Tel, UPI, PlayStore)
            if (!['http', 'https'].contains(uri.scheme) ||
                request.url.contains('wa.me') ||
                request.url.contains('api.whatsapp.com') ||
                request.url.contains('play.google.com')) {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.targetUrl));
  }

  IconData _getFabIcon() {
    switch (AppConfig.fabIconType.toLowerCase()) {
      case 'call': return Icons.phone;
      case 'share': return Icons.share;
      case 'refresh': return Icons.refresh;
      case 'chat':
      default: return Icons.chat;
    }
  }

  BottomNavigationBarItem _buildNavItem(String type) {
    switch (type) {
      case 'back': return const BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: 'Back');
      case 'forward': return const BottomNavigationBarItem(icon: Icon(Icons.arrow_forward), label: 'Forward');
      case 'reload': return const BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Reload');
      case 'share': return const BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share');
      case 'home':
      default: return const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home');
    }
  }

  void _onNavTapped(int index) async {
    setState(() => _currentNavIndex = index);
    String action = _navItemsList[index];
    if (action == 'home') _controller.loadRequest(Uri.parse(AppConfig.targetUrl));
    if (action == 'back' && await _controller.canGoBack()) _controller.goBack();
    if (action == 'forward' && await _controller.canGoForward()) _controller.goForward();
    if (action == 'reload') _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent = Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          LinearProgressIndicator(color: AppConfig.primaryColor, backgroundColor: Colors.transparent),
      ],
    );

    if (AppConfig.enablePullToRefresh) {
      bodyContent = RefreshIndicator(
        color: AppConfig.primaryColor,
        onRefresh: () async => _controller.reload(),
        child: bodyContent,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppConfig.showAppBar
            ? AppBar(
                title: Text(AppConfig.appName),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () => _controller.reload()),
                ],
              )
            : null,
        drawer: AppConfig.showDrawer
            ? Drawer(
                child: ListView(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: AppConfig.primaryColor),
                      child: Center(
                        child: Text(AppConfig.appName, style: const TextStyle(color: Colors.white, fontSize: 20)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.pop(context);
                        _controller.loadRequest(Uri.parse(AppConfig.targetUrl));
                      },
                    ),
                  ],
                ),
              )
            : null,
        body: SafeArea(child: bodyContent),
        floatingActionButton: AppConfig.showFab
            ? FloatingActionButton(
                backgroundColor: AppConfig.primaryColor,
                onPressed: () async {
                  if (AppConfig.fabActionUrl.isNotEmpty) {
                    final uri = Uri.parse(AppConfig.fabActionUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } else {
                    _controller.reload();
                  }
                },
                child: Icon(_getFabIcon(), color: Colors.white),
              )
            : null,
        bottomNavigationBar: (AppConfig.showBottomNav && _navItemsList.isNotEmpty)
            ? BottomNavigationBar(
                currentIndex: _currentNavIndex >= _navItemsList.length ? 0 : _currentNavIndex,
                selectedItemColor: AppConfig.primaryColor,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                onTap: _onNavTapped,
                items: _navItemsList.map((type) => _buildNavItem(type)).toList(),
              )
            : null,
      ),
    );
  }
}
