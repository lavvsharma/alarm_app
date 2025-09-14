import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';
import 'storage/hive_storage.dart';

/// Cross-platform scheduler abstraction.
/// Exposes scheduleAlarm/cancelAlarm/rescheduleAllOnBoot and delegates to a pluggable backend.
class AlarmSchedulerService {
  final SchedulerBackend _backend;
  bool _initialized = false;

  AlarmSchedulerService({SchedulerBackend? backend})
      : _backend = backend ?? (Platform.isAndroid ? AndroidExactAlarmBackend() : LocalNotificationsBackend());

  /// Call once during app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    // Initialize timezone database (best effort). We default to device local.
    try {
      tz.initializeTimeZones();
      // We intentionally do not override tz.local here to avoid guessing.
      // tz.local will follow the platform default if properly configured by the timezone package.
    } catch (_) {
      // no-op if already initialized or on unsupported platforms
    }
    await _backend.initialize();
    _initialized = true;
  }

  /// Schedule the next occurrence for the given alarm.
  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!_initialized) {
      await initialize();
    }
    final DateTime next = _computeNextOccurrence(alarm, DateTime.now());
    await _backend.scheduleAt(alarm.id, next, payload: alarm.id);
  }

  /// Cancel a scheduled alarm by id.
  Future<void> cancelAlarm(String alarmId) async {
    if (!_initialized) {
      await initialize();
    }
    await _backend.cancel(alarmId);
  }

  /// Reschedule all enabled alarms found in storage (used on boot or tz changes).
  Future<void> rescheduleAllOnBoot() async {
    if (!_initialized) {
      await initialize();
    }
    final List<Alarm> alarms = await HiveStorageService().getAlarms();
    for (final Alarm alarm in alarms) {
      if (alarm.enabled) {
        await scheduleAlarm(alarm);
      }
    }
  }

  // Backwards-compat: keep the old names used by existing UI code.
  Future<void> schedule(Alarm alarm) => scheduleAlarm(alarm);
  Future<void> cancel(String alarmId) => cancelAlarm(alarmId);
  Future<void> reschedule(Alarm alarm) async {
    await cancelAlarm(alarm.id);
    await scheduleAlarm(alarm);
  }

  bool isScheduled(String alarmId) => _backend.isKnown(alarmId);

  // Computes the next DateTime in device local time for a given alarm configuration.
  DateTime _computeNextOccurrence(Alarm alarm, DateTime now) {
    final DateTime todayAtTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.timeOfDay.hour,
      alarm.timeOfDay.minute,
    );

    bool isWeekday(int weekday) => weekday >= DateTime.monday && weekday <= DateTime.friday;
    bool isWeekend(int weekday) => weekday == DateTime.saturday || weekday == DateTime.sunday;

    DateTime candidate = todayAtTime.isAfter(now) ? todayAtTime : todayAtTime.add(const Duration(days: 1));

    switch (alarm.repeat) {
      case AlarmRepeat.once:
        // If the time for today has passed, schedule for tomorrow once.
        return todayAtTime.isAfter(now) ? todayAtTime : todayAtTime.add(const Duration(days: 1));
      case AlarmRepeat.daily:
        return candidate;
      case AlarmRepeat.weekdays:
        while (!isWeekday(candidate.weekday)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
      case AlarmRepeat.weekends:
        while (!isWeekend(candidate.weekday)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        return candidate;
    }
  }
}

/// Backend interface for scheduling primitives.
abstract class SchedulerBackend {
  Future<void> initialize();
  Future<void> scheduleAt(String id, DateTime when, {String? payload});
  Future<void> cancel(String id);
  bool isKnown(String id);
}

/// Default backend using flutter_local_notifications for cross-platform local scheduling.
class LocalNotificationsBackend implements SchedulerBackend {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _known = <String, DateTime>{};

  @override
  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit, macOS: null, linux: null);
    await _plugin.initialize(initSettings);
  }

  @override
  Future<void> scheduleAt(String id, DateTime when, {String? payload}) async {
    // Convert to tz for zoned scheduling.
    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarms',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'alarm',
      playSound: true,
      enableVibration: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(presentSound: true);
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use a stable integer id derived from the string id.
    final int intId = _stableId(id);
    await _plugin.zonedSchedule(
      intId,
      'Alarm',
      'It\'s time!',
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload ?? id,
      matchDateTimeComponents: null,
    );
    _known[id] = when;
  }

  @override
  Future<void> cancel(String id) async {
    await _plugin.cancel(_stableId(id));
    _known.remove(id);
  }

  @override
  bool isKnown(String id) => _known.containsKey(id);

  int _stableId(String id) => id.hashCode & 0x7fffffff;
}

/// Android backend that uses android_alarm_manager_plus to schedule exact alarms.
/// This does not present UI by itself; subsequent tasks (C-03) will handle full-screen intent/notification.
class AndroidExactAlarmBackend implements SchedulerBackend {
  final Map<String, DateTime> _known = <String, DateTime>{};

  @override
  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  @override
  Future<void> scheduleAt(String id, DateTime when, {String? payload}) async {
    final int intId = _stableId(id);
    await AndroidAlarmManager.oneShotAt(
      when,
      intId,
      _onExactAlarmFired,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
    _known[id] = when;
  }

  @override
  Future<void> cancel(String id) async {
    await AndroidAlarmManager.cancel(_stableId(id));
    _known.remove(id);
  }

  @override
  bool isKnown(String id) => _known.containsKey(id);

  int _stableId(String id) => id.hashCode & 0x7fffffff;
}

@pragma('vm:entry-point')
void _onExactAlarmFired(int id) {
  debugPrint('Exact alarm fired: $id');
  // C-03 will handle launching full-screen UI and audio when this callback runs.
}

