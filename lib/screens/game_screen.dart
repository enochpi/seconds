import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tap_result.dart';
import '../services/game_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/game_button.dart';
import '../widgets/result_popup.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
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

  GameMode _selectedMode = GameMode.classic;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _gameService = GameService();
    _setupShakeAnimation();
    _setupGameServiceCallbacks();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showIntroPopup();
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
            break;

          case GameState.ended:
            _buttonColor = Colors.blue;
            _buttonEnabled = false;

            Future.delayed(
              const Duration(milliseconds: 300),
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

    if (result.isPerfect) {
      _tapFeedbackColor = Colors.cyanAccent;
      if (hapticsEnabled) HapticFeedback.heavyImpact();
      SoundService.instance.play(GameSound.tapPerfect);
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

  void _updatePlayingText() {
    if (_gameService.state == GameState.playing) {
      if (_gameService.isDailyChallengeMode) {
        _displayText =
            "Today's target: ${(GameConstants.dailyTargetTime / 1000).toStringAsFixed(2)}s";
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
                          setState(() {
                            _selectedMode = mode;
                            _gameService.setMode(mode);
                          });

                          Navigator.pop(dialogContext);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                GameConstants.modeEmoji(mode),
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
                                      GameConstants.modeDescription(mode),
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

  Widget _buildModePill() {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: _showModeDialog,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
        ),
      );
    }

    if (_gameService.state == GameState.playing) {
      final shouldHideTimer = _gameService.isBlindMode;

      String mainText;
      String subText;

      if (_gameService.isDailyChallengeMode) {
        mainText = "Daily Challenge";
        subText =
            "Tap exactly at ${(GameConstants.dailyTargetTime / 1000).toStringAsFixed(2)}s";
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
                  child: Text(
                    mainText,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: shouldHideTimer ? 28 : 52,
                      fontWeight: FontWeight.w900,
                      color: shouldHideTimer
                          ? Colors.purpleAccent
                          : Colors.lightBlueAccent,
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
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
                    onTap: _gameService.handleTap,
                  ),
                ),
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

  Widget _buildStartButton() {
    final isSessionActive = _gameService.state == GameState.countdown ||
        _gameService.state == GameState.playing;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 78),
      child: Center(
        child: SizedBox(
          width: 220,
          child: ElevatedButton(
            onPressed: () {
              if (isSessionActive) {
                _gameService.resetToReady();
              } else {
                _gameService.startGame();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSessionActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 6,
            ),
            child: Text(
              isSessionActive ? "Stop" : "Start",
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        '7 Seconds',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _showModeDialog,
          icon: Text(
            GameConstants.modeEmoji(_selectedMode),
            style: const TextStyle(fontSize: 22),
          ),
          label: Text(
            GameConstants.modeName(_selectedMode),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: "Leaderboard",
          icon: const Icon(Icons.format_list_numbered),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LeaderboardScreen(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AchievementsScreen(
                  gameService: _gameService,
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatisticsScreen(
                  gameService: _gameService,
                ),
              ),
            );

            if (mounted) {
              setState(() {});
            }
          },
        ),
        IconButton(
          tooltip: "Settings",
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(gameService: _gameService),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPopNow = _gameService.state == GameState.ready;

    return PopScope(
      canPop: canPopNow,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // A game is active (or just ended) — treat back as "stop", not
        // "exit app". This also stops a pending auto-popup from racing
        // with navigation instead of letting it fire on a stale state.
        _gameService.resetToReady();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildStats(),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Center(
                  child: _buildModePill(),
                ),
              ),
              _buildTimerArea(),
              _buildFeedbackText(),
              _buildGameButtonArea(),
              _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameService.dispose();
    _highScoreAnimationTimer?.cancel();
    _feedbackTimer?.cancel();
    _shakeController.dispose();

    super.dispose();
  }
}
