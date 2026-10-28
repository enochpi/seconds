import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tap_result.dart';
import '../services/cosmetics_service.dart';
import '../services/game_service.dart';
import '../services/profile_service.dart';
import '../services/quest_service.dart';
import '../services/season_service.dart';
import '../services/shop_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/cosmetic_widgets.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/game_button.dart';
import '../widgets/profile_card_widget.dart';
import '../widgets/result_popup.dart';
import '../widgets/season_podium_dialog.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'quests_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'statistics_screen.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameService _gameService;

  String _displayText = "Ready to start?";
  Color _buttonColor = Colors.blue;
  bool _buttonEnabled = false;

  bool _showNewHighScoreAnimation = false;
  Timer? _highScoreAnimationTimer;

  String _tapFeedback = "";
  Color _tapFeedbackColor = Colors.white;
  Timer? _feedbackTimer;
  bool _flashOn = false;

  /// Shows "GO!" for a moment when a run starts.
  bool _showGo = false;
  Timer? _goTimer;
  Color _flashColor = Colors.orangeAccent;

  GameMode _selectedMode = GameMode.classic;

  final GlobalKey<TapBurstState> _tapBurstKey = GlobalKey();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _gameService = GameService();
    _setupShakeAnimation();
    _setupGameServiceCallbacks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (StorageService.hasSeenTutorial()) {
        _claimSeasonReward();
      } else {
        _showIntroPopup();
      }
    });
  }

  void _setupShakeAnimation() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _setupGameServiceCallbacks() {
    _gameService.onStateChanged = (state) {
      if (!mounted) return;

      setState(() {
        switch (state) {
          case GameState.ready:
            _displayText = "Ready to start?";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            _showNewHighScoreAnimation = false;
            _tapFeedback = "";
            break;

          case GameState.countdown:
            _displayText = "Get ready...";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            _tapFeedback = "";
            break;

          case GameState.playing:
            _buttonColor = Colors.green;
            _buttonEnabled = true;
            _updatePlayingText();
            _showGo = true;
            _goTimer?.cancel();
            _goTimer = Timer(const Duration(milliseconds: 700), () {
              if (mounted) setState(() => _showGo = false);
            });
            break;

          case GameState.ended:
            _buttonColor = Colors.blue;
            _buttonEnabled = false;

            // If the last tap was perfect or a near-miss, give its
            // celebration time to play before the results cover it.
            final taps = _gameService.tapResults;
            final lastTapWasBig = taps.isNotEmpty &&
                (taps.last.isPerfect ||
                    taps.last.isNearMiss ||
                    _gameService.isEndlessMode);

            Future.delayed(
              Duration(milliseconds: lastTapWasBig ? 1300 : 300),
              () {
                if (!mounted) return;
                if (_gameService.state != GameState.ended) return;

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return ResultPopup(
                      gameService: _gameService,
                    );
                  },
                ).then((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              },
            );

            break;
        }
      });
    };

    _gameService.onEndlessMiss = (result) {
      // Let the miss feedback show for a moment before the offer pops up.
      Future.delayed(const Duration(milliseconds: 600), () {
        _showContinueOffer(result);
      });
    };

    _gameService.onCountdownUpdate = (value) {
      if (!mounted) return;

      SoundService.instance.play(GameSound.countdownTick);

      setState(() {
        _displayText = value.toString();
      });
    };

    _gameService.onGameTimeUpdate = (_) {
      if (!mounted) return;

      setState(() {
        _updatePlayingText();
      });
    };

    _gameService.onTapResult = (result) {
      if (!mounted) return;

      _handleTapFeedback(result);

      setState(() {
        _updatePlayingText();
      });
    };

    _gameService.onNewHighScore = () {
      if (!mounted) return;

      SoundService.instance.play(GameSound.highScore);

      setState(() {
        _showNewHighScoreAnimation = true;
      });

      _highScoreAnimationTimer?.cancel();
      _highScoreAnimationTimer = Timer(
        const Duration(seconds: 5),
        () {
          if (mounted) {
            setState(() {
              _showNewHighScoreAnimation = false;
            });
          }
        },
      );
    };
  }

  void _handleTapFeedback(TapResult result) {
    final hapticsEnabled = StorageService.getHapticsEnabled();

    if (_gameService.isEndlessMode) {
      _handleEndlessTapFeedback(result, hapticsEnabled);
      return;
    }

    if (result.isPerfect) {
      if (hapticsEnabled) HapticFeedback.heavyImpact();
      SoundService.instance.play(GameSound.tapPerfect);
      _celebratePerfect(
        result.isBullseye
            ? "💥 BULLSEYE! 7.000s "
                "+${GameConstants.bullseyeBonusTicks} ${GameConstants.currencyEmoji}"
            : "🎯 PERFECT! Off by ${_seconds(result.difference.abs())}",
        bullseye: result.isBullseye,
      );
      return;
    } else if (result.isNearMiss) {
      if (hapticsEnabled) HapticFeedback.heavyImpact();
      SoundService.instance.play(GameSound.tapGood);
      _showSoClose("😫 SO CLOSE! Off by ${_seconds(result.difference.abs())}");
      return;
    } else if (result.isAccurate) {
      _tapFeedbackColor = Colors.greenAccent;
      if (hapticsEnabled) HapticFeedback.mediumImpact();
      SoundService.instance.play(GameSound.tapGood);
    } else if (result.isOkay) {
      _tapFeedbackColor = Colors.orangeAccent;
      if (hapticsEnabled) HapticFeedback.selectionClick();
      SoundService.instance.play(GameSound.tapGood);
    } else {
      _tapFeedbackColor = Colors.redAccent;
      if (hapticsEnabled) HapticFeedback.heavyImpact();
      SoundService.instance.play(GameSound.tapMiss);
      _shakeController.forward(from: 0);
    }

    setState(() {
      _tapFeedback = result.feedbackText;
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;

        setState(() {
          _tapFeedback = "";
        });
      },
    );
  }

  /// e.g. 14 -> "0.014s".
  String _seconds(int ms) => "${(ms / 1000).toStringAsFixed(3)}s";

  /// Feedback text in [color] plus a flash of the same color around the
  /// screen edges.
  void _showFlashFeedback(
    String text,
    Color color, {
    Duration flash = const Duration(milliseconds: 350),
  }) {
    setState(() {
      _tapFeedbackColor = color;
      _tapFeedback = text;
      _flashColor = color;
      _flashOn = true;
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: 1200),
      () {
        if (!mounted) return;

        setState(() {
          _tapFeedback = "";
        });
      },
    );

    Timer(flash, () {
      if (mounted) setState(() => _flashOn = false);
    });
  }

  void _showSoClose(String text) =>
      _showFlashFeedback(text, Colors.orangeAccent);

  /// Coin bursts and a cyan (or gold, for an exact 7.000s) flash.
  void _celebratePerfect(String text, {required bool bullseye}) {
    _showFlashFeedback(
      text,
      bullseye ? Colors.amber : Colors.cyanAccent,
      flash: Duration(milliseconds: bullseye ? 700 : 450),
    );

    const coins = ['🪙', '⏱️', '✨', '💰'];
    final bursts = bullseye ? 5 : 3;

    for (var i = 0; i < bursts; i++) {
      Timer(Duration(milliseconds: 120 * i), () {
        if (mounted) _tapBurstKey.currentState?.burst(coins);
      });
    }
  }

  // In Endless a TapResult score of 1 means the round was cleared.
  void _handleEndlessTapFeedback(TapResult result, bool hapticsEnabled) {
    final cleared = result.score > 0;

    if (cleared) {
      _tapFeedbackColor =
          result.isPerfect ? Colors.cyanAccent : Colors.greenAccent;
      if (hapticsEnabled) HapticFeedback.mediumImpact();
      SoundService.instance.play(
        result.isPerfect ? GameSound.tapPerfect : GameSound.tapGood,
      );
    } else {
      _tapFeedbackColor = Colors.redAccent;
      if (hapticsEnabled) HapticFeedback.heavyImpact();
      SoundService.instance.play(GameSound.tapMiss);
      _shakeController.forward(from: 0);
    }

    final roundTicks = GameConstants.endlessRoundTicks(result.score > 0
        ? _gameService.endlessRound - 1
        : _gameService.endlessRound);

    // Missed the window by a hair.
    final outsideBy = result.difference.abs() - _gameService.endlessMarginMs;
    if (!cleared && outsideBy <= GameConstants.nearMissMaxMs) {
      _showSoClose("😫 SO CLOSE! Just ${_seconds(outsideBy)} outside");
      return;
    }

    if (cleared && result.isPerfect) {
      _celebratePerfect(
        result.isBullseye
            ? "💥 BULLSEYE! +${roundTicks + GameConstants.bullseyeBonusTicks} "
                "${GameConstants.currencyEmoji}"
            : "🎯 PERFECT CLEAR +$roundTicks ${GameConstants.currencyEmoji}",
        bullseye: result.isBullseye,
      );
      return;
    }

    setState(() {
      _tapFeedback = cleared
          ? "✅ CLEARED +$roundTicks ${GameConstants.currencyEmoji}"
          : "💥 MISSED ${result.formattedDifference}";
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(
      const Duration(milliseconds: 1100),
      () {
        if (!mounted) return;

        setState(() {
          _tapFeedback = "";
        });
      },
    );
  }

  void _showContinueOffer(TapResult miss) {
    final cost = _gameService.nextContinueCost;
    if (cost == null || !mounted) return;

    final cleared = _gameService.endlessRound - 1;
    final round = _gameService.endlessRound;
    final nextPay = GameConstants.endlessRoundTicks(round);
    final soFar = GameService.endlessTicksForRounds(cleared);

    // Find the next milestone so we can dangle it.
    var milestoneRound = round;
    while (GameConstants.endlessMilestoneBonus(milestoneRound) == 0) {
      milestoneRound++;
    }
    final milestoneBonus = GameConstants.endlessMilestoneBonus(milestoneRound);

    final direction = miss.difference < 0 ? "early" : "late";
    final balance = StorageService.getTicks();
    final canAfford = balance >= cost;
    const ticks = GameConstants.currencyEmoji;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final onSurface = Theme.of(dialogContext).colorScheme.onSurface;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("💥", style: TextStyle(fontSize: 48)),
                Text(
                  "${miss.difference.abs()}ms $direction!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  "You needed ±${_gameService.endlessMarginMs}ms",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$cleared rounds cleared • +$soFar $ticks so far",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Text(
                    "Keep going: round $round pays +$nextPay $ticks\n"
                    "Reach round $milestoneRound for a +$milestoneBonus $ticks bonus",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canAfford
                        ? () async {
                            Navigator.pop(dialogContext);
                            await _gameService.continueEndlessRun();
                            if (mounted) setState(() {});
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      canAfford
                          ? "Continue for $ticks $cost"
                          : "Need ${cost - balance} more $ticks",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_gameService.continuesLeft} continue"
                  "${_gameService.continuesLeft == 1 ? '' : 's'} left this run",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: onSurface.withOpacity(0.5),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _gameService.endEndlessRun();
                  },
                  child: Text(
                    "End run & collect $soFar $ticks",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _claimSeasonReward() async {
    final reward = await SeasonService.claimFinishedSeasonReward();
    if (reward == null || !mounted) return;

    setState(() {});
    await showDialog(
      context: context,
      builder: (_) => SeasonPodiumDialog(reward: reward),
    );
    if (mounted) setState(() {});
  }

  void _updatePlayingText() {
    if (_gameService.state == GameState.playing) {
      if (_gameService.isEndlessMode) {
        _displayText =
            "Tap at 7.00s • within ±${_gameService.endlessMarginMs}ms";
        return;
      }

      if (_gameService.isHardcoreMode) {
        _displayText = "Tap once at exactly 7.00s";
        return;
      }

      final targetTime = _gameService.currentTargetTime / 1000.0;

      _displayText =
          "Tap ${_gameService.currentTargetNumber}/${_gameService.totalTargets} at ${targetTime.toStringAsFixed(2)}s";
    }
  }

  void _showIntroPopup() async {
    if (StorageService.hasSeenTutorial()) {
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final onSurface = Theme.of(dialogContext).colorScheme.onSurface;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Can you keep perfect rhythm for 7 seconds?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Tap at exactly 1s, 2s, 3s... all the way to 7s.\n\n"
                  "The closer you are, the higher your reflex rank.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withOpacity(0.6),
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await StorageService.setTutorialSeen();

                      if (!mounted) return;

                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(dialogContext).colorScheme.primary,
                      foregroundColor:
                          Theme.of(dialogContext).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Start the Challenge",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModeDialog() {
    if (_gameService.state != GameState.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can change modes before starting a run."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final onSurface = Theme.of(dialogContext).colorScheme.onSurface;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose Mode",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pick how you want to test your rhythm.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                ...GameMode.values.map((mode) {
                  final selected = _selectedMode == mode;
                  final unlocked = StorageService.isModeUnlocked(mode);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: selected
                          ? Colors.blue.shade700
                          : onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(dialogContext);

                          // Locked modes send the player to the shop.
                          if (!unlocked) {
                            _openShop();
                            return;
                          }

                          setState(() {
                            _selectedMode = mode;
                            _gameService.setMode(mode);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                unlocked ? GameConstants.modeEmoji(mode) : "🔒",
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      GameConstants.modeName(mode),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color:
                                            selected ? Colors.white : onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      unlocked
                                          ? GameConstants.modeDescription(mode)
                                          : "Unlock for ${GameConstants.currencyEmoji} "
                                              "${GameConstants.modeUnlockCost(mode)} "
                                              "• pays ${GameConstants.modeTicksMultiplierLabel(mode)}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white.withOpacity(0.85)
                                            : onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        gradient: _showNewHighScoreAnimation
            ? LinearGradient(
                colors: [
                  Colors.orange.shade700,
                  Colors.orange.shade400,
                ],
              )
            : null,
        color: _showNewHighScoreAnimation ? null : onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: _showNewHighScoreAnimation
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatText(
              "Score",
              "${_gameService.totalScore}",
              _showNewHighScoreAnimation
                  ? Colors.white
                  : Colors.lightBlueAccent,
            ),
          ),
          Expanded(
            child: _buildStatText(
              "Streak",
              "x${_gameService.currentStreak}",
              Colors.deepOrangeAccent,
            ),
          ),
          Expanded(
            child: _buildStatText(
              "Best",
              "${_gameService.highScore}",
              Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  void _openShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildTicksChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Material(
        color: Colors.amber.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: _openShop,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                "${GameConstants.currencyEmoji} ${StorageService.getTicks()}",
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openQuests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestsScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildSmallChip({
    required String text,
    required Color color,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 9,
                backgroundColor: Colors.redAccent,
                child: Text(
                  "$badge",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The win streak (and any Streak Shields), next to the mode pill.
  Widget _buildStreakChip() {
    final streak = StorageService.getWinStreak();
    final shields = StorageService.getStreakShields();
    if (streak == 0 && shields == 0) return const SizedBox.shrink();

    return _buildSmallChip(
      text: "🔥 $streak${shields > 0 ? "  🛡️ $shields" : ""}",
      color: Colors.deepOrangeAccent,
      onTap: _openQuests,
    );
  }

  Widget _buildPetChip() {
    final pet = ShopService.equippedPet;
    if (pet == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _openShop,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pet.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(
              pet.bonusLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: _showModeDialog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              GameConstants.modeEmoji(_selectedMode),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              "${GameConstants.modeName(_selectedMode)} Mode",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerArea() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (_gameService.state == GameState.countdown) {
      return SizedBox(
        height: 140,
        child: CountdownWidget(
          countdownValue: _gameService.countdownValue,
          isActive: true,
          size: 100,
        ),
      );
    }

    // "GO!" for a moment as the run starts.
    if (_gameService.state == GameState.playing && _showGo) {
      return const SizedBox(
        height: 140,
        child: CountdownWidget(
          key: ValueKey("go"),
          countdownValue: 0,
          isActive: true,
          text: "GO!",
          color: Colors.greenAccent,
          size: 100,
        ),
      );
    }

    if (_gameService.state == GameState.playing) {
      final shouldHideTimer = _gameService.isBlindMode;

      String mainText;
      String subText;

      if (_gameService.isEndlessMode) {
        if (_gameService.isBetweenRounds) {
          mainText = "Round ${_gameService.endlessRound}";
          subText = "Get ready… window ±${_gameService.endlessMarginMs}ms";
        } else {
          mainText = "Round ${_gameService.endlessRound}";
          subText = _displayText;
        }
      } else if (_gameService.isHardcoreMode) {
        mainText = "Wait for 7s";
        subText = "Tap exactly at 7.00";
      } else if (shouldHideTimer) {
        mainText = "Feel the rhythm";
        subText = _displayText;
      } else {
        mainText = "${_gameService.currentGameTimeDisplay}s";
        subText = _displayText;
      }

      return SizedBox(
        height: 140,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StyledTimerText(
                    text: mainText,
                    style: CosmeticsService.timer,
                    fontSize: shouldHideTimer ? 28 : 52,
                    defaultColor: shouldHideTimer
                        ? Colors.purpleAccent
                        : Colors.lightBlueAccent,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _displayText,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: onSurface.withOpacity(0.85),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _tapFeedback.isEmpty
          ? const SizedBox(
              key: ValueKey("empty-feedback"),
              height: 36,
            )
          : SizedBox(
              key: ValueKey(_tapFeedback),
              height: 36,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _tapFeedback,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: _tapFeedbackColor,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGameButtonArea() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final dx = _shakeController.isAnimating
              ? _shakeAnimation.value *
                  ((_shakeController.value * 10).round().isEven ? 1 : -1)
              : 0.0;

          return Transform.translate(
            offset: Offset(dx, 0),
            child: child,
          );
        },
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Transform.scale(
                  scale: 1.45,
                  child: GameButton(
                    enabled: _buttonEnabled,
                    color: _buttonColor,
                    onTap: () {
                      _gameService.handleTap();
                      _tapBurstKey.currentState
                          ?.burst(CosmeticsService.tapEffect.particles);
                    },
                  ),
                ),
              ),
            ),
            // Tap Effect particles, centered on the button.
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: TapBurst(key: _tapBurstKey),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: _gameService.tapResults.map((result) {
                    final color = result.isAccurate
                        ? Colors.green
                        : result.isOkay
                            ? Colors.orange
                            : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        result.formattedDifference,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HOME SCREEN
  // While on the home screen, buttons line the sides and top. Pressing PLAY
  // slides them all away, leaving just the timer and the tap button.

  bool get _isHome => _gameService.state == GameState.ready;

  bool get _isSessionActive =>
      _gameService.state == GameState.countdown ||
      _gameService.state == GameState.playing;

  /// Opens a screen and refreshes the home screen when it closes.
  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Slides [child] off toward [offset] (in its own sizes) and fades it out
  /// while a run is going.
  Widget _slideAway({
    required bool hidden,
    required Offset offset,
    required Widget child,
  }) {
    return IgnorePointer(
      ignoring: hidden,
      child: AnimatedSlide(
        offset: hidden ? offset : Offset.zero,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: hidden ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          child: child,
        ),
      ),
    );
  }

  Widget _buildRailButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                if (badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.redAccent,
                      child: Text(
                        "$badge",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railEmoji(String emoji) {
    return Text(emoji, style: const TextStyle(fontSize: 26));
  }

  Widget _buildLeftRail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRailButton(
          icon: _railEmoji("🏆"),
          label: "Ranks",
          onTap: () => _open(const LeaderboardScreen()),
        ),
        _buildRailButton(
          icon: _railEmoji("🎖️"),
          label: "Trophies",
          onTap: () => _open(AchievementsScreen(gameService: _gameService)),
        ),
        _buildRailButton(
          icon: _railEmoji("📋"),
          label: "Quests",
          onTap: _openQuests,
          badge: QuestService.claimableCount,
        ),
      ],
    );
  }

  Widget _buildRightRail() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRailButton(
          icon: _railEmoji("🛒"),
          label: "Shop",
          onTap: _openShop,
        ),
        _buildRailButton(
          icon: FramedAvatar(profile: ProfileService.current, size: 50),
          label: "Profile",
          onTap: () => _open(StatisticsScreen(gameService: _gameService)),
        ),
        _buildRailButton(
          icon: _railEmoji("⚙️"),
          label: "Settings",
          onTap: () => _open(SettingsScreen(gameService: _gameService)),
        ),
      ],
    );
  }

  /// Home: the game name and your Ticks. During a run: a quit button.
  Widget _buildTopBar() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          _slideAway(
            hidden: !_isHome,
            offset: const Offset(0, -1.5),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    "7 SECONDS",
                    style: TextStyle(
                      fontSize: 22,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                      color: onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildTicksChip(),
                ],
              ),
            ),
          ),
          if (_isSessionActive)
            Positioned(
              left: 4,
              top: 4,
              child: IconButton(
                tooltip: "Quit run",
                icon: Icon(
                  Icons.close_rounded,
                  size: 30,
                  color: onSurface.withOpacity(0.7),
                ),
                onPressed: _gameService.resetToReady,
              ),
            ),
        ],
      ),
    );
  }

  /// Mode, pet and streak above the timer. Same spacing as the old layout so
  /// the timer and tap button stay where they always were.
  Widget _buildHomeChips() {
    return _slideAway(
      hidden: !_isHome,
      offset: const Offset(0, -0.6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: _buildModePill()),
                _buildPetChip(),
              ],
            ),
          ),
          SizedBox(
            height: 37,
            child: Center(child: _buildStreakChip()),
          ),
        ],
      ),
    );
  }

  /// The PLAY button, in the same spot as the old Start button.
  Widget _buildPlayArea() {
    return _slideAway(
      hidden: !_isHome,
      offset: const Offset(0, 1.5),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 78),
        child: Center(
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: _isHome ? _gameService.startGame : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 6,
              ),
              child: const Text(
                "PLAY",
                style: TextStyle(
                  fontSize: 21,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPopNow = _gameService.state == GameState.ready;
    final background = CosmeticsService.background;
    final hasBackground = background.colors.isNotEmpty;

    final scaffold = Scaffold(
      backgroundColor: hasBackground ? Colors.transparent : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildStats(),
                _buildHomeChips(),
                _buildTimerArea(),
                _buildFeedbackText(),
                _buildGameButtonArea(),
                _buildPlayArea(),
              ],
            ),
          ),
          // Side buttons, centered on the tap button.
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: _slideAway(
                  hidden: !_isHome,
                  offset: const Offset(-1.6, 0),
                  child: _buildLeftRail(),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Center(
                child: _slideAway(
                  hidden: !_isHome,
                  offset: const Offset(1.6, 0),
                  child: _buildRightRail(),
                ),
              ),
            ),
          ),
          // Colored glow around the edges: gold/cyan on a perfect tap,
          // orange on a "SO CLOSE".
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flashOn ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _flashColor.withOpacity(0.85),
                      width: 10,
                    ),
                    gradient: RadialGradient(
                      radius: 1.1,
                      colors: [
                        Colors.transparent,
                        _flashColor.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: canPopNow,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // A game is active (or just ended) — treat back as "stop", not
        // "exit app". This also stops a pending auto-popup from racing
        // with navigation instead of letting it fire on a stale state.
        _gameService.resetToReady();
      },
      // The app switches to dark mode while a background is equipped (see
      // main.dart), so text stays readable on top of it.
      child: CosmeticBackground(style: background, child: scaffold),
    );
  }

  @override
  void dispose() {
    _gameService.dispose();
    _highScoreAnimationTimer?.cancel();
    _feedbackTimer?.cancel();
    _shakeController.dispose();
    _goTimer?.cancel();

    super.dispose();
  }
}
