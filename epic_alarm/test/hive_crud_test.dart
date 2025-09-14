import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import 'package:epic_alarm/models/alarm.dart';
import 'package:epic_alarm/models/challenge.dart';
import 'package:epic_alarm/services/storage/hive_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hive CRUD - Alarm', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(p.join(tempDir.path, 'hive'));
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlarmRepeatAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TimeOfDayModelAdapter());
      if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ChallengeTypeAdapter());
      if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ChallengeAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AlarmAdapter());
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('create, read, update, delete', () async {
      final service = HiveStorageService();
      await Hive.openBox<Alarm>(HiveStorageService.alarmsBoxName);

      final alarm = Alarm(
        id: 'a1',
        label: 'Morning',
        timeOfDay: const TimeOfDayModel(hour: 7, minute: 30),
        repeat: AlarmRepeat.weekdays,
        enabled: true,
        sound: 'default',
        challenge: const Challenge(
          type: ChallengeType.math,
          payload: '{"op":"+","a":3,"b":4}',
          answer: ['7'],
          difficulty: 'easy',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create
      await service.upsertAlarm(alarm);

      // Read
      final loaded = await service.getAlarm('a1');
      expect(loaded, isNotNull);
      expect(loaded!.label, 'Morning');
      expect(loaded.timeOfDay.hour, 7);

      // Update
      loaded.label = 'Morning Updated';
      loaded.updatedAt = DateTime.now();
      await service.upsertAlarm(loaded);
      final updated = await service.getAlarm('a1');
      expect(updated!.label, 'Morning Updated');

      // Delete
      await service.deleteAlarm('a1');
      final deleted = await service.getAlarm('a1');
      expect(deleted, isNull);
    });
  });
}

