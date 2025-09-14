import 'package:flutter/material.dart';
import 'screens/alarm_list.dart';
import 'screens/alarm_edit.dart';
import 'screens/challenge_screen.dart';
import 'screens/initial_permissions_flow.dart';
import 'screens/settings.dart';
import 'screens/help/whitelist_guide.dart';
import 'services/di.dart';
import 'services/platform_permissions.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String alarmEdit = '/alarm_edit';
  static const String challenge = '/challenge';
  static const String settings = '/settings';
  static const String whitelistGuide = '/whitelist_guide';

  static Map<String, WidgetBuilder> buildRoutes() {
    return {
      splash: (context) => const _SplashScreen(),
      home: (context) => const AlarmListScreen(),
      alarmEdit: (context) => const AlarmEditScreen(),
      challenge: (context) {
        final String alarmId = ModalRoute.of(context)!.settings.arguments as String;
        return ChallengeScreen(alarmId: alarmId);
      },
      AppRoutesPermissions.initial: (context) => const InitialPermissionsFlowScreen(),
      settings: (context) => const SettingsScreen(),
      whitelistGuide: (context) => const WhitelistGuideScreen(),
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
      final PlatformPermissionsService perms = DI.permissions;
      final bool done = await perms.isOnboardingDone();
      if (done) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutesPermissions.initial);
      }
    });

    return const Scaffold(
      body: Center(
        child: Text('Epic Alarm', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
class AppRoutesPermissions {
  static const String initial = '/initial_permissions';
}


// Home replaced by AlarmListScreen

