import 'package:flutter/material.dart';

enum GameMode {
  classic,
  blind,
  hardcore,
  daily,
}

class GameConstants {
  static const List<int> classicTargetTimes = [
    1000,
    2000,
    3000,
    4000,
    5000,
    6000,
    7000,
  ];

  static const List<int> hardcoreTargetTimes = [
    7000,
  ];

  // Keep this for old code compatibility.
  static const List<int> targetTimes = classicTargetTimes;

  static const int maxScore = 1000;
  static const int countdownDuration = 4;
  static const int updateInterval = 100;

  static const Color accurateColor = Colors.green;
  static const Color okayColor = Colors.orange;
  static const Color inaccurateColor = Colors.red;

  static List<int> getTargetTimes(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
      case GameMode.blind:
        return classicTargetTimes;

      case GameMode.hardcore:
        return hardcoreTargetTimes;

      case GameMode.daily:
        return [dailyTargetTime];
    }
  }

  static int get dailyTargetTime {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;

    // Daily target between 4.000s and 9.999s.
    return 4000 + ((seed * 37) % 6000);
  }

  static String get dailyChallengeId {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';
  }

  static String modeName(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return "Classic";
      case GameMode.blind:
        return "Blind";
      case GameMode.hardcore:
        return "Hardcore";
      case GameMode.daily:
        return "Daily";
    }
  }

  static String modeEmoji(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return "⚡";
      case GameMode.blind:
        return "🧠";
      case GameMode.hardcore:
        return "💀";
      case GameMode.daily:
        return "📅";
    }
  }

  static String modeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return "Tap every second from 1s to 7s.";
      case GameMode.blind:
        return "Same challenge, but without the timer.";
      case GameMode.hardcore:
        return "One hidden tap. Hit exactly 7.00s.";
      case GameMode.daily:
        return "One hidden target that changes every day.";
    }
  }
}