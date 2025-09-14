import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'storage/hive_storage.dart';

class PermissionsSnapshot {
  final bool notificationsGranted;
  final bool exactAlarmGranted;
  final bool batteryOptimizationIgnored;
  final bool microphoneGranted;

  const PermissionsSnapshot({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
    required this.batteryOptimizationIgnored,
    required this.microphoneGranted,
  });

  bool get allCriticalGranted {
    if (Platform.isAndroid) {
      return notificationsGranted && exactAlarmGranted;
    }
    return notificationsGranted;
  }
}

class PlatformPermissionsService {
  static const String _kOnboardingDone = 'onboarding_done';
  static const String _kPermNotifications = 'perm_notifications';
  static const String _kPermExactAlarm = 'perm_exact_alarm';
  static const String _kPermBatteryIgnore = 'perm_battery_ignore';
  static const String _kPermMicrophone = 'perm_microphone';

  final HiveStorageService _storage;

  PlatformPermissionsService({HiveStorageService? storage}) : _storage = storage ?? HiveStorageService();

  Future<bool> isOnboardingDone() async {
    return await _storage.getBoolSetting(_kOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone(bool value) async {
    await _storage.setBoolSetting(_kOnboardingDone, value);
  }

  Future<PermissionsSnapshot> currentSnapshot({bool persist = true}) async {
    final bool notifications = await _isNotificationGranted();
    final bool exactAlarm = await _isExactAlarmGranted();
    final bool batteryIgnored = await _isBatteryOptimizationIgnored();
    final bool mic = await _isMicrophoneGranted();

    if (persist) {
      await _storage.setBoolSetting(_kPermNotifications, notifications);
      await _storage.setBoolSetting(_kPermExactAlarm, exactAlarm);
      await _storage.setBoolSetting(_kPermBatteryIgnore, batteryIgnored);
      await _storage.setBoolSetting(_kPermMicrophone, mic);
    }

    return PermissionsSnapshot(
      notificationsGranted: notifications,
      exactAlarmGranted: exactAlarm,
      batteryOptimizationIgnored: batteryIgnored,
      microphoneGranted: mic,
    );
  }

  Future<bool> requestNotifications() async {
    final PermissionStatus status = await Permission.notification.request();
    final bool granted = status.isGranted;
    await _storage.setBoolSetting(_kPermNotifications, granted);
    return granted;
  }

  Future<bool> requestExactAlarm() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.scheduleExactAlarm.request();
      final bool granted = status.isGranted;
      await _storage.setBoolSetting(_kPermExactAlarm, granted);
      return granted;
    } catch (_) {
      return await _isExactAlarmGranted();
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final PermissionStatus status = await Permission.ignoreBatteryOptimizations.request();
      final bool ignored = status.isGranted;
      await _storage.setBoolSetting(_kPermBatteryIgnore, ignored);
      return ignored;
    } catch (_) {
      return await _isBatteryOptimizationIgnored();
    }
  }

  Future<bool> requestMicrophone() async {
    final PermissionStatus status = await Permission.microphone.request();
    final bool granted = status.isGranted;
    await _storage.setBoolSetting(_kPermMicrophone, granted);
    return granted;
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  Future<bool> _isNotificationGranted() async {
    try {
      final PermissionStatus status = await Permission.notification.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _isExactAlarmGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final PermissionStatus status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<bool> _isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final PermissionStatus status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isMicrophoneGranted() async {
    try {
      final PermissionStatus status = await Permission.microphone.status;
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }
}

