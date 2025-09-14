import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/alarm.dart';

/// A thin abstraction for scheduling/canceling alarms.
/// Replace internals with local_notifications/android_alarm_manager as needed.
class AlarmSchedulerService {
  final Map<String, Alarm> _scheduled = <String, Alarm>{};

  Future<void> schedule(Alarm alarm) async {
    // In a real implementation, compute next DateTime based on repeat and timeOfDay
    _scheduled[alarm.id] = alarm;
    debugPrint('Scheduled alarm ${alarm.id} at ${alarm.timeOfDay.hour}:${alarm.timeOfDay.minute}');
  }

  Future<void> cancel(String alarmId) async {
    _scheduled.remove(alarmId);
    debugPrint('Canceled alarm $alarmId');
  }

  Future<void> reschedule(Alarm alarm) async {
    await cancel(alarm.id);
    await schedule(alarm);
  }

  bool isScheduled(String alarmId) => _scheduled.containsKey(alarmId);
}

