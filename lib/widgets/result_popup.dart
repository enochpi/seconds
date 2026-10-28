import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile_model.dart';
import '../services/game_service.dart';
import '../services/mystery_box_service.dart';
import '../services/profile_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'emoji_badge.dart';
import 'share_cards.dart';

class ResultPopup extends StatefulWidget {
  final GameService gameService;

  const ResultPopup({
    Key? key,
    required this.gameService,
  }) : super(key: key);

  @override
  State<ResultPopup> createState() => _ResultPopupState();
}

class _ResultPopupState extends State<ResultPopup> {
  final GlobalKey _shareCardKey = GlobalKey();
  final GlobalKey _challengeCardKey = GlobalKey();
  bool _isSharing = false;

  /// Picked once so the caption matches the card.
  late final String _challengeLine =
      (ChallengeShareCard.lines(gameService.closestTapMs)..shuffle()).first;
  bool _isSaving = false;

  GameService get gameService => widget.gameService;

  bool get isOneShotMode => gameService.mode == GameMode.hardcore;

  /// Endless scores are rounds cleared; every other mode scores points.
  String get _scoreUnit => gameService.isEndlessMode ? "rounds" : "points";

  Color getRankColor() {
    final rank = gameService.reactionRank;

    if (rank.contains("F1") || rank.contains("Lightning")) {
      return Colors.amber;
    }

    if (rank.contains("Esports") || rank.contains("Shadow")) {
      return Colors.orangeAccent;
    }

    if (rank.contains("Falcon") || rank.contains("Cheetah")) {
      return Colors.lightBlueAccent;
    }

    if (rank.contains("Fox") || rank.contains("Cat") || rank.contains("Wolf")) {
      return Colors.greenAccent;
    }

    return Colors.white;
  }

  String getModeTitle() {
    switch (gameService.mode) {
      case GameMode.classic:
        return "Classic Run";
      case GameMode.blind:
        return "Blind Rhythm Run";
      case GameMode.hardcore:
        return "Hardcore 7-Second Shot";
      case GameMode.endless:
        return "Endless Run";
    }
  }

  String getAccuracyText() {
    final average = gameService.averageErrorMs;

    if (average == null) {
      return "No accuracy yet";
    }

    if (isOneShotMode) {
      if (gameService.tapResults.isEmpty) return "No accuracy yet";

      final result = gameService.tapResults.first;

      if (result.difference == 0) {
        if (gameService.mode == GameMode.hardcore) {
          return "Perfect 7.000s";
        }

        return "Perfect";
      }

      final direction = result.difference < 0 ? "early" : "late";
      return "${result.difference.abs()}ms $direction";
    }

    return "Average error: ±${average.toStringAsFixed(0)}ms";
  }

  String getRivalChallengeText() {
    final currentScore = gameService.totalScore;
    final currentMode = gameService.mode;
    final playerName = StorageService.getPlayerName();

    final sameModeEntries = StorageService.getLeaderboardEntries()
        .where((entry) => entry.mode == currentMode)
        .toList();

    final scoresAbove = sameModeEntries
        .where((entry) => entry.score > currentScore)
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    if (scoresAbove.isNotEmpty) {
      final rival = scoresAbove.first;
      final difference = rival.score - currentScore;

      if (!rival.isBot && rival.playerName == playerName) {
        return "Your PB is $difference $_scoreUnit ahead.\nBeat your best: ${rival.score}";
      }

      if (rival.isBot) {
        return "${rival.playerName} is $difference $_scoreUnit ahead.\nBeat their PB: ${rival.score}";
      }

      return "${rival.playerName} is $difference $_scoreUnit ahead.\nBeat their score: ${rival.score}";
    }

    final scoresBelow = sameModeEntries
        .where((entry) => entry.score < currentScore)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (scoresBelow.isNotEmpty) {
      final beatenPlayer = scoresBelow.first;
      final difference = currentScore - beatenPlayer.score;

      if (!beatenPlayer.isBot && beatenPlayer.playerName == playerName) {
        return "New personal best by $difference $_scoreUnit 🔥";
      }

      return "You beat ${beatenPlayer.playerName} by $difference $_scoreUnit 🔥";
    }

    return "First score in this mode.\nSet the standard.";
  }

  String getPersonalBestText() {
    final modeName = GameConstants.modeName(gameService.mode);

    if (gameService.isNewModePersonalBest) {
      if (gameService.previousModePersonalBest <= 0) {
        return "First $modeName PB set: ${gameService.totalScore} 🔥";
      }

      final improvement =
          gameService.totalScore - gameService.previousModePersonalBest;

      return "New $modeName PB by $improvement $_scoreUnit 🔥";
    }

    final best = gameService.currentModePersonalBest;

    if (best <= 0) {
      return "Set your first $modeName personal best.";
    }

    final away = best - gameService.totalScore;

    if (away <= 0) {
      return "$modeName PB matched: $best";
    }

    return "$away $_scoreUnit away from your $modeName PB\nBest: $best";
  }

  String get _rankEmoji {
    final rank = gameService.reactionRank;
    final spaceIndex = rank.indexOf(' ');
    return spaceIndex == -1 ? rank : rank.substring(0, spaceIndex);
  }

  String get _rankName {
    final rank = gameService.reactionRank;
    final spaceIndex = rank.indexOf(' ');
    return spaceIndex == -1 ? rank : rank.substring(spaceIndex + 1);
  }

  String getAccuracyValue() {
    final average = gameService.averageErrorMs;

    if (!isOneShotMode && average != null) {
      return "±${average.toStringAsFixed(0)}ms";
    }

    return getAccuracyText();
  }

  String? getNextRankText() {
    final nextRank = gameService.nextRank;
    final msAway = gameService.msToNextRank;

    if (nextRank == null) return "👑 Top rank! Can you do it again?";
    if (msAway == null) return null;
    if (msAway <= 15) return "🔥 So close! Just ${msAway}ms from $nextRank";

    return "Next: $nextRank • ${msAway}ms tighter";
  }

  Widget _buildRankHeader(Color rankColor, Color onSurface) {
    final stars = gameService.rankStars;
    final nextRankText = getNextRankText();

    return Column(
      children: [
        Text(
          "YOUR RANK",
          style: TextStyle(
            fontSize: 18,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            color: onSurface.withOpacity(0.55),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _rankName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: rankColor,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              _buildStar((stars - i).clamp(0.0, 1.0), 38),
          ],
        ),
        if (nextRankText != null) ...[
          const SizedBox(height: 6),
          Text(
            nextRankText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.deepOrangeAccent,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  /// A star filled from the left by [fill] (0–1), so 0.5 is a half star.
  Widget _buildStar(double fill, double size) {
    return Stack(
      children: [
        Icon(Icons.star_outline_rounded, color: Colors.amber, size: size),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: Icon(Icons.star_rounded, color: Colors.amber, size: size),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBox(Color onSurface) {
    final isNewBest = gameService.isNewModePersonalBest;

    Widget stat(
      String label,
      String value,
      Color valueColor, {
      Color? labelColor,
    }) {
      return Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w900,
                color: labelColor ?? onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: onSurface.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatsRow(stat, isNewBest, onSurface),
          ..._buildProgressNotes(onSurface),
        ],
      ),
    );
  }

  /// Win streak and finished-quest lines shown under the stats.
  List<Widget> _buildProgressNotes(Color onSurface) {
    final notes = <Widget>[];

    Widget note(String text, Color color) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      );
    }

    final streak = gameService.winStreak;
    final before = gameService.streakBeforeRun;

    switch (gameService.lastStreakOutcome) {
      case WinStreakOutcome.extended:
        final multiplier = gameService.lastStreakMultiplier;
        final nextBoost = streak < 3
            ? " • ${3 - streak} more for 1.2×"
            : streak < 5
                ? " • ${5 - streak} more for 1.5×"
                : "";

        notes.add(note(
          multiplier > 1
              ? "🔥 Win streak $streak • ${multiplier}× ${GameConstants.currencyName}$nextBoost"
              : "🔥 Win streak $streak$nextBoost",
          Colors.deepOrangeAccent,
        ));
        break;
      case WinStreakOutcome.shielded:
        notes.add(note(
          "🛡️ Shield saved your 🔥$before win streak",
          Colors.lightBlueAccent,
        ));
        break;
      case WinStreakOutcome.lost:
        notes.add(note(
          "🔥$before win streak lost",
          onSurface.withOpacity(0.6),
        ));
        break;
      case WinStreakOutcome.none:
        break;
    }

    final quests = gameService.questsFinishedThisRun;
    if (quests.isNotEmpty) {
      final reward = quests.fold<int>(0, (sum, quest) => sum + quest.reward);

      notes.add(note(
        "📋 Quest complete! Collect ${GameConstants.currencyEmoji} $reward",
        Colors.lightGreenAccent,
      ));
    }

    return notes;
  }

  Widget _buildStatsRow(
    Widget Function(String, String, Color, {Color? labelColor}) stat,
    bool isNewBest,
    Color onSurface,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          stat(
            isNewBest ? "🏆 NEW BEST" : _scoreUnit.toUpperCase(),
            "${gameService.totalScore}",
            Colors.amber,
            labelColor: isNewBest ? Colors.amber : null,
          ),
          VerticalDivider(
            color: onSurface.withOpacity(0.2),
            thickness: 1.5,
            width: 20,
          ),
          stat("ACCURACY", getAccuracyValue(), onSurface),
          VerticalDivider(
            color: onSurface.withOpacity(0.2),
            thickness: 1.5,
            width: 20,
          ),
          stat(
            "EARNED",
            "+${gameService.lastRunTicks} ${GameConstants.currencyEmoji}",
            Colors.lightGreenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge({
    double size = 132,
    double? emojiSize,
    double labelSize = 18,
  }) {
    final rankColor = getRankColor();
    final rank = gameService.reactionRank;
    final spaceIndex = rank.indexOf(' ');
    final emoji = spaceIndex == -1 ? rank : rank.substring(0, spaceIndex);
    final label = spaceIndex == -1 ? '' : rank.substring(spaceIndex + 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmojiBadge(
          emoji: emoji,
          color: rankColor,
          size: size,
          emojiSize: emojiSize,
          borderWidth: size * 0.02,
        ),
        SizedBox(height: size * 0.08),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w900,
            color: rankColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  String getShareText() {
    return "${_shareTextBody()}\n\n#7Seconds #ReactionTime #TimingChallenge";
  }

  String _shareTextBody() {
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);
    final modeName = GameConstants.modeName(gameService.mode);
    final playerName = StorageService.getPlayerName();

    const appStoreLink =
        "https://play.google.com/store/apps/details?id=com.spartalabs.sevenseconds";

    switch (gameService.mode) {
      case GameMode.classic:
      case GameMode.blind:
        return "$playerName scored ${gameService.totalScore} in 7 Seconds $modeEmoji\n"
            "Mode: $modeName\n"
            "Rank: ${gameService.reactionRank}\n"
            "${gameService.percentile}\n"
            "${getAccuracyText()}\n"
            "${getPersonalBestText()}\n"
            "Best streak: x${gameService.bestRunStreak}\n\n"
            "${getRivalChallengeText()}\n\n"
            "Can you beat $playerName?\n$appStoreLink";

      case GameMode.hardcore:
        return "$playerName scored ${gameService.totalScore}/7000 in Hardcore 7 Seconds 💀\n"
            "${getAccuracyText()}\n"
            "${getPersonalBestText()}\n"
            "Rule: every millisecond off = -7 points\n\n"
            "${getRivalChallengeText()}\n\n"
            "Can you get closer to 7.000s?\n$appStoreLink";

      case GameMode.endless:
        return "$playerName survived ${gameService.totalScore} rounds in 7 Seconds Endless ♾️\n"
            "Every round: hit 7.00s, and the window keeps shrinking\n"
            "${getAccuracyText()}\n"
            "${getPersonalBestText()}\n\n"
            "${getRivalChallengeText()}\n\n"
            "Can you last longer?\n$appStoreLink";
    }
  }

  Future<void> _giveShareReward() async {
    final rewarded = await MysteryBoxService.rewardShare();
    if (!rewarded || !mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "🎁 Thanks for sharing! A free Mystery Box is waiting in the Shop.",
        ),
      ),
    );
  }

  Future<void> _shareCard(GlobalKey key, String text) async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final shared = await ShareService.shareCard(key, text: text);
      if (shared) await _giveShareReward();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't share result card. Try again."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _shareResultCard() => _shareCard(_shareCardKey, getShareText());

  Future<void> _shareChallengeCard() {
    return _shareCard(
      _challengeCardKey,
      "🎯 $_challengeLine\n\nThink you can hit exactly 7.00 seconds?\n"
      "${ShareService.storeLink}\n\n${ShareService.hashtags}",
    );
  }

  Future<void> _copyCaption() async {
    await Clipboard.setData(ClipboardData(text: getShareText()));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Caption copied! Paste it when posting to Instagram or LinkedIn.",
        ),
      ),
    );
  }

  Future<void> _saveResultImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ShareService.saveCard(_shareCardKey);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved! Ready to post to Instagram Stories."),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save the image. Try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// The "flex" card: the player's banner, framed avatar, title and a
  /// glowing score.
  Widget _buildFlexCard(PlayerProfile profile) {
    final rankColor = getRankColor();
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);
    final modeName = GameConstants.modeName(gameService.mode);
    final perfectTaps =
        gameService.tapResults.where((result) => result.isPerfect).length;

    Widget pill(String text, Color color) {
      return Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color, width: 3),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      );
    }

    return StoryCard(
      profile: profile,
      accent: rankColor,
      children: [
        const StoryWordmark(),
        const SizedBox(height: 44),
        StoryProfileHeader(profile: profile),
        const SizedBox(height: 30),
        Text(
          "$modeEmoji $modeName",
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "${gameService.totalScore}",
          style: TextStyle(
            fontSize: 220,
            fontWeight: FontWeight.w900,
            color: rankColor,
            letterSpacing: -4,
            height: 1.05,
            shadows: [
              Shadow(color: rankColor.withOpacity(0.9), blurRadius: 50),
              Shadow(color: rankColor.withOpacity(0.5), blurRadius: 120),
            ],
          ),
        ),
        if (isOneShotMode || gameService.isEndlessMode)
          Text(
            isOneShotMode ? "/ 7000" : "ROUNDS",
            style: TextStyle(
              fontSize: 44,
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w800,
            ),
          ),
        if (gameService.isNewModePersonalBest)
          pill("🏆 NEW PERSONAL BEST", Colors.amber),
        if (perfectTaps > 0)
          pill(
            "🎯 PERFECT 7.00s${perfectTaps > 1 ? " ×$perfectTaps" : ""}",
            Colors.cyanAccent,
          ),
        const SizedBox(height: 36),
        _buildRankBadge(size: 240, emojiSize: 130, labelSize: 48),
        const SizedBox(height: 18),
        if (!isOneShotMode)
          Text(
            gameService.percentile,
            style: TextStyle(
              fontSize: 34,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          getAccuracyText(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            color: Colors.white.withOpacity(0.65),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 50),
        const StoryFooter(),
      ],
    );
  }

  /// Shows the closest tap if it was within 30ms, otherwise the score (or
  /// rounds) to beat.
  Widget _buildChallengeCard(PlayerProfile profile) {
    final ms = gameService.closestTapMs;
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);
    final modeName = GameConstants.modeName(gameService.mode);

    final String bigText;
    final String bigLabel;

    if (ms != null) {
      bigText = "${ms}ms";
      bigLabel = "MY CLOSEST TO 7.00s";
    } else if (gameService.isEndlessMode) {
      bigText = "${gameService.totalScore}";
      bigLabel = "ROUNDS TO BEAT";
    } else {
      bigText = "${gameService.totalScore}";
      bigLabel = "SCORE TO BEAT";
    }

    return ChallengeShareCard(
      profile: profile,
      line: _challengeLine,
      bigText: bigText,
      bigLabel: bigLabel,
      detail: "$modeEmoji $modeName  •  Rank: ${gameService.reactionRank}",
    );
  }

  /// The share cards are rendered off-screen so they can be captured.
  Widget _buildHiddenShareCards() {
    final profile = ProfileService.current;

    return Positioned(
      left: -1400,
      top: 0,
      child: Column(
        children: [
          RepaintBoundary(
            key: _shareCardKey,
            child: _buildFlexCard(profile),
          ),
          RepaintBoundary(
            key: _challengeCardKey,
            child: _buildChallengeCard(profile),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = getRankColor();
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildHiddenShareCards(),
          // Fills the dialog height; the rank badge takes whatever space is
          // left so everything fits on one screen without scrolling.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Column(
              children: [
                // Spare space is split 4:1 between the animal and the gap
                // above the buttons, which keeps the rank and stats up high.
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      child: EmojiBadge(
                        emoji: _rankEmoji,
                        color: rankColor,
                        size: 340,
                        emojiSize: 230,
                        borderWidth: 7,
                      ),
                    ),
                  ),
                ),
                _buildRankHeader(rankColor, onSurface),
                const SizedBox(height: 10),
                _buildStatsBox(onSurface),
                const Spacer(),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareResultCard,
                    icon: _isSharing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onSurface,
                            ),
                          )
                        : const Icon(Icons.ios_share),
                    label: Text(
                      _isSharing
                          ? "Preparing Card..."
                          : MysteryBoxService.shareRewardAvailable
                              ? "Share & get a free 🎁"
                              : "Share Result Card",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: onSurface.withOpacity(0.08),
                      foregroundColor: onSurface,
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _copyCaption,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text("Caption"),
                        style: TextButton.styleFrom(
                          foregroundColor: onSurface.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isSaving ? null : _saveResultImage,
                        icon: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: onSurface.withOpacity(0.6),
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _isSaving ? "Saving..." : "Save",
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: onSurface.withOpacity(0.6),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: _isSharing ? null : _shareChallengeCard,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.cyanAccent,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text(
                          "🎯 Challenge",
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      gameService.resetToReady();
                      gameService.startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rankColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isOneShotMode ? "Try Again" : "Run It Back",
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    gameService.resetToReady();
                  },
                  child: Text(
                    "Back to menu",
                    style: TextStyle(
                      color: onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
