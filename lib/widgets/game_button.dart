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
  bool _isProcessing = false; // ADDED: Prevents double-tapping

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // ADDED: Prevent double-tapping and check if already processing
    if (!widget.enabled || _isProcessing) return;

    // ADDED: Mark as processing to prevent additional taps
    _isProcessing = true;

    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse().then((_) {
        // ADDED: Reset processing flag after animation completes
        _isProcessing = false;
      });
    });

    // Call the tap callback immediately (don't wait for animation)
    widget.onTap?.call();
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
          shape: CircleBorder(),
          padding: EdgeInsets.all(40),
          elevation: 8,
        ),
        child: Icon(
          Icons.touch_app,
          size: 60,
        ),
      ),
    );
  }
}