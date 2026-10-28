import 'dart:math';

import 'package:flutter/material.dart';

enum GameMode {
  classic,
  blind,
  hardcore,
  endless,
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
  static const int countdownDuration = 3;
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
      case GameMode.endless:
        return hardcoreTargetTimes;
    }
  }

  // ENDLESS MODE
  // Every round is a hidden tap at 7.00s. Clearing a round shrinks the
  // allowed window by 15%, and later rounds pay more Ticks.

  static const int endlessTargetMs = 7000;
  static const int endlessStartMarginMs = 500;
  static const int endlessMinMarginMs = 30;
  static const double endlessMarginShrink = 0.85;

  /// Cost of the 1st, 2nd and 3rd continue in one run.
  static const List<int> endlessContinueCosts = [25, 50, 100];

  static int endlessMarginMs(int round) {
    final margin =
        endlessStartMarginMs * pow(endlessMarginShrink, round - 1).toDouble();

    return max(endlessMinMarginMs, margin.round());
  }

  static int endlessRoundTicks(int round) => round;

  /// Extra Ticks for clearing milestone rounds (5, 10, 15, 20, then every 5).
  static int endlessMilestoneBonus(int round) {
    if (round % 5 != 0) return 0;

    switch (round) {
      case 5:
        return 10;
      case 10:
        return 30;
      case 15:
        return 60;
      default:
        return 120;
    }
  }

  static String modeName(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return "Classic";
      case GameMode.blind:
        return "Blind";
      case GameMode.hardcore:
        return "Hardcore";
      case GameMode.endless:
        return "Endless";
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
      case GameMode.endless:
        return "♾️";
    }
  }

  /// Ticks per Classic-style run = base + per star, before multipliers.
  static const int baseRunTicks = 2;
  static const int ticksPerStar = 3;

  /// Taps this close (but not perfect) get the "SO CLOSE" treatment. In
  /// Endless it's how far outside the window a miss landed.
  static const int nearMissMaxMs = 30;

  /// Extra Ticks for each tap within 10ms of the target (non-Endless modes).
  static const int perfectTapBonusTicks = 3;

  /// Jackpot for a tap at exactly 7.000s (0ms off), in any mode, on top of
  /// the perfect tap bonus.
  static const int bullseyeBonusTicks = 25;

  // WIN STREAK
  // Back-to-back Classic, Blind or Hardcore runs at this many stars or more
  // build a win streak. Endless runs don't touch it.
  static const double winStreakMinStars = 2.5;

  /// Ticks multiplier for a win streak of [streak] runs (including this one).
  static double winStreakMultiplier(int streak) {
    if (streak >= 5) return 1.5;
    if (streak >= 3) return 1.2;
    return 1.0;
  }

  /// A Streak Shield is used up automatically to save a streak this long or
  /// longer, so it's never wasted on a streak with no bonus yet.
  static const int streakShieldMinStreak = 3;
  static const int streakShieldCost = 100;

  static const String currencyName = "Ticks";
  static const String currencyEmoji = "⏱️";

  /// Ticks needed to unlock a mode. 0 means it is free from the start.
  static int modeUnlockCost(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
      case GameMode.endless:
        return 0;
      case GameMode.blind:
        return 300;
      case GameMode.hardcore:
        return 800;
    }
  }

  /// How much a run in this mode multiplies the Ticks earned. Endless pays
  /// per round instead (see endlessRoundTicks).
  static double modeTicksMultiplier(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
      case GameMode.endless:
        return 1.0;
      case GameMode.blind:
        return 1.5;
      case GameMode.hardcore:
        return 2.0;
    }
  }

  /// e.g. "1.5x" or "2x".
  static String modeTicksMultiplierLabel(GameMode mode) {
    final multiplier = modeTicksMultiplier(mode);
    final number = multiplier == multiplier.roundToDouble()
        ? multiplier.toInt().toString()
        : multiplier.toString();

    return "${number}x";
  }

  static String modeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return "Tap every second from 1s to 7s.";
      case GameMode.blind:
        return "Same challenge, but without the timer.";
      case GameMode.hardcore:
        return "One hidden tap. Hit exactly 7.00s.";
      case GameMode.endless:
        return "Hit 7.00s again and again. The window shrinks every round.";
    }
  }
}
