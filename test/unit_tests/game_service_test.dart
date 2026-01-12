import 'package:flutter_test/flutter_test.dart';
import 'package:seconds/services/game_service.dart';
import 'package:seconds/models/tap_result.dart';

void main() {
  group('GameService Tests', () {
    late GameService gameService;

    setUp(() {
      gameService = GameService();
    });

    tearDown(() {
      gameService.dispose();
    });

    test('initial state should be ready', () {
      expect(gameService.state, equals(GameState.ready));
      expect(gameService.currentTargetIndex, equals(0));
      expect(gameService.tapResults, isEmpty);
      expect(gameService.totalScore, equals(0));
    });

    test('startGame should change state to countdown', () {
      bool stateChanged = false;
      gameService.onStateChanged = (state) {
        if (state == GameState.countdown) {
          stateChanged = true;
        }
      };

      gameService.startGame();
      expect(gameService.state, equals(GameState.countdown));
      expect(stateChanged, isTrue);
    });

    test('resetToReady should reset all game data', () {
      // Start a game and add some fake data
      gameService.startGame();
      // Simulate some game progress (this is simplified)

      // Reset the game
      gameService.resetToReady();

      expect(gameService.state, equals(GameState.ready));
      expect(gameService.currentTargetIndex, equals(0));
      expect(gameService.tapResults, isEmpty);
      expect(gameService.totalScore, equals(0));
    });

    test('handleTap should not work when game is not playing', () {
      // Game is in ready state
      int initialResultsCount = gameService.tapResults.length;

      gameService.handleTap();

      // Should not add any results
      expect(gameService.tapResults.length, equals(initialResultsCount));
    });
  });
}
