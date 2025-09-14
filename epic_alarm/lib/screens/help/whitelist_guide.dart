import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class WhitelistGuideScreen extends StatefulWidget {
  const WhitelistGuideScreen({super.key});

  @override
  State<WhitelistGuideScreen> createState() => _WhitelistGuideScreenState();
}

class _WhitelistGuideScreenState extends State<WhitelistGuideScreen> {
  String _oem = 'Unknown';

  @override
  void initState() {
    super.initState();
    _detectOem();
  }

  Future<void> _detectOem() async {
    if (!Platform.isAndroid) return;
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    final AndroidDeviceInfo info = await plugin.androidInfo;
    final String? manufacturer = info.manufacturer?.toLowerCase();
    final String? brand = info.brand?.toLowerCase();
    final String? model = info.model?.toLowerCase();
    final String guess = _classifyOem(manufacturer, brand, model);
    setState(() => _oem = guess);
  }

  String _classifyOem(String? manufacturer, String? brand, String? model) {
    final String blob = '${manufacturer ?? ''} ${brand ?? ''} ${model ?? ''}';
    if (blob.contains('xiaomi') || blob.contains('redmi') || blob.contains('mi')) return 'Xiaomi';
    if (blob.contains('oppo') || blob.contains('realme')) return 'Oppo/Realme';
    if (blob.contains('oneplus')) return 'OnePlus';
    if (blob.contains('huawei') || blob.contains('honor')) return 'Huawei/Honor';
    if (blob.contains('samsung')) return 'Samsung';
    if (blob.contains('vivo') || blob.contains('iqoo')) return 'Vivo/iQOO';
    return 'Android';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Whitelist Guide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Detected device: $_oem', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildGuideFor(_oem),
        ],
      ),
    );
  }

  Widget _buildGuideFor(String oem) {
    switch (oem) {
      case 'Xiaomi':
        return _Steps(title: 'Xiaomi / Redmi / POCO', steps: const [
          'Open Settings > Apps > Manage apps',
          'Find this app and tap it',
          'Auto-start: Enable',
          'Battery saver: No restrictions',
          'Notifications: Allow and set as priority',
        ]);
      case 'Oppo/Realme':
        return _Steps(title: 'Oppo / Realme', steps: const [
          'Settings > Battery',
          'App Battery Management',
          'Find this app and set to Allow background activity',
          'Lock the app in Recent Tasks to prevent killing',
        ]);
      case 'OnePlus':
        return _Steps(title: 'OnePlus', steps: const [
          'Settings > Battery > Battery optimization',
          'Set this app to Don’t optimize',
          'Settings > Apps > Special access > Auto-launch: Enable',
        ]);
      case 'Huawei/Honor':
        return _Steps(title: 'Huawei / Honor', steps: const [
          'Settings > Battery > App launch',
          'Disable Manage automatically',
          'Enable Auto-launch, Secondary launch, Run in background',
        ]);
      case 'Samsung':
        return _Steps(title: 'Samsung', steps: const [
          'Settings > Battery and device care > Battery',
          'Background usage limits: Remove this app from Sleeping apps',
          'Settings > Apps > this app > Battery: Unrestricted',
        ]);
      case 'Vivo/iQOO':
        return _Steps(title: 'Vivo / iQOO', steps: const [
          'i Manager > Power manager > Background power consumption management',
          'Allow this app',
          'Lock app in Recent Tasks',
        ]);
      default:
        return _Steps(title: 'General Android', steps: const [
          'Settings > Apps > this app > Battery',
          'Set to Unrestricted/Allow background activity',
          'Settings > Apps > Special access > Ignore battery optimizations: Allow for this app',
          'Ensure Notifications are allowed',
        ]);
    }
  }
}

class _Steps extends StatelessWidget {
  final String title;
  final List<String> steps;

  const _Steps({required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${i + 1}. '),
                Expanded(child: Text(steps[i])),
              ],
            ),
          ),
      ],
    );
  }
}

