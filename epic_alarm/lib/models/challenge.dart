enum ChallengeType { math, english }

class Challenge {
  final ChallengeType type;
  final String payload;
  final List<String>? answer;
  final String difficulty;

  const Challenge({
    required this.type,
    required this.payload,
    required this.answer,
    required this.difficulty,
  });
}

