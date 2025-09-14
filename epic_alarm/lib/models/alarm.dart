import 'challenge.dart';

enum AlarmRepeat { once, daily, weekdays, weekends }

class TimeOfDayModel {
  final int hour;
  final int minute;

  const TimeOfDayModel({required this.hour, required this.minute});
}

class Alarm {
  String id;
  String label;
  TimeOfDayModel timeOfDay;
  AlarmRepeat repeat;
  bool enabled;
  String sound;
  Challenge? challenge;
  DateTime createdAt;
  DateTime updatedAt;

  Alarm({
    required this.id,
    required this.label,
    required this.timeOfDay,
    required this.repeat,
    required this.enabled,
    required this.sound,
    required this.challenge,
    required this.createdAt,
    required this.updatedAt,
  });
}

