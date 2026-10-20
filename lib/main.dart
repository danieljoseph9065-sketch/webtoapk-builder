import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

Color parseColor(String hex) {
  try {
    String cleanHex = hex.replaceAll("#", "");
    if (cleanHex.length == 6) cleanHex = "FF$cleanHex";
    return Color(int.parse(cleanHex, radix: 16));
  } catch (e) {
    return const Color(0xFF4F46E5);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = parseColor(AppConfig.themeColor);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: true,
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
    Timer(Duration(seconds: AppConfig.splashDuration), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final splashBg = parseColor(AppConfig.splashBg);
    return Scaffold(
      backgroundColor: splashBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.public, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              AppConfig.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(AppConfig.enableZoom)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.parse(request.url);
            if (uri.scheme == 'tel' || uri.scheme == 'mailto' || uri.scheme == 'whatsapp') {
              launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.targetUrl));
  }

  void _triggerFabAction() async {
    if (AppConfig.fabUrl.isNotEmpty) {
      final uri = Uri.parse(AppConfig.fabUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _controller.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = parseColor(AppConfig.themeColor);

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
                title: Text(AppConfig.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 1,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _controller.reload(),
                  ),
                ],
              )
            : null,
        body: Stack(
          children: [
            AppConfig.enableRefresh
                ? RefreshIndicator(
                    onRefresh: () async => _controller.reload(),
                    child: WebViewWidget(controller: _controller),
                  )
                : WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(color: primaryColor, backgroundColor: Colors.transparent),
          ],
        ),
        bottomNavigationBar: AppConfig.showBottomNav
            ? BottomNavigationBar(
                currentIndex: 0,
                selectedItemColor: primaryColor,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                onTap: (index) async {
                  switch (index) {
                    case 0:
                      _controller.loadRequest(Uri.parse(AppConfig.targetUrl));
                      break;
                    case 1:
                      if (await _controller.canGoBack()) _controller.goBack();
                      break;
                    case 2:
                      if (await _controller.canGoForward()) _controller.goForward();
                      break;
                    case 3:
                      _controller.reload();
                      break;
                    case 4:
                      Share.share("Check out ${AppConfig.appName}: ${AppConfig.targetUrl}");
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: 'Back'),
                  BottomNavigationBarItem(icon: Icon(Icons.arrow_forward), label: 'Forward'),
                  BottomNavigationBarItem(icon: Icon(Icons.refresh), label: 'Reload'),
                  BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
                ],
              )
            : null,
        floatingActionButton: AppConfig.showFab
            ? FloatingActionButton(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                onPressed: _triggerFabAction,
                child: const Icon(Icons.chat),
              )
            : null,
      ),
    );
  }
}
