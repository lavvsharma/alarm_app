import 'package:flutter/material.dart';

import '../models/alarm.dart';

class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  String _repeatLabel(AlarmRepeat repeat) {
    switch (repeat) {
      case AlarmRepeat.once:
        return 'Once';
      case AlarmRepeat.daily:
        return 'Daily';
      case AlarmRepeat.weekdays:
        return 'Weekdays';
      case AlarmRepeat.weekends:
        return 'Weekends';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = '${alarm.timeOfDay.hour.toString().padLeft(2, '0')}:${alarm.timeOfDay.minute.toString().padLeft(2, '0')}';
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete alarm?'),
            content: Text('Delete "${alarm.label}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        return ok == true;
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        onTap: onTap,
        title: Text(time, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        subtitle: Text('${alarm.label} • ${_repeatLabel(alarm.repeat)}'),
        trailing: Switch(value: alarm.enabled, onChanged: onToggle),
      ),
    );
  }
}

