import 'package:flutter/material.dart';
import '../models/tap_result.dart';
import '../utils/constants.dart';

class ResultsDisplay extends StatelessWidget {
  final List<TapResult> results;
  final int totalScore;
  final bool showTotal;

  const ResultsDisplay({
    Key? key,
    required this.results,
    required this.totalScore,
    this.showTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return Container();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Results:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 10),
          ...results.map((result) => _buildResultRow(result)).toList(),
          if (showTotal) ...[
            Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Score:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$totalScore",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(TapResult result) {
    Color diffColor = result.isAccurate
        ? GameConstants.accurateColor
        : result.isOkay
        ? GameConstants.okayColor
        : GameConstants.inaccurateColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: diffColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(
            "${(result.actualTime / 1000).toStringAsFixed(3)}s",
            style: TextStyle(
              fontSize: 18,
              color: diffColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}