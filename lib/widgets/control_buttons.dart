import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool canStart;
  final VoidCallback? onStart;
  final VoidCallback? onReset;

  const ControlButtons({
    Key? key,
    required this.canStart,
    this.onStart,
    this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: canStart ? onStart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text("Start Game"),
        ),
        ElevatedButton(
          onPressed: onReset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text("Reset"),
        ),
      ],
    );
  }
}