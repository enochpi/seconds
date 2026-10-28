import 'package:flutter/material.dart';

class EmojiBadge extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  final double? emojiSize;
  final double borderWidth;
  final bool glow;
  final double opacity;

  const EmojiBadge({
    Key? key,
    required this.emoji,
    required this.color,
    this.size = 64,
    this.emojiSize,
    this.borderWidth = 2,
    this.glow = true,
    this.opacity = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.35),
              color.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.6),
            width: borderWidth,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.45),
                    blurRadius: size * 0.22,
                    spreadRadius: size * 0.015,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: emojiSize ?? size * 0.5),
          ),
        ),
      ),
    );
  }
}
