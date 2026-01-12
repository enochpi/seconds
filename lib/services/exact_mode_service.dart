import 'dart:async';
import '../models/tap_result.dart';
import '../utils/constants.dart';
import '../utils/scoring_utils.dart';
import 'timer_service.dart';
import 'storage_service.dart';

enum ExactGameState { ready, countdown, playing, levelComplete, gameOver }

class ExactModeService {
  final TimerService _timerService = TimerService();

  ExactGameState _state = ExactGameState.ready;
  int _currentLevel = 1;
  int _currentSequenceIndex = 0;
  int _highLevel = 0;
  int _gamesPlayed = 0;
  int _countdownValue = GameConstants.countdownDuration;
  TapResult? _lastResult;

  // Getters
  ExactGameState get state => _state;
  int get currentLevel => _currentLevel;
  int get currentSequenceIndex => _currentSequenceIndex;
  int get highLevel => _highLevel;
  int get gamesPlayed => _gamesPlayed;
  int get countdownValue => _countdownValue;

  // Get current target based on sequence position
  int get currentTargetTime {
    if (_currentSequenceIndex < 0 || _currentSequenceIndex >= _currentLevel) {
      return GameConstants.exactModeTargets[0]; // Fallback
    }
    return GameConstants.exactModeTargets[_currentSequenceIndex];
  }

  double get currentGameTime => _timerService.elapsedMilliseconds / 1000;
  TapResult? get lastResult => _lastResult;

  String get currentTargetDisplay {
    int targetTime = currentTargetTime;
    return "${(targetTime / 1000).toStringAsFixed(2)}";
  }

  String get sequenceProgress => "${_currentSequenceIndex + 1}/${_currentLevel}";

  int get maxLevel => GameConstants.exactModeTargets.length;

  // UPDATED: Simplified callback structure - removed redundant onGameOver
  Function(ExactGameState)? onStateChanged;
  Function(int)? onCountdownUpdate;
  Function(double)? onGameTimeUpdate;
  Function(TapResult, bool)? onTapResult;
  Function(int)? onLevelComplete;
  Function(int, int)? onGameFailure; // Handles game failure with level and sequence info
  Function(int)? onNewHighLevel;
  Function(String)? onSequenceProgress;
  // REMOVED: Function()? onGameOver; - redundant with onGameFailure

  ExactModeService() {
    _loadSavedData();
  }

  void _loadSavedData() {
    _highLevel = StorageService.getExactModeHighLevel();
    _gamesPlayed = StorageService.getExactModeGamesPlayed();
  }

  void startGame() {
    _resetGame();
    _state = ExactGameState.countdown;
    _countdownValue = GameConstants.countdownDuration;
    onStateChanged?.call(_state);
    onSequenceProgress?.call(sequenceProgress);
    _startCountdown();
  }

  void _startCountdown() {
    onCountdownUpdate?.call(_countdownValue);

    _timerService.startPeriodicTimer(Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (_countdownValue > 0) {
        onCountdownUpdate?.call(_countdownValue);
      } else {
        _timerService.cancelTimer();
        _startLevel();
      }
    });
  }

  void _startLevel() {
    _state = ExactGameState.playing;
    onStateChanged?.call(_state);
    onSequenceProgress?.call(sequenceProgress);

    _timerService.startStopwatch();

    _timerService.startPeriodicTimer(
      Duration(milliseconds: GameConstants.updateInterval),
          (timer) {
        if (_state == ExactGameState.playing) {
          onGameTimeUpdate?.call(currentGameTime);
        }
      },
    );
  }

  void handleTap() {
    if (_state != ExactGameState.playing) return;

    int tapTime = _timerService.elapsedMilliseconds;
    int targetTime = currentTargetTime;
    int difference = tapTime - targetTime;
    bool isSuccess = difference.abs() <= GameConstants.exactModeToleranceMs;

    // Store current level info BEFORE any changes for failure dialog
    int currentLevelForDialog = _currentLevel;
    int currentSequenceForDialog = _currentSequenceIndex + 1;

    _lastResult = TapResult(
      targetTime: targetTime,
      actualTime: tapTime,
      difference: difference,
      score: isSuccess ? 100 : 0,
    );

    // FIXED: Properly stop and reset timer for next target
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    onTapResult?.call(_lastResult!, isSuccess);

    if (isSuccess) {
      _handleSuccessfulTap();
    } else {
      // Pass the correct level info to the failure handler
      _endGameWithFailure(currentLevelForDialog, currentSequenceForDialog);
    }
  }

  // Handle successful tap - either continue sequence or complete level
  void _handleSuccessfulTap() {
    // Check if we've completed the entire sequence for this level BEFORE incrementing
    if (_currentSequenceIndex + 1 >= _currentLevel) {
      // Level complete! Increment the sequence index to reflect completion
      _currentSequenceIndex++;
      _completeLevel();
    } else {
      // Still in the same level, move to next target
      _currentSequenceIndex++;
      // Update progress display immediately
      onSequenceProgress?.call(sequenceProgress);
      _continueToNextTarget();
    }
  }

  // FIXED: Properly reset timer state before starting next target
  void _continueToNextTarget() {
    // Ensure clean timer state before starting next target
    _timerService.dispose(); // This will clean up any existing timers/stopwatch

    // Start next target in sequence with fresh timer state
    _startLevel();
  }

  // FIXED: Complete current level without auto-advance
  Future<void> _completeLevel() async {
    // Save current level for the completion dialog
    int completedLevel = _currentLevel;

    if (_currentLevel > _highLevel && _currentLevel <= maxLevel) {
      _highLevel = _currentLevel;
      await StorageService.setExactModeHighLevel(_currentLevel);
      onNewHighLevel?.call(_currentLevel);
    }

    // Show level complete state and let dialog handle next steps
    _state = ExactGameState.levelComplete;
    onStateChanged?.call(_state);
    onLevelComplete?.call(completedLevel);

    // REMOVED: Auto-advance logic that was causing race conditions
    // The dialog's "Continue" button will call nextLevel() when user is ready

    // Only end game if we've reached max level
    if (_currentLevel >= maxLevel) {
      _endGame();
    }
  }

  // Remove the separate nextLevel method since we're handling it in _completeLevel
  void nextLevel() {
    // This method can still be called manually if needed
    if (_currentLevel < maxLevel) {
      _currentLevel++;
      _currentSequenceIndex = 0;
      onSequenceProgress?.call(sequenceProgress);
      _startLevel();
    } else {
      _endGame();
    }
  }

  Future<void> _endGameWithFailure(int failedLevel, int failedSequence) async {
    _state = ExactGameState.gameOver;
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    await StorageService.incrementExactModeGamesPlayed();
    _gamesPlayed = StorageService.getExactModeGamesPlayed();

    // UPDATED: Only call state change and failure callback - no redundant onGameOver
    onStateChanged?.call(_state);
    onGameFailure?.call(failedLevel, failedSequence);
  }

  Future<void> _endGame() async {
    _state = ExactGameState.gameOver;
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    await StorageService.incrementExactModeGamesPlayed();
    _gamesPlayed = StorageService.getExactModeGamesPlayed();

    // UPDATED: For natural game completion (all levels done), just use state change
    // No special callback needed since this is handled by max level check in UI
    onStateChanged?.call(_state);

    // REMOVED: onGameOver?.call(); - not needed, state change is sufficient
  }

  void _resetGame() {
    _timerService.dispose();

    _currentLevel = 1;
    _currentSequenceIndex = 0;
    if (_currentLevel < 1) _currentLevel = 1;
    if (_currentLevel > maxLevel) _currentLevel = maxLevel;

    _countdownValue = GameConstants.countdownDuration;
    _lastResult = null;
  }

  void resetToReady() {
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    _resetGame();
    _state = ExactGameState.ready;
    onStateChanged?.call(_state);
  }

  void dispose() {
    _timerService.dispose();
  }
}