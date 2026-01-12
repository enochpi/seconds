import 'package:flutter_test/flutter_test.dart';
import 'package:seconds/models/tap_result.dart';

void main() {
  group('TapResult Tests', () {
    test('formattedDifference should format positive differences correctly', () {
      TapResult result = TapResult(
        targetTime: 1000,
        actualTime: 1150,
        difference: 150,
        score: 850,
      );

      expect(result.formattedDifference, equals('+150ms'));
    });

    test('formattedDifference should format negative differences correctly', () {
      TapResult result = TapResult(
        targetTime: 1000,
        actualTime: 850,
        difference: -150,
        score: 850,
      );

      expect(result.formattedDifference, equals('-150ms'));
    });

    test('isAccurate should return true for differences under 100ms', () {
      TapResult result = TapResult(
        targetTime: 1000,
        actualTime: 1050,
        difference: 50,
        score: 950,
      );

      expect(result.isAccurate, isTrue);
    });

    test('isOkay should return true for differences under 300ms', () {
      TapResult result = TapResult(
        targetTime: 1000,
        actualTime: 1200,
        difference: 200,
        score: 800,
      );

      expect(result.isOkay, isTrue);
      expect(result.isAccurate, isFalse);
    });
  });
}
