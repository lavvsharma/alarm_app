import 'package:flutter_test/flutter_test.dart';
import 'package:epic_alarm/models/alarm.dart';
import 'package:epic_alarm/services/time_utils.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    // Use a known DST zone for deterministic tests
    tz.setLocalLocation(tz.getLocation('America/New_York'));
  });

  group('TimeUtils DST handling', () {
    test('spring forward nonexistent time rolls forward to next valid instant', () async {
      final Alarm alarm = Alarm(
        id: 'a1',
        label: 'SF',
        timeOfDay: const TimeOfDayModel(hour: 2, minute: 30),
        repeat: AlarmRepeat.once,
        enabled: true,
        sound: 'default',
        challenge: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2025, 3, 9, 1, 0); // Before jump
      final DateTime next = TimeUtils.nextOccurrenceForAlarm(alarm, now.toLocal());

      // Expect the result to be 3:00 AM or later on the same day due to DST jump
      final tz.TZDateTime tzNext = tz.TZDateTime.from(next, tz.local);
      expect(tzNext.year, 2025);
      expect(tzNext.month, 3);
      expect(tzNext.day, 9);
      expect(tzNext.hour >= 3, isTrue);
    });

    test('fall back ambiguous time picks the first occurrence if now is before', () async {
      final Alarm alarm = Alarm(
        id: 'a2',
        label: 'FB',
        timeOfDay: const TimeOfDayModel(hour: 1, minute: 30),
        repeat: AlarmRepeat.once,
        enabled: true,
        sound: 'default',
        challenge: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2025, 11, 2, 0, 45); // Before fallback 2:00->1:00
      final DateTime next = TimeUtils.nextOccurrenceForAlarm(alarm, now.toLocal());
      final tz.TZDateTime tzNext = tz.TZDateTime.from(next, tz.local);

      expect(tzNext.year, 2025);
      expect(tzNext.month, 11);
      expect(tzNext.day, 2);
      expect(tzNext.hour, 1);
      expect(tzNext.minute, 30);
    });

    test('fall back when now past first 1:30 selects second occurrence or next day', () async {
      final Alarm alarm = Alarm(
        id: 'a3',
        label: 'FB2',
        timeOfDay: const TimeOfDayModel(hour: 1, minute: 30),
        repeat: AlarmRepeat.once,
        enabled: true,
        sound: 'default',
        challenge: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // After first 1:30 but before second 1:30 after fallback
      final tz.TZDateTime now = tz.TZDateTime(tz.local, 2025, 11, 2, 1, 45);
      final DateTime next = TimeUtils.nextOccurrenceForAlarm(alarm, now.toLocal());
      final tz.TZDateTime tzNext = tz.TZDateTime.from(next, tz.local);

      // It should be 1:30 again after fallback or next day at 1:30 if ambiguous resolution rolls forward to 2:30
      expect(tzNext.hour == 1 || tzNext.day == 3, isTrue);
      expect(tzNext.minute, 30);
    });
  });
}

