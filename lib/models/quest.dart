import '../utils/constants.dart';

/// What happened in one finished run, used to update quest progress.
class RunSummary {
  final GameMode mode;
  final double stars;
  final int perfectTaps;
  final int endlessRounds;
  final int winStreak;

  const RunSummary({
    required this.mode,
    required this.stars,
    required this.perfectTaps,
    required this.endlessRounds,
    required this.winStreak,
  });

  bool get isEndless => mode == GameMode.endless;
}

enum QuestTier { easy, medium, hard }

class Quest {
  final String id;
  final QuestTier tier;
  final String text;
  final int target;

  /// How much this run counts toward the quest.
  final int Function(RunSummary run) amount;

  /// True: progress adds up across runs. False: only the best single run
  /// counts (e.g. "clear 10 rounds in one run").
  final bool cumulative;

  const Quest({
    required this.id,
    required this.tier,
    required this.text,
    required this.target,
    required this.amount,
    this.cumulative = false,
  });

  int get reward => rewardFor(tier);

  static int rewardFor(QuestTier tier) {
    switch (tier) {
      case QuestTier.easy:
        return 30;
      case QuestTier.medium:
        return 60;
      case QuestTier.hard:
        return 120;
    }
  }

  static String tierLabel(QuestTier tier) {
    switch (tier) {
      case QuestTier.easy:
        return "EASY";
      case QuestTier.medium:
        return "MEDIUM";
      case QuestTier.hard:
        return "HARD";
    }
  }

  // One quest from each tier is picked every day.
  static final List<Quest> all = [
    // Easy
    Quest(
      id: 'play_3',
      tier: QuestTier.easy,
      text: "Play 3 runs",
      target: 3,
      amount: (run) => 1,
      cumulative: true,
    ),
    Quest(
      id: 'good_runs_2',
      tier: QuestTier.easy,
      text: "Score 2.5★ or more in 2 runs",
      target: 2,
      amount: (run) => !run.isEndless && run.stars >= 2.5 ? 1 : 0,
      cumulative: true,
    ),
    Quest(
      id: 'endless_3',
      tier: QuestTier.easy,
      text: "Clear 3 rounds in one Endless run",
      target: 3,
      amount: (run) => run.endlessRounds,
    ),

    // Medium
    Quest(
      id: 'perfect_2',
      tier: QuestTier.medium,
      text: "Get 2 perfect taps (within 10ms)",
      target: 2,
      amount: (run) => run.perfectTaps,
      cumulative: true,
    ),
    Quest(
      id: 'stars_3_5',
      tier: QuestTier.medium,
      text: "Score 3.5★ or more in one run",
      target: 1,
      amount: (run) => !run.isEndless && run.stars >= 3.5 ? 1 : 0,
    ),
    Quest(
      id: 'endless_6',
      tier: QuestTier.medium,
      text: "Clear 6 rounds in one Endless run",
      target: 6,
      amount: (run) => run.endlessRounds,
    ),
    Quest(
      id: 'streak_3',
      tier: QuestTier.medium,
      text: "Build a 🔥 win streak of 3",
      target: 3,
      amount: (run) => run.winStreak,
    ),

    // Hard
    Quest(
      id: 'perfect_2_one_run',
      tier: QuestTier.hard,
      text: "Get 2 perfect taps in one run",
      target: 2,
      amount: (run) => run.perfectTaps,
    ),
    Quest(
      id: 'stars_4_5',
      tier: QuestTier.hard,
      text: "Score 4.5★ or more in one run",
      target: 1,
      amount: (run) => !run.isEndless && run.stars >= 4.5 ? 1 : 0,
    ),
    Quest(
      id: 'endless_10',
      tier: QuestTier.hard,
      text: "Clear 10 rounds in one Endless run",
      target: 10,
      amount: (run) => run.endlessRounds,
    ),
    Quest(
      id: 'streak_5',
      tier: QuestTier.hard,
      text: "Build a 🔥 win streak of 5",
      target: 5,
      amount: (run) => run.winStreak,
    ),
  ];
}
