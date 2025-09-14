import 'package:flutter/material.dart';
import 'screens/alarm_list.dart';
import 'screens/alarm_edit.dart';
import 'screens/challenge_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String alarmEdit = '/alarm_edit';
  static const String challenge = '/challenge';
  static const String challenge = '/challenge';

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      splash: (context) => const _SplashScreen(),
      home: (context) => const AlarmListScreen(),
      alarmEdit: (context) => const AlarmEditScreen(),
      challenge: (context) {
        final String alarmId = ModalRoute.of(context)!.settings.arguments as String;
        return ChallengeScreen(alarmId: alarmId);
      },
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

// Home replaced by AlarmListScreen

