import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../../../models/alarm.dart';
import '../../../models/challenge.dart';

class AlarmRepeatAdapter extends TypeAdapter<AlarmRepeat> {
  @override
  final int typeId = 1;

  @override
  AlarmRepeat read(BinaryReader reader) {
    final index = reader.readByte();
    return AlarmRepeat.values[index];
  }

  @override
  void write(BinaryWriter writer, AlarmRepeat obj) {
    writer.writeByte(obj.index);
  }
}

class TimeOfDayModelAdapter extends TypeAdapter<TimeOfDayModel> {
  @override
  final int typeId = 2;

  @override
  TimeOfDayModel read(BinaryReader reader) {
    final hour = reader.readInt();
    final minute = reader.readInt();
    return TimeOfDayModel(hour: hour, minute: minute);
  }

  @override
  void write(BinaryWriter writer, TimeOfDayModel obj) {
    writer.writeInt(obj.hour);
    writer.writeInt(obj.minute);
  }
}

class ChallengeTypeAdapter extends TypeAdapter<ChallengeType> {
  @override
  final int typeId = 4;

  @override
  ChallengeType read(BinaryReader reader) {
    final index = reader.readByte();
    return ChallengeType.values[index];
  }

  @override
  void write(BinaryWriter writer, ChallengeType obj) {
    writer.writeByte(obj.index);
  }
}

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 5;

  @override
  Challenge read(BinaryReader reader) {
    final type = ChallengeType.values[reader.readByte()];
    final payload = reader.readString();
    final hasAnswer = reader.readBool();
    final List<String>? answer = hasAnswer ? List<String>.from(jsonDecode(reader.readString()) as List<dynamic>) : null;
    final difficulty = reader.readString();
    return Challenge(type: type, payload: payload, answer: answer, difficulty: difficulty);
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(obj.type.index)
      ..writeString(obj.payload)
      ..writeBool(obj.answer != null);
    if (obj.answer != null) {
      writer.writeString(jsonEncode(obj.answer));
    }
    writer.writeString(obj.difficulty);
  }
}

class AlarmAdapter extends TypeAdapter<Alarm> {
  @override
  final int typeId = 3;

  @override
  Alarm read(BinaryReader reader) {
    final id = reader.readString();
    final label = reader.readString();
    final timeOfDay = reader.read() as TimeOfDayModel;
    final repeat = reader.read() as AlarmRepeat;
    final enabled = reader.readBool();
    final sound = reader.readString();
    final hasChallenge = reader.readBool();
    final Challenge? challenge = hasChallenge ? reader.read() as Challenge : null;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    return Alarm(
      id: id,
      label: label,
      timeOfDay: timeOfDay,
      repeat: repeat,
      enabled: enabled,
      sound: sound,
      challenge: challenge,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, Alarm obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.label)
      ..write(obj.timeOfDay)
      ..write(obj.repeat)
      ..writeBool(obj.enabled)
      ..writeString(obj.sound)
      ..writeBool(obj.challenge != null);
    if (obj.challenge != null) {
      writer.write(obj.challenge as Challenge);
    }
    writer
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}

class HiveStorageService {
  static const String alarmsBoxName = 'alarms_box';
  static const String settingsBoxName = 'settings_box';

  static Future<void> initialize() async {
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDir.path);

    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AlarmRepeatAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TimeOfDayModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(ChallengeTypeAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ChallengeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AlarmAdapter());

    await Hive.openBox<Alarm>(alarmsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  Future<Box<Alarm>> _alarmsBox() async => Hive.openBox<Alarm>(alarmsBoxName);
  Future<Box> _settingsBox() async => Hive.openBox(settingsBoxName);

  Future<List<Alarm>> getAlarms() async {
    final box = await _alarmsBox();
    return box.values.toList(growable: false);
  }

  Future<List<String>> getAlarmIds() async {
    final box = await _alarmsBox();
    return box.keys.cast<String>().toList(growable: false);
  }

  Future<void> upsertAlarm(Alarm alarm) async {
    final box = await _alarmsBox();
    await box.put(alarm.id, alarm);
  }

  Future<Alarm?> getAlarm(String id) async {
    final box = await _alarmsBox();
    return box.get(id);
  }

  Future<void> deleteAlarm(String id) async {
    final box = await _alarmsBox();
    await box.delete(id);
  }

  Future<void> clearAll() async {
    final box = await _alarmsBox();
    await box.clear();
  }

  Future<bool?> getBoolSetting(String key) async {
    final box = await _settingsBox();
    final dynamic value = box.get(key);
    if (value is bool) return value;
    return null;
  }

  Future<void> setBoolSetting(String key, bool value) async {
    final box = await _settingsBox();
    await box.put(key, value);
  }
}

