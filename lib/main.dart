import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    debugPrint("Firebase init optional: $e");
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

// Professional Animated Splash Screen
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainWebScreen()),
      );
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

// Main Interactive WebView Screen with Full UI Controls
class MainWebScreen extends StatefulWidget {
  const MainWebScreen({super.key});

  @override
  State<MainWebScreen> createState() => _MainWebScreenState();
}

class _MainWebScreenState extends State<MainWebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.targetUrl));
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.reload(),
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  color: AppConfig.primaryColor,
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
        ),
        // Dynamic Floating Action Button (Optional)
        floatingActionButton: AppConfig.showFab
            ? FloatingActionButton(
                backgroundColor: AppConfig.primaryColor,
                onPressed: () {
                  if (AppConfig.fabActionUrl.isNotEmpty) {
                    _controller.loadRequest(Uri.parse(AppConfig.fabActionUrl));
                  } else {
                    _controller.reload();
                  }
                },
                child: const Icon(Icons.send, color: Colors.white),
              )
            : null,
        // Dynamic Bottom Navigation Bar (Optional)
        bottomNavigationBar: AppConfig.showBottomNav
            ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                selectedItemColor: AppConfig.primaryColor,
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  if (index == 0) _controller.loadRequest(Uri.parse(AppConfig.targetUrl));
                  if (index == 1) _controller.goBack();
                  if (index == 2) _controller.goForward();
                  if (index == 3) _controller.reload();
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: 'Back'),
                  BottomNavigationBarItem(icon: Icon(Icons.arrow_forward), label: 'Forward'),
                  BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Reload'),
                ],
              )
            : null,
      ),
    );
  }
}
