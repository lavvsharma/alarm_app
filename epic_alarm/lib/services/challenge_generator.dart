import 'dart:math';

import '../models/challenge.dart';

class ChallengeGeneratorService {
  final Random _random;

  ChallengeGeneratorService({int? seed}) : _random = Random(seed);

  Challenge generate({
    required ChallengeType type,
    required String difficulty,
    int? seed,
  }) {
    final Random rng = seed != null ? Random(seed) : _random;
    switch (type) {
      case ChallengeType.math:
        return _generateMath(difficulty, rng);
      case ChallengeType.english:
        return _generateEnglish(difficulty, rng);
    }
  }

  Challenge _generateMath(String difficulty, Random rng) {
    final ops = ['+', '-', '×'];
    final op = ops[rng.nextInt(ops.length)];
    int maxVal;
    switch (difficulty) {
      case 'hard':
        maxVal = 99;
        break;
      case 'medium':
        maxVal = 50;
        break;
      default:
        maxVal = 20;
    }
    final a = rng.nextInt(maxVal) + 1;
    final b = rng.nextInt(maxVal) + 1;
    int result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      default:
        result = a * b;
    }
    final payload = '{"op":"$op","a":$a,"b":$b}';
    return Challenge(
      type: ChallengeType.math,
      payload: payload,
      answer: [result.toString()],
      difficulty: difficulty,
    );
  }

  Challenge _generateEnglish(String difficulty, Random rng) {
    final promptsEasy = [
      'Type the word: sunrise',
      'Type the word: river',
      'Type the word: garden',
    ];
    final promptsMedium = [
      'Type the sentence: The quick brown fox.',
      'Type the sentence: Morning coffee is great.',
      'Type the sentence: Reading books expands minds.',
    ];
    final promptsHard = [
      'Type the sentence: Sphinx of black quartz, judge my vow.',
      'Type the sentence: Pack my box with five dozen liquor jugs.',
      'Type the sentence: How vexingly quick daft zebras jump!',
    ];

    List<String> pool;
    switch (difficulty) {
      case 'hard':
        pool = promptsHard;
        break;
      case 'medium':
        pool = promptsMedium;
        break;
      default:
        pool = promptsEasy;
    }
    final prompt = pool[rng.nextInt(pool.length)];
    // For preview purposes, we do not force-check the answer; leave as null
    return Challenge(
      type: ChallengeType.english,
      payload: '"$prompt"',
      answer: null,
      difficulty: difficulty,
    );
  }
}

