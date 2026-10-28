import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetics.dart';
import '../models/leaderboard_entry.dart';
import '../utils/constants.dart';
import 'season_service.dart';

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

  static const String _unlockedAchievementIdsKey = 'unlocked_achievement_ids';

  static const String _leaderboardEntriesKey = 'leaderboard_entries';

  static const String _dailyChallengeDateKey = 'daily_challenge_date';

  static const String _dailyChallengeBestScoreKey =
      'daily_challenge_best_score';

  static const String _ticksKey = 'ticks';
  static const String _unlockedModesKey = 'unlocked_modes';
  static const String _ownedPetIdsKey = 'owned_pet_ids';
  static const String _equippedPetIdKey = 'equipped_pet_id';

  static const String _ownedCosmeticIdsKey = 'owned_cosmetic_ids';
  static const String _equippedCosmeticPrefix = 'equipped_cosmetic_';

  static const String _freeMysteryBoxesKey = 'free_mystery_boxes';
  static const String _lastShareRewardDayKey = 'last_share_reward_day';

  static const String _seasonBestPrefix = 'season_best_';
  static const String _lastClaimedSeasonKey = 'last_claimed_season';

  static const String _winStreakKey = 'win_streak';
  static const String _streakShieldsKey = 'streak_shields';
  static const String _questStateKey = 'quest_state';

  static const String _lifetimeTicksKey = 'lifetime_ticks_earned';
  static const String _lifetimePerfectTapsKey = 'lifetime_perfect_taps';
  static const String _bestWinStreakKey = 'best_win_streak';
  static const String _avatarPhotoPathKey = 'avatar_photo_path';

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

  // TICKS (CURRENCY)

  static int getTicks() {
    try {
      return _prefs?.getInt(_ticksKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> addTicks(int amount) async {
    try {
      await _prefs?.setInt(
        _lifetimeTicksKey,
        getLifetimeTicksEarned() + amount,
      );
      return await _prefs?.setInt(_ticksKey, getTicks() + amount) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Returns false (and spends nothing) if the balance is too low.
  static Future<bool> spendTicks(int amount) async {
    final balance = getTicks();

    if (balance < amount) return false;

    try {
      return await _prefs?.setInt(_ticksKey, balance - amount) ?? false;
    } catch (e) {
      return false;
    }
  }

  // SHOP UNLOCKS

  static bool isModeUnlocked(GameMode mode) {
    if (GameConstants.modeUnlockCost(mode) == 0) return true;

    // Players who already have a score in this mode from before modes
    // were locked keep access.
    if (getModeBestScore(mode) > 0) return true;

    try {
      final unlocked = _prefs?.getStringList(_unlockedModesKey) ?? [];
      return unlocked.contains(mode.name);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unlockMode(GameMode mode) async {
    try {
      final unlocked = _prefs?.getStringList(_unlockedModesKey) ?? [];
      if (unlocked.contains(mode.name)) return true;

      return await _prefs?.setStringList(
            _unlockedModesKey,
            [...unlocked, mode.name],
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static List<String> getOwnedPetIds() {
    try {
      return _prefs?.getStringList(_ownedPetIdsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addOwnedPet(String petId) async {
    try {
      final owned = getOwnedPetIds();
      if (owned.contains(petId)) return true;

      return await _prefs?.setStringList(_ownedPetIdsKey, [...owned, petId]) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static String? getEquippedPetId() {
    try {
      return _prefs?.getString(_equippedPetIdKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setEquippedPetId(String petId) async {
    try {
      return await _prefs?.setString(_equippedPetIdKey, petId) ?? false;
    } catch (e) {
      return false;
    }
  }

  static List<String> getOwnedCosmeticIds() {
    try {
      return _prefs?.getStringList(_ownedCosmeticIdsKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addOwnedCosmetic(String id) async {
    try {
      final owned = getOwnedCosmeticIds();
      if (owned.contains(id)) return true;

      return await _prefs
              ?.setStringList(_ownedCosmeticIdsKey, [...owned, id]) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static String? getEquippedCosmeticId(CosmeticType type) {
    try {
      return _prefs?.getString('$_equippedCosmeticPrefix${type.name}');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setEquippedCosmeticId(
      CosmeticType type, String id) async {
    try {
      return await _prefs?.setString(
            '$_equippedCosmeticPrefix${type.name}',
            id,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  // MYSTERY BOXES

  static int getFreeMysteryBoxes() {
    try {
      return _prefs?.getInt(_freeMysteryBoxesKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> setFreeMysteryBoxes(int count) async {
    try {
      return await _prefs?.setInt(_freeMysteryBoxesKey, count) ?? false;
    } catch (e) {
      return false;
    }
  }

  static String? getLastShareRewardDay() {
    try {
      return _prefs?.getString(_lastShareRewardDayKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setLastShareRewardDay(String day) async {
    try {
      return await _prefs?.setString(_lastShareRewardDayKey, day) ?? false;
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

  // ENDLESS SEASONS

  static int getSeasonBest(int seasonIndex) {
    try {
      return _prefs?.getInt('$_seasonBestPrefix$seasonIndex') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> saveSeasonBest(int seasonIndex, int rounds) async {
    try {
      if (rounds <= getSeasonBest(seasonIndex)) return false;

      return await _prefs?.setInt('$_seasonBestPrefix$seasonIndex', rounds) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static int getLastClaimedSeason() {
    try {
      return _prefs?.getInt(_lastClaimedSeasonKey) ?? -1;
    } catch (e) {
      return -1;
    }
  }

  static Future<bool> setLastClaimedSeason(int seasonIndex) async {
    try {
      return await _prefs?.setInt(_lastClaimedSeasonKey, seasonIndex) ?? false;
    } catch (e) {
      return false;
    }
  }

  // WIN STREAK

  static int getWinStreak() {
    try {
      return _prefs?.getInt(_winStreakKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> setWinStreak(int streak) async {
    try {
      return await _prefs?.setInt(_winStreakKey, streak) ?? false;
    } catch (e) {
      return false;
    }
  }

  static int getStreakShields() {
    try {
      return _prefs?.getInt(_streakShieldsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> setStreakShields(int count) async {
    try {
      return await _prefs?.setInt(_streakShieldsKey, count) ?? false;
    } catch (e) {
      return false;
    }
  }

  // PROFILE STATS

  /// Every Tick ever earned, including ones already spent.
  static int getLifetimeTicksEarned() {
    try {
      // Players from before this was tracked start at their current balance.
      return _prefs?.getInt(_lifetimeTicksKey) ?? getTicks();
    } catch (e) {
      return 0;
    }
  }

  static int getLifetimePerfectTaps() {
    try {
      return _prefs?.getInt(_lifetimePerfectTapsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> addPerfectTaps(int count) async {
    try {
      return await _prefs?.setInt(
            _lifetimePerfectTapsKey,
            getLifetimePerfectTaps() + count,
          ) ??
          false;
    } catch (e) {
      return false;
    }
  }

  static int getBestWinStreak() {
    try {
      return _prefs?.getInt(_bestWinStreakKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> saveBestWinStreak(int streak) async {
    try {
      if (streak <= getBestWinStreak()) return false;

      return await _prefs?.setInt(_bestWinStreakKey, streak) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// The uploaded profile photo in the app's documents folder, or null if
  /// the player is using an emoji avatar.
  static String? getAvatarPhotoPath() {
    try {
      return _prefs?.getString(_avatarPhotoPathKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setAvatarPhotoPath(String? path) async {
    try {
      if (path == null) {
        return await _prefs?.remove(_avatarPhotoPathKey) ?? false;
      }

      return await _prefs?.setString(_avatarPhotoPathKey, path) ?? false;
    } catch (e) {
      return false;
    }
  }

  // DAILY QUESTS

  /// Raw JSON owned by QuestService.
  static String? getQuestState() {
    try {
      return _prefs?.getString(_questStateKey);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> setQuestState(String json) async {
    try {
      return await _prefs?.setString(_questStateKey, json) ?? false;
    } catch (e) {
      return false;
    }
  }

  // LOCAL LEADERBOARD

  static List<LeaderboardEntry> _getSavedLeaderboardEntries() {
    try {
      final rawEntries = _prefs?.getStringList(_leaderboardEntriesKey) ?? [];

      return rawEntries
          // Old Daily Challenge scores used a different scale; drop them.
          .where((raw) => !raw.contains('"mode":"daily"'))
          .map((raw) => LeaderboardEntry.fromJson(raw))
          .where((entry) => !entry.isBot)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static List<LeaderboardEntry> getLeaderboardEntries() {
    try {
      final season = SeasonService.currentSeasonIndex;

      // Endless only shows runs from the current season.
      final realEntries = _getSavedLeaderboardEntries()
          .where((entry) =>
              entry.mode != GameMode.endless ||
              SeasonService.isInSeason(entry.createdAt, season))
          .toList();
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

      // Keep the top 30 per mode, since Endless scores (rounds) are much
      // smaller than the other modes' points.
      final topEntries = [
        for (final mode in GameMode.values)
          ...entries.where((e) => e.mode == mode).take(30),
      ];

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

      // ENDLESS
      ...SeasonService.botsForSeason(SeasonService.currentSeasonIndex),
    ];
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

  static Future<bool> clearAllData() async {
    try {
      await _prefs?.remove(_highScoreKey);
      await _prefs?.remove(_gamesPlayedKey);
      await _prefs?.remove(_bestAccuracyKey);
      await _prefs?.remove(_unlockedAchievementIdsKey);
      await _prefs?.remove(_leaderboardEntriesKey);
      await _prefs?.remove(_dailyChallengeDateKey);
      await _prefs?.remove(_dailyChallengeBestScoreKey);
      await _prefs?.remove(_winStreakKey);

      for (final mode in GameMode.values) {
        await _prefs?.remove(_modeBestKey(mode));
      }

      // Keep player name, tutorial status, Ticks and shop purchases.
      return true;
    } catch (e) {
      return false;
    }
  }

  static bool get isStorageAvailable => _prefs != null;
}
