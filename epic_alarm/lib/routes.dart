import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      splash: (context) => const _SplashScreen(),
      home: (context) => const _HomeScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });

    return const Scaffold(
      body: Center(
        child: Text('Epic Alarm', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home placeholder')),
    );
  }
}

