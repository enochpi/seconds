import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  final int countdownValue;
  final bool isActive;

  /// Shown instead of the number, e.g. "GO!".
  final String? text;
  final double size;
  final Color color;

  const CountdownWidget({
    Key? key,
    required this.countdownValue,
    required this.isActive,
    this.text,
    this.size = 160,
    this.color = Colors.orange,
  }) : super(key: key);

  @override
  _CountdownWidgetState createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.countdownValue != oldWidget.countdownValue && widget.isActive) {
      _animationController.reset();
      _animationController.forward();
    }

    if (widget.isActive && !oldWidget.isActive) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.75,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    widget.text ?? widget.countdownValue.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: widget.color,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: widget.color.withOpacity(0.6),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
