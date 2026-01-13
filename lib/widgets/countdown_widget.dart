import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  final int countdownValue;
  final bool isActive;

  const CountdownWidget({
    Key? key,
    required this.countdownValue,
    required this.isActive,
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
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when countdown value changes
    if (widget.countdownValue != oldWidget.countdownValue && widget.isActive) {
      _animationController.reset();
      _animationController.forward();
    }

    // Start animation when countdown becomes active
    if (widget.isActive && !oldWidget.isActive) {
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
    if (!widget.isActive) return Container();

    return Container(
      padding: EdgeInsets.all(40),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                // Fixed size container to prevent layout shifts
                width: 120,
                height: 80,
                child: Center(
                  child: Text(
                    // Show the actual countdown value (3, 2, 1) - no "GO!"
                    widget.countdownValue.toString(),
                    style: TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}