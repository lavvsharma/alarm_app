import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../services/di.dart';
import '../routes.dart';
import '../widgets/alarm_tile.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  late Future<List<Alarm>> _alarmsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _alarmsFuture = DI.hiveStorage.getAlarms();
    setState(() {});
  }

  Future<void> _toggleEnabled(Alarm alarm, bool enabled) async {
    alarm.enabled = enabled;
    alarm.updatedAt = DateTime.now();
    await DI.hiveStorage.upsertAlarm(alarm);
    if (enabled) {
      await DI.scheduler.schedule(alarm);
    } else {
      await DI.scheduler.cancel(alarm.id);
    }
    _reload();
  }

  Future<void> _deleteAlarm(String id) async {
    await DI.scheduler.cancel(id);
    await DI.hiveStorage.deleteAlarm(id);
    _reload();
  }

  Future<void> _navigateToCreate() async {
    await Navigator.of(context).pushNamed(AppRoutes.alarmEdit);
    _reload();
  }

  Future<void> _navigateToEdit(Alarm alarm) async {
    await Navigator.of(context).pushNamed(AppRoutes.alarmEdit, arguments: alarm.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      body: FutureBuilder<List<Alarm>>(
        future: _alarmsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final alarms = snapshot.data!;
          if (alarms.isEmpty) {
            return const Center(child: Text('No alarms yet. Tap + to add.'));
          }
          return ListView.separated(
            itemCount: alarms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return AlarmTile(
                alarm: alarm,
                onToggle: (enabled) => _toggleEnabled(alarm, enabled),
                onTap: () => _navigateToEdit(alarm),
                onDelete: () => _deleteAlarm(alarm.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

