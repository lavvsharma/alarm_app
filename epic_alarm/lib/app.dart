import 'package:flutter/material.dart';
import 'routes.dart';

class EpicAlarmApp extends StatelessWidget {
  const EpicAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epic Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.buildRoutes(),
    );
  }
}

