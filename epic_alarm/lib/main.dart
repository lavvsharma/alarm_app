import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage/hive_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.initialize();
  runApp(const EpicAlarmApp());
}
