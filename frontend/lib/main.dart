import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/pages/chat_room.dart';
import 'package:frontend/pages/landing_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/register_page.dart';
import 'package:frontend/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final isLoggedIn = await AuthService.isLoggedIn();

  if (isLoggedIn == true) {
    await AuthService.initializeChatPlugin();
  }
  runApp(MyApp(isLoggedIn: isLoggedIn!));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureChatConnection();
      });
    }
  }

  void _ensureChatConnection() async {
    if (ChatConfig.instance.userId != null) {
      try {
        final chatService = ChatPlugin.chatService;
        if (!chatService.isSocketConnected) {
          await chatService.initGlobalConnection();
        } else {
          chatService.refreshGlobalConnection();
        }

        chatService.updateUserStatus(true);
      } catch (e) {
        if (kDebugMode) {
          print("Error refreshing chat connection: $e");
        }
      }
    } else {
      await AuthService.initializeChatPlugin();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isLoggedIn) return;

    if (state == AppLifecycleState.resumed) {
      _ensureChatConnection();
    } else if (state == AppLifecycleState.paused) {
      try {
        final chatService = ChatPlugin.chatService;
        chatService.updateUserStatus(false);
      } catch (e) {
        if (kDebugMode) {
          print("Error updating user status on pause: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const InitializerWidget(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/directMessages': (context) => const DirectMessages(),
      },
    );
  }
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  String? initialRoute;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final isLoggedIn = await AuthService.isLoggedIn();

    if (isLoggedIn == true) {
      initialRoute = '/landing';
    } else {
      initialRoute = '/landing';
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(initialRoute!);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
