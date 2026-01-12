class TapResult {
  final int targetTime;
  final int actualTime;
  final int difference;
  final int score;

  TapResult({
    required this.targetTime,
    required this.actualTime,
    required this.difference,
    required this.score,
  });

  String get formattedDifference {
    return difference >= 0 ? "+${difference}ms" : "${difference}ms";
  }

  bool get isAccurate => difference.abs() < 100;
  bool get isOkay => difference.abs() < 300;
}