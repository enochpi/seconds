import 'package:flutter/material.dart';

class GameConstants {
  static const List<int> targetTimes = [1000, 3000, 5000, 7000];
  static const int maxScore = 1000;
  static const int countdownDuration = 3;
  static const int updateInterval = 50; // CHANGED: From 10ms to 50ms for better performance

  // Exact Mode Constants
  static const int exactModeUnlockScore = 3900; // Changed from 390 to 3900
  static const List<int> exactModeTargets = [1000, 2000, 3000, 4000, 5000, 6000, 7000]; // 1.00s to 7.00s
  static const int exactModeToleranceMs = 50; // ±50ms tolerance for "exact"

  // Colors
  static const Color accurateColor = Colors.green;
  static const Color okayColor = Colors.orange;
  static const Color inaccurateColor = Colors.red;
  static const Color lockedColor = Colors.grey;
  static const Color unlockedColor = Color(0xFFFFD700); // Gold color
}