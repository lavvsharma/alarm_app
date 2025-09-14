import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage/hive_storage.dart';
import 'services/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.initialize();
  await DI.scheduler.initialize();
  runApp(const EpicAlarmApp());
}
