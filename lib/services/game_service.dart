import 'dart:async';
import '../models/tap_result.dart';
import '../utils/constants.dart';
import '../utils/scoring_utils.dart';
import 'timer_service.dart';
import 'storage_service.dart';

enum GameState { ready, countdown, playing, ended }

class GameService {
  final TimerService _timerService = TimerService();

  GameState _state = GameState.ready;
  int _currentTargetIndex = 0;
  List<TapResult> _tapResults = [];
  int _totalScore = 0;
  int _countdownValue = GameConstants.countdownDuration;
  int _highScore = 0;
  int _gamesPlayed = 0;
  double _bestAccuracy = double.infinity;

  // Getters
  GameState get state => _state;
  int get currentTargetIndex => _currentTargetIndex;
  List<TapResult> get tapResults => List.unmodifiable(_tapResults);
  int get totalScore => _totalScore;
  int get countdownValue => _countdownValue;
  int get currentTargetTime => _currentTargetIndex < GameConstants.targetTimes.length
      ? GameConstants.targetTimes[_currentTargetIndex]
      : GameConstants.targetTimes.last; // ADDED: Safe fallback to last target

  // Updated to show 2 decimal places
  double get currentGameTime => _timerService.elapsedMilliseconds / 1000.0;
  String get currentGameTimeDisplay => currentGameTime.toStringAsFixed(2);

  // High score getters
  int get highScore => _highScore;
  int get gamesPlayed => _gamesPlayed;
  double get bestAccuracy => _bestAccuracy;
  bool get isNewHighScore => _totalScore > _highScore && _totalScore > 0;

  // Callbacks
  Function(GameState)? onStateChanged;
  Function(int)? onCountdownUpdate;
  Function(String)? onGameTimeUpdate; // Changed to String for 2-decimal display
  Function(TapResult)? onTapResult;
  Function()? onNewHighScore;
  Function()? onExactModeUnlocked;

  // Constructor - load saved data
  GameService() {
    _loadSavedData();
  }

  void _loadSavedData() {
    _highScore = StorageService.getHighScore();
    _gamesPlayed = StorageService.getGamesPlayed();
    _bestAccuracy = StorageService.getBestAccuracy();
  }

  void startGame() {
    _resetGame();
    _state = GameState.countdown;
    _countdownValue = GameConstants.countdownDuration;
    onStateChanged?.call(_state);
    _startCountdown();
  }

  void _startCountdown() {
    // Show the initial countdown value immediately
    onCountdownUpdate?.call(_countdownValue);

    _timerService.startPeriodicTimer(Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (_countdownValue > 0) {
        onCountdownUpdate?.call(_countdownValue);
      } else {
        _timerService.cancelTimer();
        _startMainGame();
      }
    });
  }

  void _startMainGame() {
    _state = GameState.playing;
    onStateChanged?.call(_state);

    _timerService.startStopwatch();

    _timerService.startPeriodicTimer(
        Duration(milliseconds: GameConstants.updateInterval),
            (timer) {
          if (_state == GameState.playing) {
            // Check if over 20 seconds - reset if so
            if (currentGameTime >= 20.0) {
              resetToReady();
              return;
            }
            onGameTimeUpdate?.call(currentGameTimeDisplay);
          }
        }
    );
  }

  void handleTap() {
    if (_state != GameState.playing) return;

    // Check if we've already completed all targets
    if (_currentTargetIndex >= GameConstants.targetTimes.length) {
      return; // Don't process any more taps
    }

    int tapTime = _timerService.elapsedMilliseconds;
    int targetTime = GameConstants.targetTimes[_currentTargetIndex];
    int difference = tapTime - targetTime;
    int score = ScoringUtils.calculateScore(difference);

    TapResult result = TapResult(
      targetTime: targetTime,
      actualTime: tapTime,
      difference: difference,
      score: score,
    );

    _tapResults.add(result);
    _totalScore += score;
    _currentTargetIndex++;

    onTapResult?.call(result);

    if (_currentTargetIndex >= GameConstants.targetTimes.length) {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_state == GameState.ended) return; // ADDED: Prevent double execution

    _state = GameState.ended;
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    // Update statistics
    await _updateStatistics();

    onStateChanged?.call(_state);
  }

  Future<void> _updateStatistics() async {
    // Increment games played
    await StorageService.incrementGamesPlayed();
    _gamesPlayed = StorageService.getGamesPlayed();

    // Check for new high score
    if (_totalScore > _highScore) {
      _highScore = _totalScore;
      await StorageService.setHighScore(_totalScore);
      onNewHighScore?.call();
    }

    // Calculate and update best accuracy
    if (_tapResults.isNotEmpty) {
      double averageAccuracy = _tapResults
          .map((result) => result.difference.abs())
          .reduce((a, b) => a + b) / _tapResults.length;

      if (averageAccuracy < _bestAccuracy) {
        _bestAccuracy = averageAccuracy;
        await StorageService.setBestAccuracy(averageAccuracy);
      }
    }
  }

  void _resetGame() {
    _timerService.dispose();

    // ADDED: Ensure index is always within valid bounds
    _currentTargetIndex = 0;
    if (_currentTargetIndex < 0) _currentTargetIndex = 0;
    if (_currentTargetIndex >= GameConstants.targetTimes.length) {
      _currentTargetIndex = GameConstants.targetTimes.length - 1;
    }

    _tapResults.clear(); // ADDED: Prevents memory leak
    _totalScore = 0;
    _countdownValue = GameConstants.countdownDuration;
  }

  void resetToReady() {
    // ADDED: Cancel any active timers first
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    _resetGame();
    _state = GameState.ready;
    onStateChanged?.call(_state);
  }

  // Clear all saved data (for testing)
  Future<void> clearAllData() async {
    await StorageService.clearAllData();
    _loadSavedData();
  }

  void dispose() {
    _timerService.dispose();
  }
}