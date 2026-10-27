

import 'package:shared_preferences/shared_preferences.dart';

import '../models/leaderboard_entry.dart';
import '../utils/constants.dart';

class StorageService {
  static const String _highScoreKey = 'high_score';
  static const String _gamesPlayedKey = 'games_played';
  static const String _bestAccuracyKey = 'best_accuracy';
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';

  static const String _soundEnabledKey = 'sound_enabled';
  static const String _hapticsEnabledKey = 'haptics_enabled';
  static const String _darkModeEnabledKey = 'dark_mode_enabled';

  static const String _playerNameKey = 'player_name';

  static const String _modeBestPrefix = 'mode_best_';

  static const String _unlockedAchievementIdsKey =
      'unlocked_achievement_ids';

  static const String _leaderboardEntriesKey =
      'leaderboard_entries';

  static const String _dailyChallengeDateKey =
      'daily_challenge_date';

  static const String _dailyChallengeBestScoreKey =
      'daily_challenge_best_score';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing StorageService: $e');
    }
  }

  // PLAYER NAME

  static String getPlayerName() {
    try {
      final name = _prefs?.getString(_playerNameKey);

      if (name == null || name.trim().isEmpty) {
        return 'Player';
      }

      return name.trim();
    } catch (e) {
      return 'Player';
    }
  }

  static Future<bool> setPlayerName(String name) async {
    try {
      final cleanName = name.trim().isEmpty ? 'Player' : name.trim();

      return await _prefs?.setString(_playerNameKey, cleanName) ?? false;
    } catch (e) {
      return false;
    }
  }

  // MODE PERSONAL BESTS

  static String _modeBestKey(GameMode mode) {
    return '$_modeBestPrefix${mode.name}';
  }

  static int getModeBestScore(GameMode mode) {
    try {
      return _prefs?.getInt(_modeBestKey(mode)) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> saveModeBestScore({
    required GameMode mode,
    required int score,
  }) async {
    try {
      final currentBest = getModeBestScore(mode);

      if (score <= currentBest) {
        return false;
      }

      return await _prefs?.setInt(_modeBestKey(mode), score) ?? false;
    } catch (e) {
      return false;
    }
  }

  // BASIC STATS

  static int getHighScore() {
    try {
      return _prefs?.getInt(_highScoreKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> setHighScore(int score) async {
    try {
      return await _prefs?.setInt(_highScoreKey, score) ?? false;
    } catch (e) {
      return false;
    }
  }

  static int getGamesPlayed() {
    try {
      return _prefs?.getInt(_gamesPlayedKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> incrementGamesPlayed() async {
    try {
      final current = getGamesPlayed();

      return await _prefs?.setInt(_gamesPlayedKey, current + 1) ?? false;
    } catch (e) {
      return false;
    }
  }

  static double getBestAccuracy() {
    try {
      return _prefs?.getDouble(_bestAccuracyKey) ?? double.infinity;
    } catch (e) {
      return double.infinity;
    }
  }

  static Future<bool> setBestAccuracy(double accuracy) async {
    try {
      return await _prefs?.setDouble(_bestAccuracyKey, accuracy) ?? false;
    } catch (e) {
      return false;
    }
  }

  static bool hasSeenTutorial() {
    try {
      return _prefs?.getBool(_hasSeenTutorialKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setTutorialSeen() async {
    try {
      return await _prefs?.setBool(_hasSeenTutorialKey, true) ?? false;
    } catch (e) {
      return false;
    }
  }

  // SETTINGS

  static bool getSoundEnabled() {
    try {
      return _prefs?.getBool(_soundEnabledKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> setSoundEnabled(bool enabled) async {
    try {
      return await _prefs?.setBool(_soundEnabledKey, enabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  static bool getHapticsEnabled() {
    try {
      return _prefs?.getBool(_hapticsEnabledKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> setHapticsEnabled(bool enabled) async {
    try {
      return await _prefs?.setBool(_hapticsEnabledKey, enabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  static bool getDarkModeEnabled() {
    try {
      return _prefs?.getBool(_darkModeEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setDarkModeEnabled(bool enabled) async {
    try {
      return await _prefs?.setBool(_darkModeEnabledKey, enabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ACHIEVEMENTS

  static List<String> getUnlockedAchievementIds() {
    try {
      return _prefs?.getStringList(_unlockedAchievementIdsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  static bool isAchievementUnlocked(String id) {
    return getUnlockedAchievementIds().contains(id);
  }

  static Future<bool> unlockAchievement(String id) async {
    try {
      final ids = getUnlockedAchievementIds();

      if (!ids.contains(id)) {
        ids.add(id);
      }

      return await _prefs?.setStringList(
        _unlockedAchievementIdsKey,
        ids,
      ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> unlockAchievements(List<String> idsToUnlock) async {
    try {
      final ids = getUnlockedAchievementIds();

      for (final id in idsToUnlock) {
        if (!ids.contains(id)) {
          ids.add(id);
        }
      }

      await _prefs?.setStringList(_unlockedAchievementIdsKey, ids);
    } catch (e) {
      print('Error unlocking achievements: $e');
    }
  }

  // DAILY CHALLENGE

  static int getDailyChallengeBestScore(String challengeId) {
    try {
      final savedDate = _prefs?.getString(_dailyChallengeDateKey);

      if (savedDate != challengeId) {
        return 0;
      }

      return _prefs?.getInt(_dailyChallengeBestScoreKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> saveDailyChallengeScore({
    required String challengeId,
    required int score,
  }) async {
    try {
      final currentBest = getDailyChallengeBestScore(challengeId);

      if (score <= currentBest) {
        return false;
      }

      await _prefs?.setString(_dailyChallengeDateKey, challengeId);

      return await _prefs?.setInt(
        _dailyChallengeBestScoreKey,
        score,
      ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  // LOCAL LEADERBOARD

  static List<LeaderboardEntry> _getSavedLeaderboardEntries() {
    try {
      final rawEntries =
          _prefs?.getStringList(_leaderboardEntriesKey) ?? [];

      return rawEntries
          .map((raw) => LeaderboardEntry.fromJson(raw))
          .where((entry) => !entry.isBot)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<LeaderboardEntry> getLeaderboardEntries() {
    try {
      final realEntries = _getSavedLeaderboardEntries();
      final botEntries = _getBotLeaderboardEntries();

      final allEntries = [
        ...realEntries,
        ...botEntries,
      ];

      allEntries.sort((a, b) => b.score.compareTo(a.score));

      return allEntries;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addLeaderboardEntry(
      LeaderboardEntry entry,
      ) async {
    try {
      final entries = _getSavedLeaderboardEntries();

      entries.add(
        LeaderboardEntry(
          playerName: entry.playerName,
          score: entry.score,
          rank: entry.rank,
          accuracyText: entry.accuracyText,
          mode: entry.mode,
          createdAt: entry.createdAt,
          isBot: false,
        ),
      );

      entries.sort((a, b) => b.score.compareTo(a.score));

      final topEntries = entries.take(30).toList();

      return await _prefs?.setStringList(
        _leaderboardEntriesKey,
        topEntries.map((entry) => entry.toJson()).toList(),
      ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearLeaderboard() async {
    try {
      return await _prefs?.remove(_leaderboardEntriesKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static List<LeaderboardEntry> _getBotLeaderboardEntries() {
    final now = DateTime.now();

    return [
      // CLASSIC
      _bot(
        name: 'Tapzilla',
        score: 6928,
        rank: '🎯 Esports Pro',
        accuracy: '±6ms',
        mode: GameMode.classic,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      _bot(
        name: 'PixelNinja',
        score: 6847,
        rank: '🐆 Cheetah',
        accuracy: '±13ms',
        mode: GameMode.classic,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      _bot(
        name: 'TurboTurtle',
        score: 6430,
        rank: '🐍 Cobra Reflexes',
        accuracy: '±48ms',
        mode: GameMode.classic,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      _bot(
        name: 'LateLarry',
        score: 5110,
        rank: '🐢 Steady Turtle',
        accuracy: '±158ms',
        mode: GameMode.classic,
        createdAt: now.subtract(const Duration(days: 5)),
      ),

      // BLIND
      _bot(
        name: 'RhythmGhost',
        score: 6765,
        rank: '🐈 Alley Cat',
        accuracy: '±20ms',
        mode: GameMode.blind,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      _bot(
        name: 'NoLookNora',
        score: 6412,
        rank: '🐍 Cobra Reflexes',
        accuracy: '±49ms',
        mode: GameMode.blind,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      _bot(
        name: 'BlindBeats',
        score: 5880,
        rank: '🐢 Steady Turtle',
        accuracy: '±93ms',
        mode: GameMode.blind,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      _bot(
        name: 'SleepySloth',
        score: 3975,
        rank: '🦥 Sleeping Sloth',
        accuracy: '±252ms',
        mode: GameMode.blind,
        createdAt: now.subtract(const Duration(days: 6)),
      ),

      // HARDCORE
      _bot(
        name: 'Almost7',
        score: 6965,
        rank: '⚡ Lightning Reflexes',
        accuracy: '5ms late',
        mode: GameMode.hardcore,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      _bot(
        name: 'SevenSensei',
        score: 6895,
        rank: '🦅 Peregrine Falcon',
        accuracy: '15ms early',
        mode: GameMode.hardcore,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      _bot(
        name: 'OneTapTom',
        score: 6510,
        rank: '🐍 Cobra Reflexes',
        accuracy: '70ms late',
        mode: GameMode.hardcore,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      _bot(
        name: 'PanicTap',
        score: 2940,
        rank: '🦥 Sleeping Sloth',
        accuracy: '580ms early',
        mode: GameMode.hardcore,
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // DAILY
      ..._getDailyBotEntries(),
    ];
  }

  static List<LeaderboardEntry> _getDailyBotEntries() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;

    final score1 = 6600 + ((seed * 17) % 320);
    final score2 = 6100 + ((seed * 23) % 430);
    final score3 = 5000 + ((seed * 31) % 700);
    final score4 = 3200 + ((seed * 43) % 1200);

    return [
      _dailyBot(
        name: 'DailyDemon',
        score: score1,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      _dailyBot(
        name: 'CalendarCat',
        score: score2,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      _dailyBot(
        name: 'TodayTapper',
        score: score3,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      _dailyBot(
        name: 'MissedByMiles',
        score: score4,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }

  static LeaderboardEntry _dailyBot({
    required String name,
    required int score,
    required DateTime createdAt,
  }) {
    final offByMs = ((7000 - score) / 7).round();

    return LeaderboardEntry(
      playerName: name,
      score: score,
      rank: _rankForScore(score),
      accuracyText: '${offByMs}ms off',
      mode: GameMode.daily,
      createdAt: createdAt,
      isBot: true,
    );
  }

  static LeaderboardEntry _bot({
    required String name,
    required int score,
    required String rank,
    required String accuracy,
    required GameMode mode,
    required DateTime createdAt,
  }) {
    return LeaderboardEntry(
      playerName: name,
      score: score,
      rank: rank,
      accuracyText: accuracy,
      mode: mode,
      createdAt: createdAt,
      isBot: true,
    );
  }

  static String _rankForScore(int score) {
    if (score >= 6975) return '🏎️ F1 Champion';
    if (score >= 6950) return '⚡ Lightning Reflexes';
    if (score >= 6925) return '🎯 Esports Pro';
    if (score >= 6900) return '🥷 Shadow Ninja';
    if (score >= 6875) return '🦅 Peregrine Falcon';
    if (score >= 6850) return '🐆 Cheetah';
    if (score >= 6800) return '🦊 Fast Fox';
    if (score >= 6750) return '🐈 Alley Cat';
    if (score >= 6600) return '🐺 Rising Wolf';
    if (score >= 6000) return '🐍 Cobra Reflexes';
    if (score >= 5000) return '🐢 Steady Turtle';

    return '🦥 Sleeping Sloth';
  }

  static Future<bool> clearAllData() async {
    try {
      await _prefs?.remove(_highScoreKey);
      await _prefs?.remove(_gamesPlayedKey);
      await _prefs?.remove(_bestAccuracyKey);
      await _prefs?.remove(_unlockedAchievementIdsKey);
      await _prefs?.remove(_leaderboardEntriesKey);
      await _prefs?.remove(_dailyChallengeDateKey);
      await _prefs?.remove(_dailyChallengeBestScoreKey);

      for (final mode in GameMode.values) {
        await _prefs?.remove(_modeBestKey(mode));
      }

      // Keep player name and tutorial status.
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool get isStorageAvailable => _prefs != null;
}