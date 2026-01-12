import 'dart:math';
import 'constants.dart';

class ScoringUtils {
  static int calculateScore(int difference) {
    return max(0, GameConstants.maxScore - difference.abs());
  }

  static int calculateTotalScore(List<int> scores) {
    return scores.fold(0, (sum, score) => sum + score);
  }
}