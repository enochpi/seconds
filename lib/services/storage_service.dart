import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';

class StorageService {
  static const String _highScoreKey = 'high_score';
  static const String _gamesPlayedKey = 'games_played';
  static const String _bestAccuracyKey = 'best_accuracy';
  static const String _exactModeUnlockedKey = 'exact_mode_unlocked';
  static const String _exactModeHighLevelKey = 'exact_mode_high_level';
  static const String _exactModeGamesPlayedKey = 'exact_mode_games_played';

  static SharedPreferences? _prefs;

  // Initialize the service
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print('Error initializing StorageService: $e');
      // Continue without storage - app will work but won't save data
    }
  }

  // Free Mode methods with error handling
  static int getHighScore() {
    try {
      return _prefs?.getInt(_highScoreKey) ?? 0;
    } catch (e) {
      print('Error getting high score: $e');
      return 0;
    }
  }

  static Future<bool> setHighScore(int score) async {
    try {
      return await _prefs?.setInt(_highScoreKey, score) ?? false;
    } catch (e) {
      print('Error setting high score: $e');
      return false;
    }
  }

  static int getGamesPlayed() {
    try {
      return _prefs?.getInt(_gamesPlayedKey) ?? 0;
    } catch (e) {
      print('Error getting games played: $e');
      return 0;
    }
  }

  static Future<bool> incrementGamesPlayed() async {
    try {
      int current = getGamesPlayed();
      return await _prefs?.setInt(_gamesPlayedKey, current + 1) ?? false;
    } catch (e) {
      print('Error incrementing games played: $e');
      return false;
    }
  }

  static double getBestAccuracy() {
    try {
      return _prefs?.getDouble(_bestAccuracyKey) ?? double.infinity;
    } catch (e) {
      print('Error getting best accuracy: $e');
      return double.infinity;
    }
  }

  static Future<bool> setBestAccuracy(double accuracy) async {
    try {
      return await _prefs?.setDouble(_bestAccuracyKey, accuracy) ?? false;
    } catch (e) {
      print('Error setting best accuracy: $e');
      return false;
    }
  }

  // Exact Mode methods with error handling
  static bool isExactModeUnlocked() {
    try {
      return _prefs?.getBool(_exactModeUnlockedKey) ?? false;
    } catch (e) {
      print('Error checking exact mode unlock: $e');
      return false;
    }
  }

  static Future<bool> unlockExactMode() async {
    try {
      return await _prefs?.setBool(_exactModeUnlockedKey, true) ?? false;
    } catch (e) {
      print('Error unlocking exact mode: $e');
      return false;
    }
  }

  static int getExactModeHighLevel() {
    try {
      return _prefs?.getInt(_exactModeHighLevelKey) ?? 0;
    } catch (e) {
      print('Error getting exact mode high level: $e');
      return 0;
    }
  }

  static Future<bool> setExactModeHighLevel(int level) async {
    try {
      return await _prefs?.setInt(_exactModeHighLevelKey, level) ?? false;
    } catch (e) {
      print('Error setting exact mode high level: $e');
      return false;
    }
  }

  static int getExactModeGamesPlayed() {
    try {
      return _prefs?.getInt(_exactModeGamesPlayedKey) ?? 0;
    } catch (e) {
      print('Error getting exact mode games played: $e');
      return 0;
    }
  }

  static Future<bool> incrementExactModeGamesPlayed() async {
    try {
      int current = getExactModeGamesPlayed();
      return await _prefs?.setInt(_exactModeGamesPlayedKey, current + 1) ?? false;
    } catch (e) {
      print('Error incrementing exact mode games played: $e');
      return false;
    }
  }

  // Clear all data with error handling
  static Future<bool> clearAllData() async {
    try {
      bool score = await _prefs?.remove(_highScoreKey) ?? false;
      bool games = await _prefs?.remove(_gamesPlayedKey) ?? false;
      bool accuracy = await _prefs?.remove(_bestAccuracyKey) ?? false;
      bool exactUnlocked = await _prefs?.remove(_exactModeUnlockedKey) ?? false;
      bool exactLevel = await _prefs?.remove(_exactModeHighLevelKey) ?? false;
      bool exactGames = await _prefs?.remove(_exactModeGamesPlayedKey) ?? false;
      return score && games && accuracy && exactUnlocked && exactLevel && exactGames;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }

  // NEW: Check if storage is working
  static bool get isStorageAvailable => _prefs != null;

  // NEW: Get storage status for debugging
  static String get storageStatus {
    if (_prefs == null) {
      return 'Storage unavailable - data will not persist';
    } else {
      return 'Storage working normally';
    }
  }
}