import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'time_utils.dart';

import '../models/alarm.dart';
import 'storage/hive_storage.dart';
import '../routes.dart';
import 'navigation.dart';
import 'platform_permissions.dart';

/// Cross-platform scheduler abstraction.
/// Exposes scheduleAlarm/cancelAlarm/rescheduleAllOnBoot and delegates to a pluggable backend.
class AlarmSchedulerService {
  final SchedulerBackend _backend;
  bool _initialized = false;
  final PlatformPermissionsService _permissions = PlatformPermissionsService();

  AlarmSchedulerService({SchedulerBackend? backend})
      : _backend = backend ?? (Platform.isAndroid ? AndroidExactAlarmBackend() : LocalNotificationsBackend());

  /// Call once during app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    // Initialize timezone database (best effort). We default to device local.
    try {
      await TimeUtils.ensureInitialized();
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
    // Enforce required permissions for exact alarms on Android
    if (Platform.isAndroid && _backend is AndroidExactAlarmBackend) {
      final PermissionsSnapshot snapshot = await _permissions.currentSnapshot(persist: true);
      final List<String> missing = <String>[];
      if (!snapshot.notificationsGranted) missing.add('Notifications');
      if (!snapshot.exactAlarmGranted) missing.add('Exact Alarms');
      if (missing.isNotEmpty) {
        throw MissingPermissionsException(missing: missing);
      }
    }
    final DateTime next = TimeUtils.nextOccurrenceForAlarm(alarm, DateTime.now());
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

  /// Schedule a one-shot snooze re-trigger at [when].
  Future<void> snoozeUntil(String alarmId, DateTime when) async {
    if (!_initialized) {
      await initialize();
    }
    await _backend.scheduleAt(alarmId, when, payload: alarmId);
  }

  // Legacy private method removed. Logic moved to TimeUtils.
}

class MissingPermissionsException implements Exception {
  final List<String> missing;

  MissingPermissionsException({required this.missing});

  @override
  String toString() => 'MissingPermissionsException(missing: ${missing.join(', ')})';
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
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final String? payload = response.payload;
        if (payload != null) {
          try {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final navigator = NavigationService.navigatorKey.currentState;
              navigator?.pushNamed(AppRoutes.challenge, arguments: payload);
            });
          } catch (_) {
            // ignore navigation errors in background
          }
        }
      },
    );
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
  // TODO: Launch full-screen challenge screen via platform channel or background isolate.
}

