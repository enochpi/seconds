import 'package:flutter_test/flutter_test.dart';
import 'package:seconds/utils/scoring_utils.dart';

void main() {
  group('ScoringUtils Tests', () {
    test('calculateScore should return maximum score for perfect timing', () {
      int score = ScoringUtils.calculateScore(0); // Perfect timing
      expect(score, equals(1000));
    });

    test('calculateScore should decrease with larger differences', () {
      int score1 = ScoringUtils.calculateScore(100); // 100ms off
      int score2 = ScoringUtils.calculateScore(500); // 500ms off

      expect(score1, equals(900));
      expect(score2, equals(500));
      expect(score1, greaterThan(score2));
    });

    test('calculateScore should never return negative scores', () {
      int score = ScoringUtils.calculateScore(2000); // Very far off
      expect(score, equals(0));
    });

    test('calculateScore should handle negative differences', () {
      int score1 = ScoringUtils.calculateScore(-100); // 100ms early
      int score2 = ScoringUtils.calculateScore(100);  // 100ms late

      expect(score1, equals(score2)); // Should be same for same magnitude
    });

    test('calculateTotalScore should sum all scores correctly', () {
      List<int> scores = [900, 800, 700, 600];
      int total = ScoringUtils.calculateTotalScore(scores);
      expect(total, equals(3000));
    });

    test('calculateTotalScore should handle empty list', () {
      List<int> scores = [];
      int total = ScoringUtils.calculateTotalScore(scores);
      expect(total, equals(0));
    });
  });
}

