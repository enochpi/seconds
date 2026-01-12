import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class UnlockAnimation extends StatefulWidget {
  final bool isVisible;
  final VoidCallback onComplete;
  final VoidCallback? onTryIt; // Add callback for try it button

  const UnlockAnimation({
    Key? key,
    required this.isVisible,
    required this.onComplete,
    this.onTryIt,
  }) : super(key: key);

  @override
  _UnlockAnimationState createState() => _UnlockAnimationState();
}

class _UnlockAnimationState extends State<UnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _lockController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late ConfettiController _confetti;

  late Animation<double> _lockRotation;
  late Animation<double> _lockScale;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showLockAnimation = false;

  @override
  void initState() {
    super.initState();

    // Lock animation controller (for the lock icon)
    _lockController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade controller (for the background and text)
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Bounce controller (for the final bounce out effect)
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Confetti controller - longer duration
    _confetti = ConfettiController(duration: Duration(seconds: 10));

    // Lock animations
    _lockRotation = Tween<double>(begin: 0, end: 2).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.elasticOut),
    );

    _lockScale = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.elasticOut),
    );

    // Fade animation for background and text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Bounce animation for final exit
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Slide animation for final exit
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(0, -0.5)).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInBack),
    );

    if (widget.isVisible) {
      _startAnimation();
    }
  }

  void _startAnimation() async {
    // Step 1: Start confetti immediately
    _confetti.play();

    // Step 2: Wait 0.5 seconds then show lock animation
    await Future.delayed(Duration(milliseconds: 500));

    // Step 3: Fade in the lock animation background
    setState(() {
      _showLockAnimation = true;
    });
    _fadeController.forward();

    // Step 4: Lock appears normally (no zoom in animation)
    await Future.delayed(Duration(milliseconds: 300));

    // Animation stays until user interacts or times out
  }

  @override
  void didUpdateWidget(UnlockAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _lockController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return Container();

    return Positioned.fill(
      child: Stack(
        children: [
          // Confetti - always visible when animation is running
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: 1.57, // Down
              numberOfParticles: 80,
              gravity: 0.3,
              colors: [
                Colors.orange,
                Colors.yellow,
                Color(0xFFFFD700),
                Colors.amber,
                Colors.deepOrange,
                Color(0xFFD4AF37), // Gold color
              ],
            ),
          ),

          // Background overlay and lock animation (appears after delay)
          if (_showLockAnimation)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black54.withOpacity(_fadeAnimation.value * 0.8),
                  child: Center(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AnimatedBuilder(
                        animation: _bounceAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _bounceAnimation.value,
                            child: Opacity(
                              opacity: _fadeAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Lock icon with animations
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFFD700).withOpacity(0.9),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _lockController,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _lockRotation.value,
                                          child: Icon(
                                            Icons.lock_open,
                                            size: 80,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 30),

                                  // Title text with glow effect
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.black.withOpacity(0.3),
                                      border: Border.all(color: Color(0xFFFFD700), width: 2),
                                    ),
                                    child: Text(
                                      "🎉 EXACT MODE UNLOCKED! 🎉",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Color(0xFFFFD700),
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  SizedBox(height: 15),

                                  // Subtitle
                                  Text(
                                    "Challenge yourself with precision timing!",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  SizedBox(height: 25),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Try It button
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _bounceController.forward();
                                          widget.onTryIt?.call();
                                          widget.onComplete();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFFD700),
                                          foregroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          elevation: 5,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.play_arrow, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Try It!",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Later button
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _bounceController.forward();
                                          widget.onComplete();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade600,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(25),
                                          ),
                                          elevation: 3,
                                        ),
                                        child: Text(
                                          "Later",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}