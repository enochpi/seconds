import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../models/tap_result.dart';
import '../services/game_service.dart';
import '../utils/constants.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/game_button.dart';
import '../widgets/results_display.dart';
import 'statistics_screen.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameService _gameService;

  String _displayText = "Ready to start?";
  Color _buttonColor = Colors.blue;
  bool _buttonEnabled = false;
  bool _showNewHighScoreAnimation = false;
  Timer? _highScoreAnimationTimer;

  @override
  void initState() {
    super.initState();
    _gameService = GameService();
    _setupGameServiceCallbacks();
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
            break;
          case GameState.countdown:
            _displayText = "Get ready...";
            _buttonColor = Colors.blue;
            _buttonEnabled = false;
            break;
          case GameState.playing:
            _buttonColor = Colors.green;
            _buttonEnabled = true;
            _updatePlayingText();
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
      if (!mounted) return;
      setState(() {
        _displayText = value.toString();
      });
    };

    _gameService.onGameTimeUpdate = (currentTime) {
      if (!mounted) return;
      setState(() {
        _updatePlayingText();
      });
    };

    _gameService.onTapResult = (result) {
      if (!mounted) return;
      setState(() {
        _updatePlayingText();
      });
    };

    _gameService.onNewHighScore = () {
      if (!mounted) return;
      setState(() {
        _showNewHighScoreAnimation = true;
      });

      _highScoreAnimationTimer?.cancel();
      _highScoreAnimationTimer = Timer(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showNewHighScoreAnimation = false;
          });
        }
      });
    };
  }

  void _updatePlayingText() {
    if (_gameService.state == GameState.playing) {
      double targetTime = _gameService.currentTargetTime / 1000.0;
      _displayText = "Target: ${targetTime.toStringAsFixed(2)}s";
    }
  }

  Widget _buildStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: _showNewHighScoreAnimation
            ? LinearGradient(colors: [Colors.orange.shade200, Colors.yellow.shade100])
            : LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
        borderRadius: BorderRadius.circular(10),
        border: _showNewHighScoreAnimation ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Score",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "${_gameService.totalScore}",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _showNewHighScoreAnimation ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
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
                    '${_gameService.highScore}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStats(),

            if (_gameService.state == GameState.countdown)
              Container(
                height: 160,
                child: CountdownWidget(
                  countdownValue: _gameService.countdownValue,
                  isActive: true,
                ),
              )
            else if (_gameService.state == GameState.playing)
              Container(
                height: 160,
                child: Center(
                  child: Text(
                    "${_gameService.currentGameTimeDisplay}s",
                    style: TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: 160),

            Container(
              height: 200,  // ← Add container with height
              child: Stack(
                children: [
                  // Centered button
                  Center(
                    child: Transform.scale(
                      scale: 1.2,
                      child: GameButton(
                        enabled: _buttonEnabled,
                        color: _buttonColor,
                        onTap: _gameService.handleTap,
                      ),
                    ),
                  ),
                  // Results on the right edge
                  Positioned(
                    right: 16,
                    top: 0,  // ← Add this to align from top
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: _gameService.tapResults
                          .map((result) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          "${(result.actualTime / 1000).toStringAsFixed(3)}s",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: result.isAccurate
                                ? Colors.green
                                : result.isOkay
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
              Spacer(),

            Container(
              margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Center(
                child: SizedBox(
                  width: 200,  // ← Button width
                  child: ElevatedButton(
                    onPressed: () {
                      if (_gameService.state == GameState.ended ||
                          _gameService.state == GameState.playing) {
                        _gameService.resetToReady();
                      }
                      _gameService.startGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                        _gameService.state == GameState.playing ? "Restart" : "Start",
                        style: TextStyle(fontSize: 20)
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameService.dispose();
    _highScoreAnimationTimer?.cancel();
    super.dispose();
  }
}