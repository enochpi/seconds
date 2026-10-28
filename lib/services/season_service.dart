import 'dart:math';

import '../models/leaderboard_entry.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class SeasonReward {
  final int seasonIndex;
  final int placement;
  final int rounds;
  final int ticks;

  const SeasonReward({
    required this.seasonIndex,
    required this.placement,
    required this.rounds,
    required this.ticks,
  });
}

/// One place in a season's final standings.
class PodiumSpot {
  final String name;
  final int rounds;
  final bool isPlayer;

  const PodiumSpot({
    required this.name,
    required this.rounds,
    required this.isPlayer,
  });
}

/// Endless mode runs in 3-day seasons. Everyone in a season races the same
/// bots, and Ticks are paid out by placement once the season ends.
class SeasonService {
  static const int seasonLengthDays = 3;

  /// Ticks for 1st, 2nd and 3rd. Everyone else who played gets the last one.
  static const List<int> placementPrizes = [2000, 1000, 500];
  static const int participationPrize = 100;

  static int get currentSeasonIndex {
    final daysSinceEpoch = DateTime.now().toUtc().millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;

    return daysSinceEpoch ~/ seasonLengthDays;
  }

  static DateTime seasonStart(int seasonIndex) {
    return DateTime.utc(1970).add(
      Duration(days: seasonIndex * seasonLengthDays),
    );
  }

  static DateTime get currentSeasonEnd => seasonStart(currentSeasonIndex + 1);

  /// e.g. "2d 5h" or "47m".
  static String get timeLeft {
    final left = currentSeasonEnd.difference(DateTime.now().toUtc());

    if (left.inDays > 0) return "${left.inDays}d ${left.inHours % 24}h";
    if (left.inHours > 0) return "${left.inHours}h ${left.inMinutes % 60}m";

    return "${max(1, left.inMinutes)}m";
  }

  static bool isInSeason(DateTime time, int seasonIndex) {
    final utc = time.toUtc();

    return !utc.isBefore(seasonStart(seasonIndex)) &&
        utc.isBefore(seasonStart(seasonIndex + 1));
  }

  static int prizeForPlacement(int placement) {
    if (placement <= placementPrizes.length) {
      return placementPrizes[placement - 1];
    }

    return participationPrize;
  }

  /// The same bots (and scores) for every player in a given season.
  static List<LeaderboardEntry> botsForSeason(int seasonIndex) {
    final random = Random(seasonIndex * 7919);
    final start = seasonStart(seasonIndex);

    const bots = [
      ['InfinityIvy', 12, 5],
      ['LoopLord', 9, 4],
      ['TickTockTom', 6, 4],
      ['SevenSam', 4, 3],
      ['OneMoreTry', 2, 3],
    ];

    return bots.map((bot) {
      final rounds = (bot[1] as int) + random.nextInt(bot[2] as int);

      return LeaderboardEntry(
        playerName: bot[0] as String,
        score: rounds,
        rank: "${GameConstants.modeEmoji(GameMode.endless)} Endless",
        accuracyText: "$rounds rounds",
        mode: GameMode.endless,
        createdAt: start,
        isBot: true,
      );
    }).toList();
  }

  /// 1 = first place.
  static int placementFor(int rounds, int seasonIndex) {
    final botsAhead =
        botsForSeason(seasonIndex).where((bot) => bot.score > rounds).length;

    return botsAhead + 1;
  }

  /// Pays out the most recent finished season once. Returns null if there is
  /// nothing to claim (didn't play it, or already claimed).
  static Future<SeasonReward?> claimFinishedSeasonReward() async {
    final lastSeason = currentSeasonIndex - 1;

    if (StorageService.getLastClaimedSeason() >= lastSeason) return null;

    final rounds = StorageService.getSeasonBest(lastSeason);
    await StorageService.setLastClaimedSeason(lastSeason);

    if (rounds <= 0) return null;

    final placement = placementFor(rounds, lastSeason);
    final ticks = prizeForPlacement(placement);

    await StorageService.addTicks(ticks);

    return SeasonReward(
      seasonIndex: lastSeason,
      placement: placement,
      rounds: rounds,
      ticks: ticks,
    );
  }

  /// Final standings: the bots plus the player, best first. The player wins
  /// ties, matching [placementFor].
  static List<PodiumSpot> standings({
    required int seasonIndex,
    required int playerRounds,
    required String playerName,
  }) {
    final spots = [
      PodiumSpot(name: playerName, rounds: playerRounds, isPlayer: true),
      for (final bot in botsForSeason(seasonIndex))
        PodiumSpot(name: bot.playerName, rounds: bot.score, isPlayer: false),
    ];

    spots.sort((a, b) {
      if (a.rounds != b.rounds) return b.rounds.compareTo(a.rounds);
      return a.isPlayer ? -1 : (b.isPlayer ? 1 : 0);
    });

    return spots;
  }
}
