import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../services/di.dart';
import '../services/platform_permissions.dart';
import '../routes.dart';

class InitialPermissionsFlowScreen extends StatefulWidget {
  const InitialPermissionsFlowScreen({super.key});

  @override
  State<InitialPermissionsFlowScreen> createState() => _InitialPermissionsFlowScreenState();
}

class _InitialPermissionsFlowScreenState extends State<InitialPermissionsFlowScreen> {
  final PlatformPermissionsService _permissions = DI.permissions;
  PermissionsSnapshot? _snapshot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final snap = await _permissions.currentSnapshot();
    setState(() => _snapshot = snap);
  }

  Future<void> _requestNotifications() async {
    setState(() => _busy = true);
    await _permissions.requestNotifications();
    await _refresh();
    setState(() => _busy = false);
  }

  Future<void> _requestExactAlarm() async {
    setState(() => _busy = true);
    await _permissions.requestExactAlarm();
    await _refresh();
    setState(() => _busy = false);
  }

  Future<void> _requestBatteryIgnore() async {
    setState(() => _busy = true);
    await _permissions.requestIgnoreBatteryOptimizations();
    await _refresh();
    setState(() => _busy = false);
  }

  Future<void> _requestMicrophone() async {
    setState(() => _busy = true);
    await _permissions.requestMicrophone();
    await _refresh();
    setState(() => _busy = false);
  }

  Future<void> _finish() async {
    await _permissions.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions setup')),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(
                  title: 'Notifications',
                  granted: snapshot.notificationsGranted,
                  description: 'Needed to alert you when the alarm goes off.',
                  actionLabel: 'Enable notifications',
                  onAction: _requestNotifications,
                ),
                if (Platform.isAndroid)
                  _Section(
                    title: 'Exact alarms',
                    granted: snapshot.exactAlarmGranted,
                    description: 'Required so alarms ring at the exact time.',
                    actionLabel: 'Allow exact alarms',
                    onAction: _requestExactAlarm,
                  ),
                if (Platform.isAndroid)
                  _Section(
                    title: 'Battery optimizations',
                    granted: snapshot.batteryOptimizationIgnored,
                    description: 'Optional but recommended to ensure alarms are reliable.',
                    actionLabel: 'Whitelist the app',
                    onAction: _requestBatteryIgnore,
                  ),
                _Section(
                  title: 'Microphone',
                  granted: snapshot.microphoneGranted,
                  description: 'Needed for certain audio input challenges.',
                  actionLabel: 'Allow microphone',
                  onAction: _requestMicrophone,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: !_busy && snapshot.allCriticalGranted ? _finish : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
                if (!_busy && !snapshot.allCriticalGranted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'You can continue after granting the required permissions above. You can change these anytime in Settings.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final bool granted;
  final VoidCallback onAction;

  const _Section({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.granted,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                Icon(granted ? Icons.check_circle : Icons.error_outline, color: granted ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: granted ? null : onAction,
                  child: Text(actionLabel),
                ),
                const SizedBox(width: 12),
                Text(granted ? 'Granted' : 'Not granted', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

