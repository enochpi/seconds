import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/cosmetics_service.dart';
import '../services/storage_service.dart';
import 'cosmetic_widgets.dart';

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

    if (StorageService.getHapticsEnabled()) {
      HapticFeedback.lightImpact();
    }

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
      child: GestureDetector(
        onTap: widget.enabled ? _handleTap : null,
        child: SkinnedButtonFace(
          skin: CosmeticsService.button,
          defaultColor: widget.color,
          size: 140,
          enabled: widget.enabled,
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
