import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/cosmetics.dart';
import '../models/profile_model.dart';
import '../utils/constants.dart';

/// A player's profile card: banner, framed avatar, name, title and lifetime
/// stats. [compact] drops the stats row for tighter spots like the
/// leaderboard header.
class ProfileCard extends StatelessWidget {
  final PlayerProfile profile;
  final bool compact;

  /// Shown on the right, e.g. an "Edit" button.
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.profile,
    this.compact = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final banner = profile.banner;
    final hasBanner = banner.colors.isNotEmpty;
    final textColor = hasBanner ? Colors.white : onSurface;
    final radius = BorderRadius.circular(compact ? 18 : 24);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: hasBanner ? null : onSurface.withOpacity(0.07),
          gradient: hasBanner
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: banner.colors,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              if (banner.pattern != null)
                Positioned.fill(child: BannerPattern(emoji: banner.pattern!)),
              Padding(
                padding: EdgeInsets.all(compact ? 12 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        FramedAvatar(
                          profile: profile,
                          size: compact ? 52 : 76,
                        ),
                        SizedBox(width: compact ? 12 : 16),
                        Expanded(child: _buildIdentity(textColor)),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 16),
                      _buildStats(textColor),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentity(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 17 : 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        if (profile.title != null) ...[
          const SizedBox(height: 4),
          TitleBadge(title: profile.title!, small: compact),
        ],
        if (profile.boost > 0) ...[
          const SizedBox(height: 4),
          Text(
            "${profile.frame.name} frame • ${profile.frame.boostLabel} "
            "${GameConstants.currencyName}",
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: textColor.withOpacity(0.75),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(Color textColor) {
    Widget stat(String emoji, String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              "$emoji $value",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
                color: textColor.withOpacity(0.65),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          stat(
            GameConstants.currencyEmoji,
            "${profile.lifetimeTicks}",
            "TICKS EARNED",
          ),
          stat("🎯", "${profile.perfectTaps}", "PERFECT TAPS"),
          stat("🔥", "${profile.bestWinStreak}", "BEST STREAK"),
        ],
      ),
    );
  }
}

/// The equipped title as a small rarity-colored pill.
class TitleBadge extends StatelessWidget {
  final String title;
  final bool small;

  const TitleBadge({super.key, required this.title, this.small = false});

  @override
  Widget build(BuildContext context) {
    PlayerTitle? item;
    for (final candidate in PlayerTitle.all) {
      if (candidate.name == title) item = candidate;
    }
    final color = item?.rarity.color ?? Colors.amber;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        "🏷️ $title",
        style: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

/// The player's picture (uploaded photo, else pet emoji, else name initial)
/// encased in the equipped frame. Decorated frames shrink the picture a
/// little so their flames, stars, crowns etc. fit inside [size].
class FramedAvatar extends StatefulWidget {
  final PlayerProfile profile;
  final double size;

  const FramedAvatar({super.key, required this.profile, this.size = 76});

  @override
  State<FramedAvatar> createState() => _FramedAvatarState();
}

class _FramedAvatarState extends State<FramedAvatar>
    with SingleTickerProviderStateMixin {
  // One loop drives the spin, the orbit and the pulse.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    _updateLoop();
  }

  @override
  void didUpdateWidget(FramedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateLoop();
  }

  void _updateLoop() {
    if (widget.profile.frame.isMoving) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final frame = widget.profile.frame;
    final size = widget.size;

    // Room around the ring for decorations.
    final margin = frame.hasDecorations ? size * 0.14 : 0.0;
    final ringSize = size - margin * 2;
    final ringWidth = frame.colors.isEmpty ? 2.5 : ringSize * 0.09;
    final ornamentSize = size * 0.15;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) {
          final t = _loop.value;
          // Two breaths per loop.
          final glow =
              frame.pulse ? 0.35 + 0.35 * (sin(t * 4 * pi) + 1) / 2 : 0.5;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // The ring.
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      frame.colors.isEmpty ? onSurface.withOpacity(0.3) : null,
                  gradient: frame.colors.isEmpty
                      ? null
                      : SweepGradient(
                          colors: frame.colors,
                          transform: GradientRotation(
                            frame.animated ? t * 2 * pi * 1.5 : 0,
                          ),
                        ),
                  boxShadow: frame.colors.isEmpty
                      ? null
                      : [
                          BoxShadow(
                            color: frame.colors.first.withOpacity(glow),
                            blurRadius: size * (frame.pulse ? 0.25 : 0.15),
                            spreadRadius: frame.pulse ? size * 0.02 * glow : 0,
                          ),
                        ],
                ),
              ),
              // The picture.
              Container(
                width: ringSize - ringWidth * 2,
                height: ringSize - ringWidth * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E1E2A),
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: _buildPicture(ringSize),
              ),
              // Orbiting decorations.
              if (frame.orbit != null)
                for (var i = 0; i < frame.orbitCount; i++)
                  _place(
                    angle: t * 2 * pi + i * 2 * pi / frame.orbitCount,
                    radius: ringSize / 2 + margin * 0.15,
                    child: Text(
                      frame.orbit!,
                      style: TextStyle(fontSize: ornamentSize),
                    ),
                  ),
              if (frame.bottom != null)
                _place(
                  angle: pi / 2,
                  radius: ringSize / 2,
                  child: Text(
                    frame.bottom!,
                    style: TextStyle(fontSize: ornamentSize * 1.4),
                  ),
                ),
              if (frame.topper != null)
                _place(
                  angle: -pi / 2,
                  radius: ringSize / 2 + margin * 0.2,
                  child: Text(
                    frame.topper!,
                    style: TextStyle(fontSize: ornamentSize * 1.7),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Centers [child] at [angle] (0 = right, clockwise) on a circle of
  /// [radius] around the middle.
  Widget _place({
    required double angle,
    required double radius,
    required Widget child,
  }) {
    return Transform.translate(
      offset: Offset(cos(angle) * radius, sin(angle) * radius),
      child: child,
    );
  }

  Widget _buildPicture(double ringSize) {
    final photo = widget.profile.avatarPhotoPath;
    final emoji = widget.profile.avatarEmoji;

    Widget fallback() {
      return Text(
        emoji ?? widget.profile.initial,
        style: TextStyle(
          fontSize: ringSize * (emoji == null ? 0.4 : 0.48),
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
    }

    if (photo == null) return fallback();

    return Image.file(
      File(photo),
      width: ringSize,
      height: ringSize,
      fit: BoxFit.cover,
      // Falls back to the emoji if the file is unreadable.
      errorBuilder: (_, __, ___) => fallback(),
    );
  }
}

/// Faint repeating emoji over a banner.
class BannerPattern extends StatelessWidget {
  final String emoji;

  final double size;
  final int count;

  const BannerPattern({
    super.key,
    required this.emoji,
    this.size = 16,
    this.count = 40,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.18,
        child: Wrap(
          clipBehavior: Clip.hardEdge,
          spacing: size * 1.1,
          runSpacing: size * 0.9,
          children: List.generate(
            count,
            (_) => Text(emoji, style: TextStyle(fontSize: size)),
          ),
        ),
      ),
    );
  }
}
