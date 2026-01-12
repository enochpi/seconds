import 'package:flutter/material.dart';
import 'dart:ui'; // ADDED: For FontFeature.tabularFigures()
import 'dart:async'; // ADDED: For Timer
import '../models/tap_result.dart';
import '../services/game_service.dart';
import '../services/exact_mode_service.dart';
import '../services/storage_service.dart';
import '../models/game_mode.dart';
import '../utils/constants.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/game_button.dart';
import '../widgets/results_display.dart';
import '../widgets/control_buttons.dart';
import '../widgets/mode_selector.dart';
import '../widgets/unlock_animation.dart';
import '../widgets/exact_mode_display.dart';
import 'statistics_screen.dart'; // ADDED: Import statistics screen

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameService _gameService;
  late ExactModeService _exactModeService;

  GameMode _currentMode = GameMode.free;
  String _displayText = "Ready to start?";
  String _sequenceProgress = "1/1";
  Color _buttonColor = Colors.blue;
  bool _buttonEnabled = false;
  bool _showNewHighScoreAnimation = false;
  bool _showUnlockAnimation = false;
  bool _showLevelCompleteDialog = false;
  bool _exactModeUnlocked = false;

  // NEW: Spam prevention and session tracking
  bool _hasShownUnlockThisSession = false;
  DateTime? _lastSpamClickTime;
  bool _hasShownSnackbarThisSpamSession = false;
  Timer? _highScoreAnimationTimer; // ADDED: Timer for high score animation
  static const Duration _spamClickCooldown = Duration(milliseconds: 500);
  static const Duration _spamSessionTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _exactModeService = ExactModeService();
    _exactModeUnlocked = StorageService.isExactModeUnlocked();
    _setupGameServiceCallbacks();
    _setupExactModeCallbacks();
  }

  void _setupGameServiceCallbacks() {
    _gameService.onStateChanged = (state) {
      if (!mounted || _currentMode != GameMode.free) return; // ADDED: mounted check

      setState(() {
        switch (state) {
          case GameState.ready:
            _displayText = "Ready to start?";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            _showNewHighScoreAnimation = false;
            break;
          case GameState.countdown:
            _displayText = "Get ready...";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            break;
          case GameState.playing:
            _buttonColor = Colors.green;
            _buttonEnabled = true;
            _updateFreePlayingText();
            break;
          case GameState.ended:
            _displayText = "Game Over! Score: ${_gameService.totalScore}";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            break;
        }
      });
    };

    _gameService.onCountdownUpdate = (value) {
      if (!mounted || _currentMode != GameMode.free) return; // ADDED: mounted check
      setState(() {
        _displayText = value.toString();
      });
    };

    _gameService.onGameTimeUpdate = (currentTime) {
      if (!mounted || _currentMode != GameMode.free) return; // ADDED: mounted check
      setState(() {
        _updateFreePlayingText();
      });
    };

    _gameService.onTapResult = (result) {
      if (!mounted || _currentMode != GameMode.free) return; // ADDED: mounted check
      setState(() {
        // REMOVED the problematic condition check - just update the text
        _updateFreePlayingText();
      });
    };

    _gameService.onNewHighScore = () {
      if (!mounted) return; // ADDED: mounted check
      setState(() {
        _showNewHighScoreAnimation = true;
        // Reset the unlock animation flag if they beat the unlock threshold
        if (_gameService.totalScore >= GameConstants.exactModeUnlockScore) {
          _hasShownUnlockThisSession = false;
        }
      });

      // ADDED: Auto-reset high score animation after 5 seconds
      _highScoreAnimationTimer?.cancel();
      _highScoreAnimationTimer = Timer(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showNewHighScoreAnimation = false;
          });
        }
      });

      _showNewHighScoreDialog();
    };

    _gameService.onExactModeUnlocked = () {
      if (!mounted) return; // ADDED: mounted check
      // Only show unlock animation if we haven't shown it this session
      if (!_hasShownUnlockThisSession) {
        setState(() {
          _showUnlockAnimation = true;
          _hasShownUnlockThisSession = true;
        });
      }
    };
  }

  void _setupExactModeCallbacks() {
    _exactModeService.onStateChanged = (state) {
      if (!mounted || _currentMode != GameMode.exact) return;

      setState(() {
        switch (state) {
          case ExactGameState.ready:
            _displayText = "Precision timing";
            _buttonColor = Colors.purple;
            _buttonEnabled = false;
            break;
          case ExactGameState.countdown:
            _displayText = "Get ready...";
            _buttonColor = Colors.purple;
            _buttonEnabled = false;
            break;
          case ExactGameState.playing:
            _buttonColor = Colors.purple;
            _buttonEnabled = true;
            _updateExactPlayingText();
            break;
          case ExactGameState.levelComplete:
            _displayText = "Level ${_exactModeService.currentLevel} Complete!";
            _buttonColor = Colors.green;
            _buttonEnabled = false;
            _showLevelCompleteDialog = true;
            break;
          case ExactGameState.gameOver:
            _displayText = "Game Over! Level ${_exactModeService.currentLevel}";
            _buttonColor = Colors.purple;
            _buttonEnabled = false;
            break;
        }
      });
    };

    _exactModeService.onCountdownUpdate = (value) {
      if (!mounted || _currentMode != GameMode.exact) return;
      setState(() {
        _displayText = value.toString();
      });
    };

    _exactModeService.onGameTimeUpdate = (currentTime) {
      if (!mounted || _currentMode != GameMode.exact) return;
      setState(() {
        _updateExactPlayingText();
      });
    };

    _exactModeService.onSequenceProgress = (progress) {
      if (!mounted || _currentMode != GameMode.exact) return;
      setState(() {
        _sequenceProgress = progress;
      });
    };

    _exactModeService.onTapResult = (result, isSuccess) {
      if (!mounted || _currentMode != GameMode.exact) return;
      setState(() {
        _displayText = isSuccess
            ? "SUCCESS! ${result.formattedDifference}"
            : "FAILED! ${result.formattedDifference}";
      });

      // Show result dialog on failure - but don't show it here, let onGameFailure handle it
    };

    _exactModeService.onLevelComplete = (level) {
      if (!mounted) return;
      _showLevelCompleteDialogBox(level);
    };

    _exactModeService.onNewHighLevel = (level) {
      if (!mounted) return;
      _showNewHighLevelDialog(level);
    };

    // NEW: Handle game failure with correct level info
    _exactModeService.onGameFailure = (failedLevel, failedSequence) {
      if (!mounted) return;
      if (_exactModeService.lastResult != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          _showExactModeFailedDialog(_exactModeService.lastResult!, failedLevel, failedSequence);
        });
      }
    };
  }

  void _updateFreePlayingText() {
    if (_gameService.state == GameState.playing) {
      double targetTime = _gameService.currentTargetTime / 1000.0;
      double currentTime = _gameService.currentGameTime;
      _displayText = "Target: ${targetTime.toStringAsFixed(2)}s";
    }
  }

  void _updateExactPlayingText() {
    if (_exactModeService.state == ExactGameState.playing) {
      String targetTime = _exactModeService.currentTargetDisplay;
      _displayText = "Hit at ${targetTime}s";
    }
  }

  List<GameModeInfo> _getGameModes() {
    return [
      GameModeInfo(
        mode: GameMode.free,
        name: "Easy Mode",
        description: "1s, 3s, 5s, 7s",
        isUnlocked: true,
      ),
      GameModeInfo(
        mode: GameMode.exact,
        name: "Exact Mode",
        description: "±50ms precision",
        isUnlocked: _exactModeUnlocked,
        unlockRequirement: GameConstants.exactModeUnlockScore,
      ),
    ];
  }

  void _onModeChanged(GameMode mode) {
    setState(() {
      _currentMode = mode;
      _resetCurrentGame();
    });
  }

  void _resetCurrentGame() {
    if (_currentMode == GameMode.free) {
      _gameService.resetToReady();
    } else {
      _exactModeService.resetToReady();
    }
  }

  // NEW: Handle locked mode clicks with spam prevention
  void _handleLockedModeClick() {
    final now = DateTime.now();

    // Check if this is a new spam session (user stopped clicking for a while)
    if (_lastSpamClickTime != null &&
        now.difference(_lastSpamClickTime!) > _spamSessionTimeout) {
      _hasShownSnackbarThisSpamSession = false; // Reset for new spam session
    }

    // Prevent spam clicking
    if (_lastSpamClickTime != null &&
        now.difference(_lastSpamClickTime!) < _spamClickCooldown) {
      return; // Ignore click if within cooldown period
    }
    _lastSpamClickTime = now;

    // Check if user has qualifying score but hasn't unlocked yet
    if (_gameService.totalScore >= GameConstants.exactModeUnlockScore ||
        _gameService.highScore >= GameConstants.exactModeUnlockScore) {

      // Only show unlock animation if we haven't shown it this session
      if (!_hasShownUnlockThisSession) {
        setState(() {
          _showUnlockAnimation = true;
          _hasShownUnlockThisSession = true;
        });
      } else {
        // Show snackbar only once per spam session
        if (!_hasShownSnackbarThisSpamSession) {
          _hasShownSnackbarThisSpamSession = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exact Mode is ready! Use the "Try It" button above.'),
              backgroundColor: Colors.purple,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Show requirement message only once per spam session
      if (!_hasShownSnackbarThisSpamSession) {
        _hasShownSnackbarThisSpamSession = true;
        int needed = GameConstants.exactModeUnlockScore - _gameService.highScore;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Score ${GameConstants.exactModeUnlockScore}+ to unlock! Need $needed more points.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _startCurrentGame() {
    if (_currentMode == GameMode.free) {
      _gameService.startGame();
    } else {
      _exactModeService.startGame();
    }
  }

  void _handleGameTap() {
    if (_currentMode == GameMode.free) {
      _gameService.handleTap();
    } else {
      _exactModeService.handleTap();
    }
  }

  bool _canStartGame() {
    if (_currentMode == GameMode.free) {
      return _gameService.state == GameState.ready;
    } else {
      return _exactModeService.state == ExactGameState.ready;
    }
  }

  void _showExactModeFailedDialog(TapResult result, int failedLevel, int failedSequence) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Level $failedLevel Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 50),
              SizedBox(height: 15),
              Text(
                'Not quite!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Failed on target $failedSequence of $failedLevel',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(result.actualTime / 1000).toStringAsFixed(2)} seconds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Target: ${(result.targetTime / 1000).toStringAsFixed(2)}s',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(width: 12),
                        Text(
                          result.formattedDifference,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Need ±50ms precision',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              if (_exactModeService.highLevel > 0)
                Text('Your best: Level ${_exactModeService.highLevel}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _exactModeService.resetToReady();
              },
            ),
          ],
        );
      },
    );
  }

  void _showNewHighScoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedHighScoreDialog(
          score: _gameService.totalScore,
          shouldAutoClose: _gameService.shouldShowUnlockAnimation,
        );
      },
    );
  }

  void _showLevelCompleteDialogBox(int level) {
    final result = _exactModeService.lastResult;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Level $level Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 15),
              Text(
                'Perfect sequence!',  // UPDATED text
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'You hit all $level targets in order!',  // NEW: Show what was accomplished
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 15),
              if (result != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Final Target',  // UPDATED: Show it was the final target
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${(result.actualTime / 1000).toStringAsFixed(2)} seconds',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: result.difference.abs() <= 50
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Target: ${(result.targetTime / 1000).toStringAsFixed(2)}s',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(width: 12),
                          Text(
                            result.formattedDifference,
                            style: TextStyle(
                              color: result.difference.abs() <= 50
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
              ],
              if (level < _exactModeService.maxLevel)
                Text('Ready for Level ${level + 1}?\n(${level + 1} targets in sequence)')  // NEW: Show next level requirement
              else
                Text('🎉 You completed all levels! 🎉'),
            ],
          ),
          actions: [
            TextButton(
              child: Text(level < _exactModeService.maxLevel ? 'Continue' : 'Finish'),
              onPressed: () {
                Navigator.of(context).pop();
                if (level < _exactModeService.maxLevel) {
                  _exactModeService.nextLevel();
                } else {
                  _exactModeService.resetToReady();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showNewHighLevelDialog(int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.military_tech, color: Colors.purple, size: 30),
              SizedBox(width: 10),
              Text('New Record!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆 Amazing! 🏆',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Level $level',
                style: TextStyle(fontSize: 24, color: Colors.purple),
              ),
              SizedBox(height: 10),
              Text('Your highest level yet!'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Incredible!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Unified Stats Display for both modes
  Widget _buildUnifiedStats() {
    String targetDisplay = "Ready";
    String progressDisplay = "";

    if (_currentMode == GameMode.free) {
      if (_gameService.state == GameState.playing && _gameService.currentTargetIndex < GameConstants.targetTimes.length) {
        double target = GameConstants.targetTimes[_gameService.currentTargetIndex] / 1000.0;
        targetDisplay = "${target.toStringAsFixed(1)}s";
      }
    } else {
      targetDisplay = "${_exactModeService.currentTargetDisplay}s";
      progressDisplay = _sequenceProgress;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: _currentMode == GameMode.free
            ? (_showNewHighScoreAnimation
            ? LinearGradient(colors: [Colors.orange.shade200, Colors.yellow.shade100])
            : LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]))
            : LinearGradient(colors: [Colors.purple.shade50, Colors.purple.shade100]),
        borderRadius: BorderRadius.circular(10),
        border: _showNewHighScoreAnimation ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _currentMode == GameMode.free
            ? [
          _buildStatItem("High", "${_gameService.highScore}", Colors.purple.shade700, false),
          _buildStatItem("Score", "${_gameService.totalScore}",
              _showNewHighScoreAnimation ? Colors.orange.shade700 : Colors.blue.shade700, false),
          _buildStatItem("Target", targetDisplay, Colors.green.shade700, false),
        ]
            : [
          _buildStatItem("Level", "${_exactModeService.currentLevel}/${_exactModeService.maxLevel}", Colors.purple.shade700, false),
          _buildStatItem("Target", targetDisplay, Colors.blue.shade700, false),
          _buildStatItem("Progress", progressDisplay, Colors.orange.shade700, false),
          _buildStatItem("Best", "L${_exactModeService.highLevel}", Colors.green.shade700, false),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isCompact) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reaction Timer'),
        backgroundColor: _currentMode == GameMode.free ? Colors.blue[700] : Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          // ADDED: Statistics button
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatisticsScreen()),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 16),
                  SizedBox(width: 4),
                  Text(
                    _currentMode == GameMode.free
                        ? '${_gameService.highScore}'
                        : 'L${_exactModeService.highLevel}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Mode Selector - Increased height
                Container(
                  margin: EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: _getGameModes()
                        .map((mode) => Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        child: _buildModeSelectorCard(mode),
                      ),
                    ))
                        .toList(),
                  ),
                ),

                // Unified Stats Display
                _buildUnifiedStats(),

                // Display text area - Consistent height for both modes
                Container(
                  height: 35,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentMode == GameMode.free
                        ? Colors.blue[50]
                        : Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _displayText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _currentMode == GameMode.free
                            ? Colors.blue[800]
                            : Colors.purple[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),

                // Countdown or timer display - Consistent height
                if ((_currentMode == GameMode.free &&
                    _gameService.state == GameState.countdown) ||
                    (_currentMode == GameMode.exact &&
                        _exactModeService.state == ExactGameState.countdown))
                  Container(
                    height: 60,
                    child: CountdownWidget(
                      countdownValue: _currentMode == GameMode.free
                          ? _gameService.countdownValue
                          : _exactModeService.countdownValue,
                      isActive: true,
                    ),
                  )
                else if (_currentMode == GameMode.exact &&
                    _exactModeService.state == ExactGameState.playing)
                  Container(
                    height: 60,
                    child: Center(
                      child: Text(
                        "${_exactModeService.currentGameTime.toStringAsFixed(2)}s",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                else if (_currentMode == GameMode.free &&
                      _gameService.state == GameState.playing)
                    Container(
                      height: 60,
                      child: Center(
                        child: Text(
                          "${_gameService.currentGameTimeDisplay}s",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(height: 60),

                // Game Button - Consistent scale
                Transform.scale(
                  scale: 0.85,
                  child: GameButton(
                    enabled: _buttonEnabled,
                    color: _buttonColor,
                    onTap: _handleGameTap,
                  ),
                ),

                SizedBox(height: 10),

                // Results - Only for free mode when ended
                if (_currentMode == GameMode.free &&
                    _gameService.state == GameState.ended)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: ResultsDisplay(
                        results: _gameService.tapResults,
                        totalScore: _gameService.totalScore,
                        showTotal: true,
                      ),
                    ),
                  )
                else
                  Spacer(),

                // Control buttons - Consistent sizing
                Container(
                  margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canStartGame() ? _startCurrentGame : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Start", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _resetCurrentGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Reset", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Unlock animation overlay
            UnlockAnimation(
              isVisible: _showUnlockAnimation,
              onTryIt: () {
                setState(() {
                  _currentMode = GameMode.exact;
                  _exactModeUnlocked = true;
                  _resetCurrentGame();
                });
              },
              onComplete: () {
                setState(() {
                  _showUnlockAnimation = false;
                  _exactModeUnlocked = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelectorCard(GameModeInfo mode) {
    bool isSelected = mode.mode == _currentMode;
    bool isLocked = !mode.isUnlocked;

    return GestureDetector(
      onTap: () {
        if (mode.isUnlocked) {
          _onModeChanged(mode.mode);
        } else {
          _handleLockedModeClick();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            vertical: 20, // INCREASED: From 14 to 24 (added 10 pixels)
            horizontal: 4
        ),
        decoration: BoxDecoration(
          gradient: isLocked
              ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
              : isSelected
              ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
              : LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocked ? Icons.lock :
              mode.mode == GameMode.free ? Icons.play_arrow : Icons.precision_manufacturing,
              color: isLocked ? Colors.grey.shade600 :
              isSelected ? Colors.white : Colors.blue.shade700,
              size: 26, // INCREASED: From 20 to 26
            ),
            SizedBox(height: 4), // Slightly increased spacing
            Text(
              mode.name,
              style: TextStyle(
                fontSize: 14, // INCREASED: From 12 to 14
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey.shade600 :
                isSelected ? Colors.white : Colors.blue.shade800,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              isLocked && mode.unlockRequirement != null
                  ? "${mode.unlockRequirement}+"
                  : mode.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12, // INCREASED: From 10 to 12
                color: isLocked ? Colors.grey.shade600 :
                isSelected ? Colors.white70 : Colors.blue.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameService.dispose();
    _exactModeService.dispose();
    _highScoreAnimationTimer?.cancel();
    super.dispose();
  }
}

class _AnimatedHighScoreDialog extends StatefulWidget {
  final int score;
  final bool shouldAutoClose;

  const _AnimatedHighScoreDialog({
    required this.score,
    required this.shouldAutoClose,
  });

  @override
  _AnimatedHighScoreDialogState createState() => _AnimatedHighScoreDialogState();
}

class _AnimatedHighScoreDialogState extends State<_AnimatedHighScoreDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _controller.forward();

    if (widget.shouldAutoClose) {
      _scheduleAutoClose();
    }
  }

  void _scheduleAutoClose() {
    Future.delayed(Duration(milliseconds: 1800), () {
      if (mounted) {
        _controller.reverse();
      }
    });

    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text('New High Score!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Congratulations! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Score: ${widget.score}',
              style: TextStyle(fontSize: 24, color: Colors.orange),
            ),
            SizedBox(height: 10),
            Text('You beat your previous best!'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Awesome!'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
