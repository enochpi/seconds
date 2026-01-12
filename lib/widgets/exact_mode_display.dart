import 'package:flutter/material.dart';
import '../models/tap_result.dart';

class ExactModeDisplay extends StatelessWidget {
  final int currentLevel;
  final int highLevel;
  final int gamesPlayed;
  final String targetTime;
  final TapResult? lastResult;
  final bool showResult;
  final int maxLevel;

  const ExactModeDisplay({
    Key? key,
    required this.currentLevel,
    required this.highLevel,
    required this.gamesPlayed,
    required this.targetTime,
    this.lastResult,
    this.showResult = false,
    required this.maxLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.purple.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.precision_manufacturing,
                  color: Colors.purple.shade700, size: 24),
              SizedBox(width: 8),
              Text(
                "Exact Mode",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Current level and target
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Level:", style: _labelStyle()),
                  Text("$currentLevel / $maxLevel", style: _valueStyle(Colors.purple.shade700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Target:", style: _labelStyle()),
                  Text("${targetTime}s", style: _valueStyle(Colors.blue.shade700)),
                ],
              ),
            ],
          ),

          SizedBox(height: 12),

          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("High Level:", style: _labelStyle()),
                  Text("$highLevel", style: _valueStyle(Colors.green.shade700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Games:", style: _labelStyle()),
                  Text("$gamesPlayed", style: _valueStyle(Colors.orange.shade700)),
                ],
              ),
            ],
          ),

          // Last result
          if (showResult && lastResult != null) ...[
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Last Result:", style: _labelStyle()),
                Row(
                  children: [
                    Text(
                      lastResult!.formattedDifference,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: lastResult!.difference.abs() <= 50
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      lastResult!.difference.abs() <= 50
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: lastResult!.difference.abs() <= 50
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _labelStyle() {
    return TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  }

  TextStyle _valueStyle(Color color) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }
}