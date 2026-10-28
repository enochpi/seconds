import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../services/quest_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  Future<void> _claim(Quest quest) async {
    final reward = await QuestService.claim(quest);
    if (!mounted || reward == 0) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "+$reward ${GameConstants.currencyName} ${GameConstants.currencyEmoji}",
        ),
      ),
    );
  }

  Future<void> _claimWeeklyBox() async {
    final claimed = await QuestService.claimWeeklyBox();
    if (!mounted || !claimed) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🎁 Free Mystery Box added! Open it in the Shop."),
      ),
    );
  }

  String get _resetText {
    final left = QuestService.timeUntilReset;
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;

    return hours > 0
        ? "New quests in ${hours}h ${minutes}m"
        : "New quests in ${minutes}m";
  }

  Color _tierColor(QuestTier tier) {
    switch (tier) {
      case QuestTier.easy:
        return Colors.greenAccent;
      case QuestTier.medium:
        return Colors.lightBlueAccent;
      case QuestTier.hard:
        return Colors.deepOrangeAccent;
    }
  }

  Widget _buildCard({
    required Widget header,
    required String title,
    required int progress,
    required int target,
    required Widget action,
    required Color color,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              action,
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: target == 0 ? 0 : progress / target,
                    minHeight: 10,
                    color: color,
                    backgroundColor: onSurface.withOpacity(0.12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$progress/$target",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required bool claimed,
    required bool complete,
    required String reward,
    required VoidCallback onClaim,
  }) {
    if (claimed) {
      return const Text(
        "✅ Done",
        style:
            TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent),
      );
    }

    return ElevatedButton(
      onPressed: complete ? onClaim : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        complete ? "Collect $reward" : reward,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final color = _tierColor(quest.tier);

    return _buildCard(
      header: Text(
        Quest.tierLabel(quest.tier),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      title: quest.text,
      progress: QuestService.progress(quest),
      target: quest.target,
      color: color,
      action: _buildAction(
        claimed: QuestService.isClaimed(quest),
        complete: QuestService.isComplete(quest),
        reward: "${GameConstants.currencyEmoji} ${quest.reward}",
        onClaim: () => _claim(quest),
      ),
    );
  }

  Widget _buildWeeklyCard() {
    return _buildCard(
      header: const Text(
        "WEEKLY GOAL",
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w900,
          color: Colors.purpleAccent,
        ),
      ),
      title: "Collect ${QuestService.weeklyGoal} quests this week",
      progress: QuestService.weeklyProgress,
      target: QuestService.weeklyGoal,
      color: Colors.purpleAccent,
      action: _buildAction(
        claimed: QuestService.weeklyBoxClaimed,
        complete: QuestService.weeklyBoxClaimable,
        reward: "🎁",
        onClaim: _claimWeeklyBox,
      ),
    );
  }

  Widget _buildStreakCard() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final streak = StorageService.getWinStreak();
    final shields = StorageService.getStreakShields();
    final multiplier = GameConstants.winStreakMultiplier(streak);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "🔥 Win streak: $streak"
            "${multiplier > 1 ? "  (${multiplier}× ${GameConstants.currencyName})" : ""}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.deepOrangeAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Score ${GameConstants.winStreakMinStars}★+ in Classic, Blind or "
            "Hardcore runs in a row. 3 in a row = 1.2×, 5 in a row = 1.5× "
            "${GameConstants.currencyName}.\n"
            "🛡️ Streak Shields: $shields (buy them in the Shop)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Quests",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                "DAILY QUESTS • $_resetText",
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900,
                  color: onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ...QuestService.todaysQuests.map(_buildQuestCard),
            _buildWeeklyCard(),
            _buildStreakCard(),
          ],
        ),
      ),
    );
  }
}
