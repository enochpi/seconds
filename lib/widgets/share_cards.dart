import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../services/season_service.dart';
import '../utils/constants.dart';
import 'emoji_badge.dart';
import 'profile_card_widget.dart';

/// A 1080x1920 (9:16) card that fits Instagram/TikTok Stories, Reels and
/// Shorts without cropping. Uses the player's banner as the background
/// unless [colors] is given. Content is scaled down if it doesn't fit.
class StoryCard extends StatelessWidget {
  final PlayerProfile profile;
  final List<Color>? colors;
  final Color accent;
  final List<Widget> children;

  const StoryCard({
    super.key,
    required this.profile,
    required this.accent,
    required this.children,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final banner = profile.banner;
    final background = colors ??
        (banner.colors.isNotEmpty
            ? banner.colors
            : const [Color(0xFF151515), Color(0xFF0D0D0D)]);
    final pattern = colors == null ? banner.pattern : null;

    return Container(
      width: 1080,
      height: 1920,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: accent.withOpacity(0.6), width: 4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: background,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: Stack(
          children: [
            if (pattern != null)
              Positioned.fill(
                child: BannerPattern(emoji: pattern, size: 54, count: 140),
              ),
            // Keeps white text readable on bright banners.
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.28)),
            ),
            Padding(
              padding: const EdgeInsets.all(64),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 952,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "7 SECONDS" at the top of every card.
class StoryWordmark extends StatelessWidget {
  const StoryWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      "7 SECONDS",
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: 8,
      ),
    );
  }
}

/// Download nudge at the bottom of every card.
class StoryFooter extends StatelessWidget {
  final String callToAction;

  const StoryFooter({super.key, this.callToAction = "Can you beat this?"});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 952,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            callToAction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Play 7 Seconds  •  #7SecondsGame",
          style: TextStyle(
            fontSize: 28,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Framed avatar, name and title badge, sized for a story card.
class StoryProfileHeader extends StatelessWidget {
  final PlayerProfile profile;
  final double avatarSize;

  const StoryProfileHeader({
    super.key,
    required this.profile,
    this.avatarSize = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FramedAvatar(profile: profile, size: avatarSize),
        const SizedBox(height: 22),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (profile.title != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: FittedBox(child: TitleBadge(title: profile.title!)),
          ),
        ],
      ],
    );
  }
}

/// "Beat me" card: shows how close the player got and dares friends to do
/// better.
class ChallengeShareCard extends StatelessWidget {
  final PlayerProfile profile;
  final String line;
  final String bigText;
  final String bigLabel;
  final String detail;

  const ChallengeShareCard({
    super.key,
    required this.profile,
    required this.line,
    required this.bigText,
    required this.bigLabel,
    required this.detail,
  });

  /// Rotating dares. [ms] is how far off the closest tap was, if known.
  static List<String> lines(int? ms) => ms != null
      ? [
          "I was ${ms}ms off. Can you get closer?",
          "Bet you can't beat ${ms}ms.",
          "${ms}ms from perfect. Your turn.",
          "7.00 seconds. Sounds easy. Prove it.",
        ]
      : [
          "Beat my score. Should be easy… right?",
          "7.00 seconds. Sounds easy. Prove it.",
          "Think you've got better timing than me?",
        ];

  @override
  Widget build(BuildContext context) {
    return StoryCard(
      profile: profile,
      accent: Colors.cyanAccent,
      colors: const [Color(0xFF020B2E), Color(0xFF0B3D91), Color(0xFF4A148C)],
      children: [
        const StoryWordmark(),
        const SizedBox(height: 50),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.cyanAccent, width: 3),
          ),
          child: const Text(
            "🎯 CHALLENGE",
            style: TextStyle(
              fontSize: 44,
              letterSpacing: 4,
              fontWeight: FontWeight.w900,
              color: Colors.cyanAccent,
            ),
          ),
        ),
        const SizedBox(height: 50),
        StoryProfileHeader(profile: profile, avatarSize: 200),
        const SizedBox(height: 50),
        Text(
          line,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 66,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 50),
        Text(
          bigText,
          style: TextStyle(
            fontSize: 210,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Colors.cyanAccent,
            shadows: [
              Shadow(
                color: Colors.cyanAccent.withOpacity(0.8),
                blurRadius: 60,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          bigLabel,
          style: TextStyle(
            fontSize: 38,
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 60),
        const StoryFooter(callToAction: "Your turn 👀"),
      ],
    );
  }
}

/// 2nd, 1st and 3rd place blocks with avatars on top. [scale] is 1 for a
/// story card; the in-app dialog uses a smaller one.
class PodiumView extends StatelessWidget {
  final List<PodiumSpot> topThree;
  final PlayerProfile profile;
  final double scale;

  const PodiumView({
    super.key,
    required this.topThree,
    required this.profile,
    this.scale = 1,
  });

  static const _medals = ["🥇", "🥈", "🥉"];
  static const _colors = [Colors.amber, Color(0xFFCFD8DC), Color(0xFFCD7F32)];
  static const _heights = [420.0, 300.0, 220.0];

  Widget _buildSpot(int index) {
    if (index >= topThree.length) {
      return SizedBox(width: 280 * scale);
    }

    final spot = topThree[index];
    final color = _colors[index];

    return SizedBox(
      width: 280 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spot.isPlayer)
            FramedAvatar(profile: profile, size: 170 * scale)
          else
            EmojiBadge(
              emoji: "🤖",
              color: color,
              size: 150 * scale,
              borderWidth: 4 * scale,
            ),
          SizedBox(height: 14 * scale),
          Text(
            spot.isPlayer ? "YOU" : spot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: spot.isPlayer ? Colors.amber : Colors.white,
              fontSize: 38 * scale,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            "${spot.rounds} rounds",
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 28 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14 * scale),
          Container(
            width: 250 * scale,
            height: _heights[index] * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24 * scale),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.35)],
              ),
              boxShadow: spot.isPlayer
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.7),
                        blurRadius: 50 * scale,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 18 * scale),
            child: Text(
              _medals[index],
              style: TextStyle(fontSize: 90 * scale),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [_buildSpot(1), _buildSpot(0), _buildSpot(2)],
    );
  }
}

/// "I won the season" card.
class PodiumShareCard extends StatelessWidget {
  final PlayerProfile profile;
  final List<PodiumSpot> topThree;
  final int placement;
  final int prize;

  const PodiumShareCard({
    super.key,
    required this.profile,
    required this.topThree,
    required this.placement,
    required this.prize,
  });

  static String placeLabel(int placement) {
    switch (placement) {
      case 1:
        return "1ST PLACE";
      case 2:
        return "2ND PLACE";
      case 3:
        return "3RD PLACE";
      default:
        return "#$placement";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoryCard(
      profile: profile,
      accent: Colors.amber,
      children: [
        const StoryWordmark(),
        const SizedBox(height: 20),
        Text(
          "${GameConstants.modeEmoji(GameMode.endless)} ENDLESS SEASON",
          style: TextStyle(
            fontSize: 34,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          placeLabel(placement),
          style: TextStyle(
            fontSize: 130,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Colors.amber,
            shadows: [
              Shadow(
                color: Colors.amber.withOpacity(0.8),
                blurRadius: 60,
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        PodiumView(topThree: topThree, profile: profile),
        const SizedBox(height: 50),
        Text(
          profile.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 60,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (profile.title != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: FittedBox(child: TitleBadge(title: profile.title!)),
          ),
        ],
        const SizedBox(height: 36),
        Text(
          "Won ${GameConstants.currencyEmoji} $prize ${GameConstants.currencyName}",
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Colors.lightGreenAccent,
          ),
        ),
        const SizedBox(height: 60),
        const StoryFooter(callToAction: "Think you can take my spot? 👑"),
      ],
    );
  }
}
