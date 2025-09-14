import 'dart:async';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

/// Timezone-aware helpers for computing next alarm occurrences.
class TimeUtils {
  static bool _tzInitialized = false;

  /// Initialize the timezone database and local location.
  /// Attempts to get the platform timezone via flutter_timezone if available.
  static Future<void> ensureInitialized() async {
    if (_tzInitialized) return;
    try {
      tzdata.initializeTimeZones();
    } catch (_) {
      // already initialized or not supported
    }

    // Best-effort: set the local location using platform timezone if the
    // flutter_timezone plugin is available at runtime. Wrap in try/catch so
    // that tests or platforms without the plugin do not fail.
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName.isNotEmpty) {
        final tz.Location location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
      }
    } catch (_) {
      // If we cannot detect the platform timezone, fall back to default tz.local
    }

    _tzInitialized = true;
  }

  /// Force-refresh local timezone from the platform and update tz.local.
  static Future<void> refreshLocalTimezone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      if (timeZoneName.isNotEmpty) {
        final tz.Location location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
      }
    } catch (_) {
      // ignore
    }
  }

  /// Core next-occurrence computation using tz-aware wall clock times.
  /// Returns a DateTime in the device local timezone matching the next alarm time.
  static DateTime nextOccurrenceForAlarm(Alarm alarm, DateTime now) {
    final tz.TZDateTime nowTz = tz.TZDateTime.from(now, tz.local);

    tz.TZDateTime buildCandidate(tz.TZDateTime baseDay) {
      // Constructing TZDateTime with a nonexistent wall time (spring-forward)
      // will roll forward to the next valid instant, which is the most
      // practical behavior for alarms.
      return tz.TZDateTime(
        tz.local,
        baseDay.year,
        baseDay.month,
        baseDay.day,
        alarm.timeOfDay.hour,
        alarm.timeOfDay.minute,
      );
    }

    bool isWeekday(int weekday) => weekday >= DateTime.monday && weekday <= DateTime.friday;
    bool isWeekend(int weekday) => weekday == DateTime.saturday || weekday == DateTime.sunday;

    tz.TZDateTime candidate = buildCandidate(nowTz);

    tz.TZDateTime advanceOneDay(tz.TZDateTime d) => tz.TZDateTime(tz.local, d.year, d.month, d.day + 1, d.hour, d.minute);

    switch (alarm.repeat) {
      case AlarmRepeat.once:
        if (candidate.isAfter(nowTz)) return candidate.toLocal();
        return buildCandidate(advanceOneDay(nowTz)).toLocal();
      case AlarmRepeat.daily:
        if (candidate.isAfter(nowTz)) return candidate.toLocal();
        return buildCandidate(advanceOneDay(nowTz)).toLocal();
      case AlarmRepeat.weekdays:
        tz.TZDateTime day = candidate.isAfter(nowTz) ? candidate : buildCandidate(advanceOneDay(nowTz));
        while (!isWeekday(day.weekday)) {
          final tz.TZDateTime nextDayBase = tz.TZDateTime(tz.local, day.year, day.month, day.day + 1);
          day = buildCandidate(nextDayBase);
        }
        return day.toLocal();
      case AlarmRepeat.weekends:
        tz.TZDateTime day = candidate.isAfter(nowTz) ? candidate : buildCandidate(advanceOneDay(nowTz));
        while (!isWeekend(day.weekday)) {
          final tz.TZDateTime nextDayBase = tz.TZDateTime(tz.local, day.year, day.month, day.day + 1);
          day = buildCandidate(nextDayBase);
        }
        return day.toLocal();
    }
  }
}
