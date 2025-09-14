import '../models/challenge.dart';

class ChallengeValidatorService {
  /// Returns true if [input] satisfies the challenge.
  bool validate(Challenge challenge, String input) {
    switch (challenge.type) {
      case ChallengeType.math:
        return _validateMath(challenge, input);
      case ChallengeType.english:
        return _validateEnglish(challenge, input);
    }
  }

  bool _validateMath(Challenge challenge, String input) {
    final normalized = input.trim();
    final answers = challenge.answer ?? const <String>[];
    return answers.any((a) => a.trim() == normalized);
  }

  bool _validateEnglish(Challenge challenge, String input) {
    // For english tasks, payload holds a quoted prompt like: "Type the word: sunrise"
    // We accept the substring after the colon, lowercased and trimmed as the expected content
    final payload = challenge.payload.replaceAll('"', '');
    final idx = payload.indexOf(':');
    if (idx == -1) return false;
    final expected = payload.substring(idx + 1).trim();
    return input.trim() == expected;
  }
}

