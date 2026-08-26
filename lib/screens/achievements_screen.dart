import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/game_service.dart';

class AchievementsScreen extends StatelessWidget {
  final GameService gameService;

  const AchievementsScreen({
    Key? key,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievements = gameService.achievements;
    final unlockedCount =
        achievements.where((achievement) => achievement.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.purple.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$unlockedCount / ${achievements.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: achievements.isEmpty
                      ? 0
                      : unlockedCount / achievements.length,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final Achievement achievement = achievements[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: achievement.unlocked
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: achievement.unlocked
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        achievement.unlocked
                            ? Icons.emoji_events
                            : Icons.lock,
                        color: achievement.unlocked
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: achievement.unlocked
                                    ? Colors.black
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              achievement.description,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: achievement.unlocked
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (achievement.unlocked)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}