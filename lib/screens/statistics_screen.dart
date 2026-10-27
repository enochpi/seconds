import 'package:flutter/material.dart';

import '../services/game_service.dart';

class StatisticsScreen extends StatelessWidget {
  final GameService gameService;

  const StatisticsScreen({
    Key? key,
    required this.gameService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bestAccuracy = gameService.bestAccuracy == double.infinity
        ? "N/A"
        : "±${gameService.bestAccuracy.toStringAsFixed(0)}ms";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(
              context: context,
              title: "High Score",
              value: "${gameService.highScore}",
              icon: Icons.emoji_events,
              color: Colors.amber,
            ),
            _buildStatCard(
              context: context,
              title: "Games Played",
              value: "${gameService.gamesPlayed}",
              icon: Icons.sports_esports,
              color: Colors.blue,
            ),
            _buildStatCard(
              context: context,
              title: "Best Accuracy",
              value: bestAccuracy,
              icon: Icons.center_focus_strong,
              color: Colors.green,
            ),
            _buildStatCard(
              context: context,
              title: "Current Rank",
              value: gameService.reactionRank,
              icon: Icons.speed,
              color: Colors.deepPurple,
            ),
            _buildStatCard(
              context: context,
              title: "Percentile",
              value: gameService.percentile,
              icon: Icons.leaderboard,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.22),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}