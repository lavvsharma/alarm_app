import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/alarm.dart';
import '../models/challenge.dart';
import '../services/di.dart';
import '../services/audio_service.dart';
import '../services/challenge_validator.dart';

class ChallengeScreen extends StatefulWidget {
  final String alarmId;

  const ChallengeScreen({super.key, required this.alarmId});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final ChallengeValidatorService _validator = ChallengeValidatorService();
  Alarm? _alarm;
  Challenge? _challenge;
  String _input = '';
  bool _valid = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final alarm = await DI.hiveStorage.getAlarm(widget.alarmId);
    setState(() {
      _alarm = alarm;
      _challenge = alarm?.challenge ?? DI.challengeGenerator.generate(type: ChallengeType.math, difficulty: 'easy');
      _loading = false;
    });
    await DI.audio.initialize();
    await DI.audio.start(assetPath: alarm?.sound);
  }

  Future<void> _onInputChanged(String value) async {
    setState(() {
      _input = value;
      if (_challenge != null) {
        _valid = _validator.validate(_challenge!, value);
      }
    });
  }

  Future<void> _onDismiss() async {
    final Alarm? alarm = _alarm;
    await DI.audio.stop();
    if (alarm != null) {
      // Cancel any pending schedules for this alarm
      await DI.scheduler.cancelAlarm(alarm.id);
      // If one-time alarm, disable it
      if (alarm.repeat == AlarmRepeat.once) {
        alarm.enabled = false;
        alarm.updatedAt = DateTime.now();
        await DI.hiveStorage.upsertAlarm(alarm);
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _onSnooze() async {
    // Snooze 5 minutes by default
    final DateTime when = DateTime.now().add(const Duration(minutes: 5));
    final Alarm? alarm = _alarm;
    if (alarm != null) {
      // Keep audio playing during snooze period.
      await DI.scheduler.snoozeUntil(alarm.id, when);
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    // Do not stop audio on dispose. Audio stops only after successful dismiss.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final challenge = _challenge!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Wake up! Complete the challenge to stop the alarm.',
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Center(child: _buildChallenge(challenge)),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onSnooze,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                  child: const Text('Snooze 5 min'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _valid ? _onDismiss : null,
                  style: FilledButton.styleFrom(backgroundColor: _valid ? Colors.green : Colors.grey),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChallenge(Challenge challenge) {
    switch (challenge.type) {
      case ChallengeType.math:
        final Map<String, dynamic> data = jsonDecode(challenge.payload) as Map<String, dynamic>;
        final String op = data['op'] as String;
        final int a = data['a'] as int;
        final int b = data['b'] as int;
        return _PromptWithInput(
          prompt: 'Solve: $a $op $b = ? ',
          onChanged: _onInputChanged,
        );
      case ChallengeType.english:
        final String prompt = challenge.payload.replaceAll('"', '');
        return _PromptWithInput(
          prompt: prompt,
          onChanged: _onInputChanged,
        );
    }
  }
}

class _PromptWithInput extends StatelessWidget {
  final String prompt;
  final ValueChanged<String> onChanged;

  const _PromptWithInput({required this.prompt, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(prompt, style: const TextStyle(fontSize: 22, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              filled: true,
              fillColor: Color(0x22FFFFFF),
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              hintText: 'Type your answer',
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

