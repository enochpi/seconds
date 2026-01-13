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

      _showNewHighScoreDialog();
    };
  }

  void _updatePlayingText() {
    if (_gameService.state == GameState.playing) {
      double targetTime = _gameService.currentTargetTime / 1000.0;
      _displayText = "Target: ${targetTime.toStringAsFixed(2)}s";
    }
  }

  void _showNewHighScoreDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
                'Score: ${_gameService.totalScore}',
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
        );
      },
    );
  }

  Widget _buildStats() {
    String targetDisplay = "Ready";

    if (_gameService.state == GameState.playing &&
        _gameService.currentTargetIndex < GameConstants.targetTimes.length) {
      double target = GameConstants.targetTimes[_gameService.currentTargetIndex] / 1000.0;
      targetDisplay = "${target.toStringAsFixed(1)}s";
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: _showNewHighScoreAnimation
            ? LinearGradient(colors: [Colors.orange.shade200, Colors.yellow.shade100])
            : LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
        borderRadius: BorderRadius.circular(10),
        border: _showNewHighScoreAnimation ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("High", "${_gameService.highScore}", Colors.purple.shade700),
          _buildStatItem("Score", "${_gameService.totalScore}",
              _showNewHighScoreAnimation ? Colors.orange.shade700 : Colors.blue.shade700),
          _buildStatItem("Target", targetDisplay, Colors.green.shade700),
        ],
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

            Container(
              height: 35,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),

            if (_gameService.state == GameState.countdown)
              Container(
                height: 60,
                child: CountdownWidget(
                  countdownValue: _gameService.countdownValue,
                  isActive: true,
                ),
              )
            else if (_gameService.state == GameState.playing)
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

            Transform.scale(
              scale: 0.85,
              child: GameButton(
                enabled: _buttonEnabled,
                color: _buttonColor,
                onTap: _gameService.handleTap,
              ),
            ),

            SizedBox(height: 10),

            if (_gameService.state == GameState.ended)
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

            Container(
              margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _gameService.state == GameState.ready
                          ? _gameService.startGame
                          : null,
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
                      onPressed: _gameService.resetToReady,
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