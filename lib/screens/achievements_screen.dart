import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../services/game_service.dart';
import '../widgets/emoji_badge.dart';

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
                final onSurface = Theme.of(context).colorScheme.onSurface;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: achievement.unlocked
                        ? Colors.green.withOpacity(0.12)
                        : onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: achievement.unlocked
                          ? Colors.green.withOpacity(0.4)
                          : onSurface.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          EmojiBadge(
                            emoji: achievement.emoji,
                            color: achievement.unlocked
                                ? Colors.greenAccent
                                : onSurface.withOpacity(0.3),
                            size: 56,
                            emojiSize: 28,
                            opacity: achievement.unlocked ? 1 : 0.4,
                            glow: achievement.unlocked,
                          ),
                          if (!achievement.unlocked)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock,
                                  size: 14,
                                  color: onSurface.withOpacity(0.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: achievement.unlocked
                                    ? onSurface
                                    : onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              achievement.description,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: achievement.unlocked
                                    ? onSurface.withOpacity(0.7)
                                    : onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (achievement.unlocked)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
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