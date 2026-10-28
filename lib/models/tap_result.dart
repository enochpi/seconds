import '../utils/constants.dart';

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
    if (difference == 0) {
      return "Perfect!";
    }

    final sign = difference > 0 ? "+" : "";
    return "$sign${difference}ms";
  }

  bool get isPerfect => difference.abs() <= 10;

  /// Exactly 7.000s (0ms off). Pays a jackpot.
  bool get isBullseye => difference == 0;

  /// Just outside perfect: close enough to hurt.
  bool get isNearMiss =>
      difference.abs() > 10 && difference.abs() <= GameConstants.nearMissMaxMs;

  bool get isAccurate => difference.abs() < 100;

  bool get isOkay => difference.abs() < 300;

  String get feedbackLabel {
    final absDiff = difference.abs();

    if (absDiff <= 10) {
      return "PERFECT";
    }

    if (absDiff < 100) {
      return "GREAT";
    }

    if (absDiff < 300) {
      return difference < 0 ? "EARLY" : "LATE";
    }

    return difference < 0 ? "TOO EARLY" : "TOO LATE";
  }

  String get feedbackEmoji {
    final absDiff = difference.abs();

    if (absDiff <= 10) {
      return "🎯";
    }

    if (absDiff < 100) {
      return "⚡";
    }

    if (absDiff < 300) {
      return "⏱️";
    }

    return "💥";
  }

  String get feedbackText {
    return "$feedbackEmoji $feedbackLabel +$score";
  }
}
