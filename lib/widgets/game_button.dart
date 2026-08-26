import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameButton extends StatefulWidget {
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  const GameButton({
    Key? key,
    required this.enabled,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  _GameButtonState createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scale;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 170),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _handleTap() {
    if (!widget.enabled || _isProcessing) return;

    _isProcessing = true;

    HapticFeedback.lightImpact();

    widget.onTap?.call();

    _animationController.forward().then((_) {
      if (!mounted) return;

      _animationController.reverse().then((_) {
        if (mounted) {
          _isProcessing = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ElevatedButton(
        onPressed: widget.enabled ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(40),
          elevation: 8,
        ),
        child: const Icon(
          Icons.touch_app,
          size: 60,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}