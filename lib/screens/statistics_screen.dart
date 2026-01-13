import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final highScore = StorageService.getHighScore();
    final gamesPlayed = StorageService.getGamesPlayed();
    final bestAccuracy = StorageService.getBestAccuracy();

    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Game Statistics'),
            _buildStatCard(
              Icons.emoji_events,
              'High Score',
              '$highScore points',
              Colors.orange,
            ),
            _buildStatCard(
              Icons.sports_esports,
              'Games Played',
              '$gamesPlayed',
              Colors.blue,
            ),
            _buildStatCard(
              Icons.gps_fixed,
              'Best Accuracy',
              bestAccuracy == double.infinity
                  ? 'No data yet'
                  : '±${bestAccuracy.toStringAsFixed(0)}ms average',
              Colors.green,
            ),

            SizedBox(height: 24),

            _buildSectionTitle('Achievements'),
            _buildAchievements(highScore, gamesPlayed),

            SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _showResetDialog(context),
                icon: Icon(Icons.delete_forever),
                label: Text('Reset All Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements(int highScore, int gamesPlayed) {
    final achievements = [
      Achievement(
        'First Steps',
        'Play your first game',
        Icons.directions_walk,
        gamesPlayed >= 1,
      ),
      Achievement(
        'Getting Good',
        'Score 2000+ points',
        Icons.trending_up,
        highScore >= 2000,
      ),
      Achievement(
        'Master Timer',
        'Score 3500+ points',
        Icons.timer,
        highScore >= 3500,
      ),
    ];

    return Column(
      children: achievements.map((achievement) => Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        color: achievement.isUnlocked ? Colors.green[50] : Colors.grey[100],
        child: ListTile(
          leading: Icon(
            achievement.icon,
            color: achievement.isUnlocked ? Colors.green : Colors.grey,
          ),
          title: Text(
            achievement.name,
            style: TextStyle(
              decoration: achievement.isUnlocked ? null : TextDecoration.lineThrough,
            ),
          ),
          subtitle: Text(achievement.description),
          trailing: achievement.isUnlocked
              ? Icon(Icons.check_circle, color: Colors.green)
              : Icon(Icons.circle_outlined, color: Colors.grey),
        ),
      )).toList(),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset All Data?'),
          content: Text('This will permanently delete all your progress and high scores. This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Reset', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await StorageService.clearAllData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All data has been reset'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class Achievement {
  final String name;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  Achievement(this.name, this.description, this.icon, this.isUnlocked);
}