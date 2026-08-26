import 'dart:async';

import '../models/achievement.dart';
import '../models/leaderboard_entry.dart';
import '../models/tap_result.dart';
import '../utils/constants.dart';
import '../utils/scoring_utils.dart';
import 'storage_service.dart';
import 'timer_service.dart';

enum GameState {
  ready,
  countdown,
  playing,
  ended,
}

class GameService {
  final TimerService _timerService = TimerService();

  GameState _state = GameState.ready;

  GameMode _mode = GameMode.classic;

  List<int> _activeTargetTimes =
  GameConstants.getTargetTimes(GameMode.classic);

  int _currentTargetIndex = 0;

  final List<TapResult> _tapResults = [];

  int _totalScore = 0;

  int _countdownValue = GameConstants.countdownDuration;

  int _highScore = 0;

  int _gamesPlayed = 0;

  double _bestAccuracy = double.infinity;

  int _currentStreak = 0;

  int _bestRunStreak = 0;

  bool _isNewModePersonalBest = false;

  int _previousModePersonalBest = 0;

  GameService() {
    _loadSavedData();
  }

  GameState get state => _state;

  GameMode get mode => _mode;

  int get currentTargetIndex => _currentTargetIndex;

  List<TapResult> get tapResults => List.unmodifiable(_tapResults);

  int get totalScore => _totalScore;

  int get countdownValue => _countdownValue;

  int get highScore => _highScore;

  int get gamesPlayed => _gamesPlayed;

  double get bestAccuracy => _bestAccuracy;

  int get currentStreak => _currentStreak;

  int get bestRunStreak => _bestRunStreak;

  int get totalTargets => _activeTargetTimes.length;

  bool get isNewHighScore => _totalScore > _highScore && _totalScore > 0;

  bool get isNewModePersonalBest => _isNewModePersonalBest;

  int get previousModePersonalBest => _previousModePersonalBest;

  int get currentModePersonalBest {
    return StorageService.getModeBestScore(_mode);
  }

  int get pointsAwayFromModePersonalBest {
    final best = currentModePersonalBest;

    if (best <= 0) return 0;

    return (best - _totalScore).clamp(0, best);
  }

  bool get isBlindMode =>
      _mode == GameMode.blind ||
          _mode == GameMode.hardcore ||
          _mode == GameMode.daily;

  bool get isHardcoreMode => _mode == GameMode.hardcore;

  bool get isDailyChallengeMode => _mode == GameMode.daily;

  int get currentTargetNumber {
    if (_activeTargetTimes.isEmpty) return 0;

    final number = _currentTargetIndex + 1;

    if (number > _activeTargetTimes.length) {
      return _activeTargetTimes.length;
    }

    return number;
  }

  int get currentTargetTime {
    if (_activeTargetTimes.isEmpty) return 7000;

    if (_currentTargetIndex < _activeTargetTimes.length) {
      return _activeTargetTimes[_currentTargetIndex];
    }

    return _activeTargetTimes.last;
  }

  double get currentGameTime {
    return _timerService.elapsedMilliseconds / 1000.0;
  }

  String get currentGameTimeDisplay {
    return currentGameTime.toStringAsFixed(2);
  }

  double? get averageErrorMs {
    if (_tapResults.isEmpty) return null;

    return _tapResults
        .map((result) => result.difference.abs())
        .reduce((a, b) => a + b) /
        _tapResults.length;
  }

  int get dailyTargetTime => GameConstants.dailyTargetTime;

  String get dailyChallengeId => GameConstants.dailyChallengeId;

  int get todayDailyBestScore {
    return StorageService.getDailyChallengeBestScore(dailyChallengeId);
  }

  Function(GameState)? onStateChanged;

  Function(int)? onCountdownUpdate;

  Function(String)? onGameTimeUpdate;

  Function(TapResult)? onTapResult;

  Function()? onNewHighScore;

  void _loadSavedData() {
    _highScore = StorageService.getHighScore();
    _gamesPlayed = StorageService.getGamesPlayed();
    _bestAccuracy = StorageService.getBestAccuracy();
    _previousModePersonalBest = StorageService.getModeBestScore(_mode);
  }

  void setMode(GameMode mode) {
    if (_state != GameState.ready) return;

    _mode = mode;
    _activeTargetTimes = GameConstants.getTargetTimes(mode);
    _previousModePersonalBest = StorageService.getModeBestScore(mode);
    _isNewModePersonalBest = false;
  }

  String get reactionRank {
    if (_tapResults.isEmpty || _totalScore == 0) {
      return "🦥 Sleeping Sloth";
    }

    final averageError = averageErrorMs ?? 9999;

    final score = (7000 - (averageError * 12)).clamp(0, 7000).toInt();

    if (score < 5000) {
      return "🦥 Sleeping Sloth";
    }

    if (score < 6000) {
      return "🐢 Steady Turtle";
    }

    if (score < 6600) {
      return "🐍 Cobra Reflexes";
    }

    if (score >= 6975) {
      return "🏎️ F1 Champion";
    }

    if (score >= 6950) {
      return "⚡ Lightning Reflexes";
    }

    if (score >= 6925) {
      return "🎯 Esports Pro";
    }

    if (score >= 6900) {
      return "🥷 Shadow Ninja";
    }

    if (score >= 6875) {
      return "🦅 Peregrine Falcon";
    }

    if (score >= 6850) {
      return "🐆 Cheetah";
    }

    if (score >= 6800) {
      return "🦊 Fast Fox";
    }

    if (score >= 6750) {
      return "🐈 Alley Cat";
    }

    if (score >= 6700) {
      return "🐕 Playful Pup";
    }

    if (score >= 6600) {
      return "🐺 Rising Wolf";
    }

    return "🦥 Sleeping Sloth";
  }

  String get percentile {
    if (_tapResults.isEmpty || _totalScore == 0) {
      return "New Player";
    }

    final averageError = averageErrorMs ?? 9999;

    final score = (7000 - (averageError * 12)).clamp(0, 7000).toInt();

    if (score >= 6975) {
      return "Top 0.01%";
    }

    if (score >= 6950) {
      return "Top 0.05%";
    }

    if (score >= 6925) {
      return "Top 0.1%";
    }

    if (score >= 6900) {
      return "Top 0.5%";
    }

    if (score >= 6875) {
      return "Top 1%";
    }

    if (score >= 6850) {
      return "Top 3%";
    }

    if (score >= 6800) {
      return "Top 5%";
    }

    if (score >= 6750) {
      return "Top 10%";
    }

    if (score >= 6700) {
      return "Top 20%";
    }

    if (score >= 6600) {
      return "Top 30%";
    }

    if (score >= 6000) {
      return "Top 50%";
    }

    if (score >= 5000) {
      return "Top 75%";
    }

    return "Keep Practicing";
  }

  List<Achievement> get achievements {
    final unlockedIds = StorageService.getUnlockedAchievementIds();

    bool unlocked(String id) => unlockedIds.contains(id);

    final completedMainAchievements = [
      'first_attempt',
      'getting_started',
      'dedicated_player',
      'rhythm_addict',
      'cobra_reflexes',
      'shadow_ninja',
      'esports_pro',
      'lightning_reflexes',
      'f1_champion',
      'hardcore_legend',
      'daily_challenger',
      'daily_destroyer',
    ].every(unlocked);

    return [
      Achievement(
        id: 'first_attempt',
        title: "🎮 First Attempt",
        description: "Play 1 game",
        unlocked: unlocked('first_attempt') || _gamesPlayed >= 1,
      ),
      Achievement(
        id: 'getting_started',
        title: "🔥 Getting Started",
        description: "Play 25 games",
        unlocked: unlocked('getting_started') || _gamesPlayed >= 25,
      ),
      Achievement(
        id: 'dedicated_player',
        title: "⚡ Dedicated Player",
        description: "Play 100 games",
        unlocked: unlocked('dedicated_player') || _gamesPlayed >= 100,
      ),
      Achievement(
        id: 'rhythm_addict',
        title: "🧠 Rhythm Addict",
        description: "Play 1000 games",
        unlocked: unlocked('rhythm_addict') || _gamesPlayed >= 1000,
      ),
      Achievement(
        id: 'cobra_reflexes',
        title: "🐍 Cobra Reflexes",
        description: "Reach Cobra rank",
        unlocked: unlocked('cobra_reflexes'),
      ),
      Achievement(
        id: 'shadow_ninja',
        title: "🥷 Shadow Ninja",
        description: "Reach Shadow Ninja rank",
        unlocked: unlocked('shadow_ninja'),
      ),
      Achievement(
        id: 'esports_pro',
        title: "🎯 Esports Pro",
        description: "Reach Esports Pro rank",
        unlocked: unlocked('esports_pro'),
      ),
      Achievement(
        id: 'lightning_reflexes',
        title: "⚡ Lightning Reflexes",
        description: "Reach Lightning Reflexes",
        unlocked: unlocked('lightning_reflexes'),
      ),
      Achievement(
        id: 'f1_champion',
        title: "🏎️ F1 Champion",
        description: "Reach F1 Champion",
        unlocked: unlocked('f1_champion'),
      ),
      Achievement(
        id: 'hardcore_legend',
        title: "💀 Hardcore Legend",
        description: "Score 6900+ in Hardcore",
        unlocked: unlocked('hardcore_legend'),
      ),
      Achievement(
        id: 'daily_challenger',
        title: "📅 Daily Challenger",
        description: "Play the Daily Challenge",
        unlocked: unlocked('daily_challenger'),
      ),
      Achievement(
        id: 'daily_destroyer',
        title: "🌎 Daily Destroyer",
        description: "Score 6900+ in the Daily Challenge",
        unlocked: unlocked('daily_destroyer'),
      ),
      Achievement(
        id: 'reflex_master',
        title: "👑 Reflex Master",
        description: "Unlock every major achievement",
        unlocked: unlocked('reflex_master') || completedMainAchievements,
      ),
    ];
  }

  void startGame() {
    if (_state != GameState.ready) {
      resetToReady();
    }

    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    _resetGame();

    _state = GameState.countdown;
    _countdownValue = GameConstants.countdownDuration;

    onStateChanged?.call(_state);

    _startCountdown();
  }

  void _startCountdown() {
    onCountdownUpdate?.call(_countdownValue);

    _timerService.startPeriodicTimer(
      const Duration(seconds: 1),
          (timer) {
        _countdownValue--;

        if (_countdownValue > 0) {
          onCountdownUpdate?.call(_countdownValue);
        } else {
          _timerService.cancelTimer();
          _startMainGame();
        }
      },
    );
  }

  void _startMainGame() {
    _state = GameState.playing;

    onStateChanged?.call(_state);

    _timerService.startStopwatch();

    _timerService.startPeriodicTimer(
      Duration(milliseconds: GameConstants.updateInterval),
          (timer) {
        if (_state != GameState.playing) {
          return;
        }

        if (currentGameTime >= 20.0) {
          _endGame();
          return;
        }

        onGameTimeUpdate?.call(currentGameTimeDisplay);
      },
    );
  }

  void handleTap() {
    if (_state != GameState.playing) return;

    if (_currentTargetIndex >= _activeTargetTimes.length) return;

    final tapTime = _timerService.elapsedMilliseconds;
    final targetTime = _activeTargetTimes[_currentTargetIndex];
    final difference = tapTime - targetTime;

    int score;

    if (_mode == GameMode.hardcore || _mode == GameMode.daily) {
      score = (7000 - (difference.abs() * 7)).clamp(0, 7000).toInt();
    } else {
      score = ScoringUtils.calculateScore(difference);
    }

    final result = TapResult(
      targetTime: targetTime,
      actualTime: tapTime,
      difference: difference,
      score: score,
    );

    _tapResults.add(result);
    _totalScore += score;

    if (result.isAccurate) {
      _currentStreak++;

      if (_currentStreak > _bestRunStreak) {
        _bestRunStreak = _currentStreak;
      }
    } else {
      _currentStreak = 0;
    }

    _currentTargetIndex++;

    onTapResult?.call(result);

    if (_currentTargetIndex >= _activeTargetTimes.length) {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_state == GameState.ended) {
      return;
    }

    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    _state = GameState.ended;

    await _updateStatistics();

    onStateChanged?.call(_state);
  }

  Future<void> _updateStatistics() async {
    await StorageService.incrementGamesPlayed();

    _gamesPlayed = StorageService.getGamesPlayed();

    if (_totalScore > _highScore) {
      _highScore = _totalScore;

      await StorageService.setHighScore(_totalScore);

      onNewHighScore?.call();
    }

    _previousModePersonalBest = StorageService.getModeBestScore(_mode);
    _isNewModePersonalBest = _totalScore > _previousModePersonalBest;

    await StorageService.saveModeBestScore(
      mode: _mode,
      score: _totalScore,
    );

    if (_tapResults.isNotEmpty) {
      final averageAccuracy = averageErrorMs ?? double.infinity;

      if (averageAccuracy < _bestAccuracy) {
        _bestAccuracy = averageAccuracy;

        await StorageService.setBestAccuracy(averageAccuracy);
      }
    }

    await _savePersistentAchievements();
    await _saveLeaderboardEntry();

    if (_mode == GameMode.daily) {
      await StorageService.saveDailyChallengeScore(
        challengeId: dailyChallengeId,
        score: _totalScore,
      );
    }
  }

  Future<void> _saveLeaderboardEntry() async {
    if (_totalScore <= 0) return;

    await StorageService.addLeaderboardEntry(
      LeaderboardEntry(
        playerName: StorageService.getPlayerName(),
        score: _totalScore,
        rank: reactionRank,
        accuracyText: averageErrorMs == null
            ? "No accuracy"
            : "±${averageErrorMs!.toStringAsFixed(0)}ms",
        mode: _mode,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _savePersistentAchievements() async {
    final idsToUnlock = <String>[];

    if (_gamesPlayed >= 1) idsToUnlock.add('first_attempt');
    if (_gamesPlayed >= 25) idsToUnlock.add('getting_started');
    if (_gamesPlayed >= 100) idsToUnlock.add('dedicated_player');
    if (_gamesPlayed >= 1000) idsToUnlock.add('rhythm_addict');

    final rank = reactionRank;

    if (rank.contains("Cobra")) idsToUnlock.add('cobra_reflexes');
    if (rank.contains("Ninja")) idsToUnlock.add('shadow_ninja');
    if (rank.contains("Esports")) idsToUnlock.add('esports_pro');
    if (rank.contains("Lightning")) idsToUnlock.add('lightning_reflexes');
    if (rank.contains("F1")) idsToUnlock.add('f1_champion');

    if (_mode == GameMode.hardcore && _totalScore >= 6900) {
      idsToUnlock.add('hardcore_legend');
    }

    if (_mode == GameMode.daily && _totalScore > 0) {
      idsToUnlock.add('daily_challenger');
    }

    if (_mode == GameMode.daily && _totalScore >= 6900) {
      idsToUnlock.add('daily_destroyer');
    }

    await StorageService.unlockAchievements(idsToUnlock);

    final unlockedIds = StorageService.getUnlockedAchievementIds();

    final completedMainAchievements = [
      'first_attempt',
      'getting_started',
      'dedicated_player',
      'rhythm_addict',
      'cobra_reflexes',
      'shadow_ninja',
      'esports_pro',
      'lightning_reflexes',
      'f1_champion',
      'hardcore_legend',
      'daily_challenger',
      'daily_destroyer',
    ].every(unlockedIds.contains);

    if (completedMainAchievements) {
      await StorageService.unlockAchievement('reflex_master');
    }
  }

  void _resetGame() {
    _timerService.dispose();

    _currentTargetIndex = 0;
    _tapResults.clear();

    _totalScore = 0;
    _currentStreak = 0;
    _bestRunStreak = 0;

    _isNewModePersonalBest = false;
    _previousModePersonalBest = StorageService.getModeBestScore(_mode);

    _activeTargetTimes = GameConstants.getTargetTimes(_mode);

    _countdownValue = GameConstants.countdownDuration;
  }

  void resetToReady() {
    _timerService.cancelTimer();
    _timerService.stopStopwatch();

    _resetGame();

    _state = GameState.ready;

    onStateChanged?.call(_state);
  }

  Future<void> clearAllData() async {
    await StorageService.clearAllData();

    _highScore = 0;
    _gamesPlayed = 0;
    _bestAccuracy = double.infinity;
    _totalScore = 0;
    _currentStreak = 0;
    _bestRunStreak = 0;
    _isNewModePersonalBest = false;
    _previousModePersonalBest = 0;

    _tapResults.clear();

    onStateChanged?.call(_state);
  }

  void dispose() {
    _timerService.dispose();
  }
}