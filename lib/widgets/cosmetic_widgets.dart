import 'dart:math';

import 'package:flutter/material.dart';

import '../models/cosmetics.dart';

/// Text drawn in a [TimerStyle]: solid or gradient color, optional glow.
/// The default style uses [defaultColor].
class StyledTimerText extends StatelessWidget {
  final String text;
  final TimerStyle style;
  final double fontSize;
  final Color defaultColor;
  final List<FontFeature>? fontFeatures;

  const StyledTimerText({
    Key? key,
    required this.text,
    required this.style,
    required this.fontSize,
    required this.defaultColor,
    this.fontFeatures,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = style.colors.isEmpty ? [defaultColor] : style.colors;
    final isGradient = colors.length > 1;

    final textWidget = Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        // A gradient is painted over white text by the ShaderMask below.
        color: isGradient ? Colors.white : colors.first,
        fontFeatures: fontFeatures,
        shadows: style.glow
            ? [
                Shadow(color: colors.last.withOpacity(0.8), blurRadius: 18),
                Shadow(color: colors.first.withOpacity(0.6), blurRadius: 6),
              ]
            : null,
      ),
    );

    if (!isGradient) return textWidget;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: textWidget,
    );
  }
}

/// Fills its area with a [BackgroundStyle]. The default style draws nothing
/// so the normal theme background shows through.
class CosmeticBackground extends StatelessWidget {
  final BackgroundStyle style;
  final Widget child;
  final BorderRadius? borderRadius;

  const CosmeticBackground({
    Key? key,
    required this.style,
    required this.child,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (style.colors.isEmpty) return child;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style.colors,
        ),
      ),
      child: style.grid
          ? CustomPaint(painter: _GridPainter(), child: child)
          : child,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.18)
      ..strokeWidth = 1;

    const spacing = 32.0;

    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The round tap button drawn in a [ButtonSkin]. The default skin uses
/// [defaultColor] (the game's state color).
class SkinnedButtonFace extends StatelessWidget {
  final ButtonSkin skin;
  final Color defaultColor;
  final double size;
  final bool enabled;

  const SkinnedButtonFace({
    Key? key,
    required this.skin,
    required this.defaultColor,
    required this.size,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors =
        skin.colors.isEmpty ? [defaultColor, defaultColor] : skin.colors;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: size * 0.02,
          ),
          boxShadow: [
            BoxShadow(
              color: skin.colors.isEmpty
                  ? Colors.black26
                  : skin.glow.withOpacity(enabled ? 0.6 : 0.25),
              blurRadius: size * 0.18,
              spreadRadius: size * 0.02,
            ),
          ],
        ),
        child: Center(
          child: skin.emoji == null
              ? Icon(Icons.touch_app, size: size * 0.43, color: Colors.white)
              : Text(skin.emoji!, style: TextStyle(fontSize: size * 0.4)),
        ),
      ),
    );
  }
}

/// Bursts emoji particles outward from its center. Call [TapBurstState.burst]
/// through a GlobalKey on every tap.
class TapBurst extends StatefulWidget {
  const TapBurst({Key? key}) : super(key: key);

  @override
  TapBurstState createState() => TapBurstState();
}

class _Particle {
  final String emoji;
  final double angle;
  final double distance;
  final double size;

  const _Particle(this.emoji, this.angle, this.distance, this.size);
}

class _Burst {
  final AnimationController controller;
  final List<_Particle> particles;

  _Burst(this.controller, this.particles);
}

class TapBurstState extends State<TapBurst> with TickerProviderStateMixin {
  static const int _particlesPerBurst = 10;

  final List<_Burst> _bursts = [];
  final Random _random = Random();

  void burst(List<String> emojis) {
    if (emojis.isEmpty) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final particles = List.generate(_particlesPerBurst, (i) {
      return _Particle(
        emojis[_random.nextInt(emojis.length)],
        (i / _particlesPerBurst) * 2 * pi + _random.nextDouble() * 0.5,
        90 + _random.nextDouble() * 70,
        18 + _random.nextDouble() * 14,
      );
    });

    final newBurst = _Burst(controller, particles);
    setState(() => _bursts.add(newBurst));

    controller.forward().whenComplete(() {
      controller.dispose();
      if (mounted) setState(() => _bursts.remove(newBurst));
    });
  }

  @override
  void dispose() {
    for (final b in _bursts) {
      b.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A 1x1 anchor; particles draw outside it and never block taps.
    return IgnorePointer(
      child: SizedBox(
        width: 1,
        height: 1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            for (final b in _bursts)
              for (final particle in b.particles)
                AnimatedBuilder(
                  animation: b.controller,
                  builder: (context, child) {
                    final t = Curves.easeOut.transform(b.controller.value);

                    return Transform.translate(
                      offset: Offset(
                        cos(particle.angle) * particle.distance * t,
                        sin(particle.angle) * particle.distance * t,
                      ),
                      child: Opacity(
                          opacity: 1 - b.controller.value, child: child),
                    );
                  },
                  child: Text(
                    particle.emoji,
                    style: TextStyle(fontSize: particle.size),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
