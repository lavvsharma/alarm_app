import 'dart:async';

import 'package:flutter/material.dart';

import '../services/di.dart';
import '../services/platform_permissions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PermissionsSnapshot? _snapshot;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final snap = await DI.permissions.currentSnapshot();
    setState(() => _snapshot = snap);
  }

  Future<void> _runTestAlarm() async {
    setState(() => _testing = true);
    final String id = 'test_alarm';
    final now = DateTime.now().add(const Duration(seconds: 10));
    try {
      await DI.scheduler.snoozeUntil(id, now);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test alarm scheduled in 10 seconds')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule test: $e')));
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  title: const Text('Test alarm'),
                  subtitle: const Text('Schedules an alarm to fire in 10 seconds'),
                  trailing: FilledButton(
                    onPressed: _testing ? null : _runTestAlarm,
                    child: const Text('Run'),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Notifications'),
                  subtitle: Text(snapshot.notificationsGranted ? 'Granted' : 'Not granted'),
                  trailing: FilledButton(
                    onPressed: () => DI.permissions.requestNotifications().then((_) => _refresh()),
                    child: const Text('Request'),
                  ),
                ),
                ListTile(
                  title: const Text('Exact alarms (Android)'),
                  subtitle: Text(snapshot.exactAlarmGranted ? 'Granted' : 'Not granted'),
                  trailing: FilledButton(
                    onPressed: () => DI.permissions.requestExactAlarm().then((_) => _refresh()),
                    child: const Text('Request'),
                  ),
                ),
                ListTile(
                  title: const Text('Ignore battery optimizations (Android)'),
                  subtitle: Text(snapshot.batteryOptimizationIgnored ? 'Whitelisted' : 'Not whitelisted'),
                  trailing: FilledButton(
                    onPressed: () => DI.permissions.requestIgnoreBatteryOptimizations().then((_) => _refresh()),
                    child: const Text('Open'),
                  ),
                ),
                ListTile(
                  title: const Text('Microphone'),
                  subtitle: Text(snapshot.microphoneGranted ? 'Granted' : 'Not granted'),
                  trailing: FilledButton(
                    onPressed: () => DI.permissions.requestMicrophone().then((_) => _refresh()),
                    child: const Text('Request'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => DI.permissions.openAppSettingsPage(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open system app settings'),
                ),
              ],
            ),
    );
  }
}

