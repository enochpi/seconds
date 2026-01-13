import 'package:flutter/material.dart';

class GameConstants {
  static const List<int> targetTimes = [1000, 2000, 3000, 4000, 5000, 6000, 7000];
  static const int maxScore = 1000;
  static const int countdownDuration = 4;
  static const int updateInterval = 50; // CHANGED: From 10ms to 50ms for better performance

  // Colors
  static const Color accurateColor = Colors.green;
  static const Color okayColor = Colors.orange;
  static const Color inaccurateColor = Colors.red;
  static const Color lockedColor = Colors.grey;
  static const Color unlockedColor = Color(0xFFFFD700); // Gold color
}