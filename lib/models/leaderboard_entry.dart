import 'dart:convert';

import '../utils/constants.dart';

class LeaderboardEntry {
  final String playerName;
  final int score;
  final String rank;
  final String accuracyText;
  final GameMode mode;
  final DateTime createdAt;
  final bool isBot;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.rank,
    required this.accuracyText,
    required this.mode,
    required this.createdAt,
    this.isBot = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'score': score,
      'rank': rank,
      'accuracyText': accuracyText,
      'mode': mode.name,
      'createdAt': createdAt.toIso8601String(),
      'isBot': isBot,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      playerName: map['playerName'] ?? 'Player',
      score: map['score'] ?? 0,
      rank: map['rank'] ?? 'Unknown',
      accuracyText: map['accuracyText'] ?? '',
      mode: GameMode.values.firstWhere(
        (mode) => mode.name == map['mode'],
        orElse: () => GameMode.classic,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isBot: map['isBot'] ?? false,
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory LeaderboardEntry.fromJson(String source) {
    return LeaderboardEntry.fromMap(jsonDecode(source));
  }
}
