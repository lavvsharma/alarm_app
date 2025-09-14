import 'package:flutter_test/flutter_test.dart';
import 'package:epic_alarm/models/alarm.dart';
import 'package:epic_alarm/services/scheduler.dart';

class FakeBackend implements SchedulerBackend {
  bool initialized = false;
  final List<String> scheduleIds = <String>[];
  final Map<String, DateTime> scheduledAt = <String, DateTime>{};

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> scheduleAt(String id, DateTime when, {String? payload}) async {
    scheduleIds.add(id);
    scheduledAt[id] = when;
  }

  @override
  Future<void> cancel(String id) async {
    scheduledAt.remove(id);
  }

  @override
  bool isKnown(String id) => scheduledAt.containsKey(id);
}

void main() {
  group('AlarmSchedulerService', () {
    test('scheduleAlarm delegates to backend and tracks known id', () async {
      final backend = FakeBackend();
      final service = AlarmSchedulerService(backend: backend);

      final alarm = Alarm(
        id: 'a1',
        label: 'Test',
        timeOfDay: const TimeOfDayModel(hour: 8, minute: 30),
        repeat: AlarmRepeat.once,
        enabled: true,
        sound: 'default',
        challenge: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await service.scheduleAlarm(alarm);

      expect(backend.initialized, isTrue);
      expect(backend.scheduleIds, contains('a1'));
      expect(service.isScheduled('a1'), isTrue);
    });

    test('cancelAlarm delegates to backend and clears known id', () async {
      final backend = FakeBackend();
      final service = AlarmSchedulerService(backend: backend);
      final now = DateTime.now();

      await backend.initialize();
      await backend.scheduleAt('a2', now);
      expect(service.isScheduled('a2'), isFalse); // service consults backend map only

      // After we schedule through service, it should be known.
      final alarm = Alarm(
        id: 'a2',
        label: 'Test2',
        timeOfDay: const TimeOfDayModel(hour: 7, minute: 0),
        repeat: AlarmRepeat.daily,
        enabled: true,
        sound: 'default',
        challenge: null,
        createdAt: now,
        updatedAt: now,
      );
      await service.scheduleAlarm(alarm);
      expect(service.isScheduled('a2'), isTrue);

      await service.cancelAlarm('a2');
      expect(service.isScheduled('a2'), isFalse);
    });
  });
}

