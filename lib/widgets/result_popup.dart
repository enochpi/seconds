import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/game_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

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
  bool _isSharing = false;

  GameService get gameService => widget.gameService;

  bool get isOneShotMode {
    return gameService.mode == GameMode.hardcore ||
        gameService.mode == GameMode.daily;
  }

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
      case GameMode.daily:
        return "Daily Challenge";
    }
  }

  String getModeGoal() {
    switch (gameService.mode) {
      case GameMode.classic:
        return "Goal: tap every second from 1s to 7s.";
      case GameMode.blind:
        return "Goal: tap every second without watching the timer.";
      case GameMode.hardcore:
        return "Goal: one tap, as close as possible to exactly 7.00s.";
      case GameMode.daily:
        return "Goal: hit today’s hidden target as closely as possible.";
    }
  }

  String getScoreExplanation() {
    switch (gameService.mode) {
      case GameMode.classic:
        return "Each tap can earn up to 1000 points.";
      case GameMode.blind:
        return "Same scoring as Classic, but without the timer.";
      case GameMode.hardcore:
        return "Start at 7000. Every millisecond off costs 7 points.";
      case GameMode.daily:
        return "Today’s target is ${(GameConstants.dailyTargetTime / 1000).toStringAsFixed(2)}s. Every millisecond off costs 7 points.";
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

  String getReplayMessage() {
    final score = gameService.totalScore;

    switch (gameService.mode) {
      case GameMode.classic:
        if (score < 5000) return "Try to reach Turtle rank.";
        if (score < 6000) return "You are close to Cobra Reflexes.";
        if (score < 6750) return "Good rhythm. Push for Alley Cat.";
        if (score < 6850) return "Fast. Now chase Cheetah speed.";
        if (score < 6950) return "Elite territory. Chase Lightning.";
        return "Almost impossible. Can you hit F1?";

      case GameMode.blind:
        if (score < 5000) return "Blind Mode is brutal. Find the rhythm.";
        if (score < 6000) return "Not bad without the timer.";
        if (score < 6750) return "Your internal clock is getting sharp.";
        if (score < 6850) return "That is seriously good blind rhythm.";
        if (score < 6950) return "Elite blind timing. Run it back.";
        return "Insane. That is almost perfect rhythm.";

      case GameMode.hardcore:
        if (score >= 6975) return "Unreal. That was almost exactly 7 seconds.";
        if (score >= 6900) return "Insane shot. You were barely off.";
        if (score >= 6750) return "Very close. One cleaner tap could be elite.";
        if (score >= 6300) return "Good attempt. Try to feel the 7-second mark.";
        if (score >= 5000) return "You were off, but not hopeless.";
        return "Hardcore is unforgiving. Try again.";

      case GameMode.daily:
        if (score >= 6975) return "Daily destroyed. That is almost perfect.";
        if (score >= 6900) return "Elite daily score. Share this one.";
        if (score >= 6750) return "Very strong daily attempt.";
        if (score >= 6300) return "Good try. Come back tomorrow.";
        return "Daily Challenge got you today.";
    }
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
        return "Your PB is $difference points ahead.\nBeat your best: ${rival.score}";
      }

      if (rival.isBot) {
        return "${rival.playerName} is $difference points ahead.\nBeat their PB: ${rival.score}";
      }

      return "${rival.playerName} is $difference points ahead.\nBeat their score: ${rival.score}";
    }

    final scoresBelow = sameModeEntries
        .where((entry) => entry.score < currentScore)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (scoresBelow.isNotEmpty) {
      final beatenPlayer = scoresBelow.first;
      final difference = currentScore - beatenPlayer.score;

      if (!beatenPlayer.isBot && beatenPlayer.playerName == playerName) {
        return "New personal best by $difference points 🔥";
      }

      return "You beat ${beatenPlayer.playerName} by $difference points 🔥";
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

      return "New $modeName PB by $improvement points 🔥";
    }

    final best = gameService.currentModePersonalBest;

    if (best <= 0) {
      return "Set your first $modeName personal best.";
    }

    final away = best - gameService.totalScore;

    if (away <= 0) {
      return "$modeName PB matched: $best";
    }

    return "$away points away from your $modeName PB\nBest: $best";
  }

  Widget _buildRivalChallengeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.amber.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Text(
            "🎯",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              getRivalChallengeText(),
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalBestBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.lightBlueAccent.withOpacity(0.30),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const Text(
            "🏅",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              getPersonalBestText(),
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getShareText() {
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);
    final modeName = GameConstants.modeName(gameService.mode);
    final playerName = StorageService.getPlayerName();

    const appStoreLink =
        "https://play.google.com/store/apps/details?id=com.spartalabs.sevenseconds&hl=ko";

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

      case GameMode.daily:
        return "$playerName scored ${gameService.totalScore}/7000 in today's 7 Seconds Daily Challenge 📅\n"
            "Target: ${(GameConstants.dailyTargetTime / 1000).toStringAsFixed(2)}s\n"
            "${getAccuracyText()}\n"
            "${getPersonalBestText()}\n\n"
            "${getRivalChallengeText()}\n\n"
            "Can you beat today's score?\n$appStoreLink";
    }
  }

  Future<void> _shareResultCard() async {
    if (_isSharing) return;

    try {
      setState(() {
        _isSharing = true;
      });

      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 180));

      final cardContext = _shareCardKey.currentContext;

      if (cardContext == null) {
        throw Exception("Share card is not ready yet");
      }

      final boundary =
      cardContext.findRenderObject() as RenderRepaintBoundary;

      if (boundary.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 180));
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Could not convert image");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/seven_seconds_result_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: getShareText(),
        subject: "Can you beat me in 7 Seconds?",
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't share result card. Try again."),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Widget _buildShareCardContent() {
    final rankColor = getRankColor();
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);
    final modeName = GameConstants.modeName(gameService.mode);
    final playerName = StorageService.getPlayerName();

    return Container(
      width: 1080,
      padding: const EdgeInsets.all(64),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: rankColor.withOpacity(0.5),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "7 SECONDS",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            playerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 54,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            "$modeEmoji $modeName",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            "${gameService.totalScore}",
            style: TextStyle(
              fontSize: 180,
              fontWeight: FontWeight.w900,
              color: rankColor,
              letterSpacing: -4,
              height: 1.0,
            ),
          ),
          if (isOneShotMode)
            Text(
              "/ 7000",
              style: TextStyle(
                fontSize: 44,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 28),
          Text(
            gameService.reactionRank,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 62,
              fontWeight: FontWeight.w900,
              color: rankColor,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 22),
          if (!isOneShotMode)
            Text(
              gameService.percentile,
              style: TextStyle(
                fontSize: 42,
                color: Colors.grey.shade300,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (!isOneShotMode) const SizedBox(height: 14),
          Text(
            getAccuracyText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.lightBlueAccent.withOpacity(0.30),
                width: 2,
              ),
            ),
            child: Text(
              getPersonalBestText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.amber.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: Text(
              getRivalChallengeText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 38),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 28,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Text(
              "Can you beat this?",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "Play 7 Seconds",
            style: TextStyle(
              fontSize: 30,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiddenShareCard() {
    return Positioned(
      left: -1400,
      top: 0,
      child: RepaintBoundary(
        key: _shareCardKey,
        child: _buildShareCardContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rankColor = getRankColor();
    final modeEmoji = GameConstants.modeEmoji(gameService.mode);

    return Dialog(
      backgroundColor: const Color(0xFF0D0D0D),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildHiddenShareCard(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$modeEmoji ${getModeTitle()}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${gameService.totalScore}",
                  style: TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: rankColor,
                    letterSpacing: -2,
                  ),
                ),
                if (isOneShotMode)
                  Text(
                    "/ 7000",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  gameService.reactionRank,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                if (!isOneShotMode)
                  Text(
                    gameService.percentile,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  getAccuracyText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade300,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        getModeGoal(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        getScoreExplanation(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  getReplayMessage(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade200,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRivalChallengeBox(),
                const SizedBox(height: 10),
                _buildPersonalBestBox(),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareResultCard,
                    icon: _isSharing
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.ios_share),
                    label: Text(
                      _isSharing ? "Preparing Card..." : "Share Result Card",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                        vertical: 13,
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    gameService.resetToReady();
                  },
                  child: Text(
                    "Back to menu",
                    style: TextStyle(
                      color: Colors.grey.shade500,
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