import 'package:flutter/material.dart';

enum CosmeticType {
  button,
  timer,
  background,
  font,
  tapEffect,
  title,
  frame,
  banner,
}

/// How rare an item is, based on its price. Mystery Boxes use this to pick
/// what to drop.
enum Rarity { common, rare, epic, legendary }

extension RarityInfo on Rarity {
  String get label {
    switch (this) {
      case Rarity.common:
        return "Common";
      case Rarity.rare:
        return "Rare";
      case Rarity.epic:
        return "Epic";
      case Rarity.legendary:
        return "Legendary";
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return Colors.blueGrey.shade300;
      case Rarity.rare:
        return Colors.lightBlueAccent;
      case Rarity.epic:
        return Colors.purpleAccent;
      case Rarity.legendary:
        return Colors.amber;
    }
  }
}

/// Something cosmetic the player can buy in the shop and equip. The first
/// item of each type is the free default.
abstract class Cosmetic {
  final String id;
  final String name;
  final int cost;

  const Cosmetic({
    required this.id,
    required this.name,
    required this.cost,
  });

  CosmeticType get type;

  bool get isDefault => cost == 0;

  Rarity get rarity {
    if (cost <= 300) return Rarity.common;
    if (cost <= 1000) return Rarity.rare;
    if (cost <= 2000) return Rarity.epic;
    return Rarity.legendary;
  }

  static List<Cosmetic> ofType(CosmeticType type) {
    switch (type) {
      case CosmeticType.button:
        return ButtonSkin.all;
      case CosmeticType.timer:
        return TimerStyle.all;
      case CosmeticType.background:
        return BackgroundStyle.all;
      case CosmeticType.font:
        return AppFont.all;
      case CosmeticType.tapEffect:
        return TapEffect.all;
      case CosmeticType.title:
        return PlayerTitle.all;
      case CosmeticType.frame:
        return ProfileFrame.all;
      case CosmeticType.banner:
        return ProfileBanner.all;
    }
  }

  /// Every item that can be bought (everything except the free defaults).
  static List<Cosmetic> get allPaid => [
        for (final type in CosmeticType.values)
          ...ofType(type).where((item) => !item.isDefault),
      ];

  static Cosmetic? byId(CosmeticType type, String? id) {
    for (final item in ofType(type)) {
      if (item.id == id) return item;
    }

    return null;
  }
}

class ButtonSkin extends Cosmetic {
  /// Empty means "use the game's own state colors" (the default button).
  final List<Color> colors;

  /// Shown in the middle of the button instead of the tap icon.
  final String? emoji;

  final Color glow;

  const ButtonSkin({
    required super.id,
    required super.name,
    required super.cost,
    this.colors = const [],
    this.emoji,
    this.glow = Colors.black26,
  });

  @override
  CosmeticType get type => CosmeticType.button;

  static const List<ButtonSkin> all = [
    ButtonSkin(id: 'button_classic', name: 'Classic', cost: 0),
    ButtonSkin(
      id: 'button_fire',
      name: 'Fire',
      cost: 200,
      colors: [Color(0xFFFFC107), Color(0xFFFF5722), Color(0xFFD50000)],
      emoji: '🔥',
      glow: Colors.deepOrange,
    ),
    ButtonSkin(
      id: 'button_ice',
      name: 'Ice',
      cost: 200,
      colors: [Color(0xFFE0F7FA), Color(0xFF4DD0E1), Color(0xFF1565C0)],
      emoji: '❄️',
      glow: Colors.cyanAccent,
    ),
    ButtonSkin(
      id: 'button_galaxy',
      name: 'Galaxy',
      cost: 800,
      colors: [Color(0xFFE040FB), Color(0xFF5E35B1), Color(0xFF0D0D3B)],
      emoji: '✨',
      glow: Colors.purpleAccent,
    ),
    ButtonSkin(
      id: 'button_rainbow',
      name: 'Rainbow',
      cost: 1200,
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
      ],
      emoji: '🌈',
      glow: Colors.white,
    ),
    ButtonSkin(
      id: 'button_gold',
      name: 'Gold',
      cost: 3000,
      colors: [Color(0xFFFFF8E1), Color(0xFFFFC107), Color(0xFFB8860B)],
      emoji: '👑',
      glow: Colors.amber,
    ),
  ];
}

class TimerStyle extends Cosmetic {
  /// Empty means the default colors. More than one color is drawn as a
  /// gradient across the numbers.
  final List<Color> colors;

  final bool glow;

  const TimerStyle({
    required super.id,
    required super.name,
    required super.cost,
    this.colors = const [],
    this.glow = false,
  });

  @override
  CosmeticType get type => CosmeticType.timer;

  static const List<TimerStyle> all = [
    TimerStyle(id: 'timer_classic', name: 'Classic', cost: 0),
    TimerStyle(
      id: 'timer_neon',
      name: 'Neon Pink',
      cost: 100,
      colors: [Colors.pinkAccent],
      glow: true,
    ),
    TimerStyle(
      id: 'timer_matrix',
      name: 'Matrix',
      cost: 100,
      colors: [Colors.greenAccent],
      glow: true,
    ),
    TimerStyle(
      id: 'timer_fire',
      name: 'Fire',
      cost: 500,
      colors: [Colors.yellow, Colors.orange, Colors.red],
      glow: true,
    ),
    TimerStyle(
      id: 'timer_rainbow',
      name: 'Rainbow',
      cost: 1000,
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple,
      ],
    ),
    TimerStyle(
      id: 'timer_gold',
      name: 'Gold',
      cost: 2000,
      colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFFF8F00)],
      glow: true,
    ),
  ];
}

class BackgroundStyle extends Cosmetic {
  /// Empty means the normal app background.
  final List<Color> colors;

  /// Draws a retro grid over the gradient.
  final bool grid;

  const BackgroundStyle({
    required super.id,
    required super.name,
    required super.cost,
    this.colors = const [],
    this.grid = false,
  });

  @override
  CosmeticType get type => CosmeticType.background;

  static const List<BackgroundStyle> all = [
    BackgroundStyle(id: 'background_default', name: 'Default', cost: 0),
    BackgroundStyle(
      id: 'background_sunset',
      name: 'Sunset',
      cost: 300,
      colors: [Color(0xFF2B1055), Color(0xFF7B2D5B), Color(0xFFD9653B)],
    ),
    BackgroundStyle(
      id: 'background_ocean',
      name: 'Ocean',
      cost: 300,
      colors: [Color(0xFF001F3F), Color(0xFF00476B), Color(0xFF00897B)],
    ),
    BackgroundStyle(
      id: 'background_galaxy',
      name: 'Galaxy',
      cost: 800,
      colors: [Color(0xFF05010F), Color(0xFF2A0B4A), Color(0xFF0B1A4A)],
    ),
    BackgroundStyle(
      id: 'background_retro',
      name: 'Retro Grid',
      cost: 1200,
      colors: [Color(0xFF0B0221), Color(0xFF2D0B4E), Color(0xFF5B0F6B)],
      grid: true,
    ),
    BackgroundStyle(
      id: 'background_neon_city',
      name: 'Neon City',
      cost: 2500,
      colors: [Color(0xFF000000), Color(0xFF3A0050), Color(0xFFFF2E88)],
      grid: true,
    ),
  ];
}

/// Uses fonts already on the phone (Android first, then iPhone fallbacks),
/// so nothing extra needs downloading.
class AppFont extends Cosmetic {
  final String? family;
  final List<String> fallback;

  const AppFont({
    required super.id,
    required super.name,
    required super.cost,
    this.family,
    this.fallback = const [],
  });

  @override
  CosmeticType get type => CosmeticType.font;

  static const List<AppFont> all = [
    AppFont(id: 'font_default', name: 'Default', cost: 0),
    AppFont(
      id: 'font_digital',
      name: 'Digital',
      cost: 100,
      family: 'monospace',
      fallback: ['Menlo', 'Courier'],
    ),
    AppFont(
      id: 'font_classy',
      name: 'Classy',
      cost: 300,
      family: 'serif',
      fallback: ['Georgia', 'Times New Roman'],
    ),
    AppFont(
      id: 'font_condensed',
      name: 'Condensed',
      cost: 300,
      family: 'sans-serif-condensed',
      fallback: ['Avenir Next Condensed'],
    ),
    AppFont(
      id: 'font_handwritten',
      name: 'Handwritten',
      cost: 500,
      family: 'casual',
      fallback: ['Chalkboard SE', 'Marker Felt'],
    ),
  ];
}

/// Emoji particles that burst out of the button on every tap.
class TapEffect extends Cosmetic {
  /// Empty means no effect (the default).
  final List<String> particles;

  const TapEffect({
    required super.id,
    required super.name,
    required super.cost,
    this.particles = const [],
  });

  @override
  CosmeticType get type => CosmeticType.tapEffect;

  String get previewEmoji => particles.isEmpty ? "👆" : particles.first;

  static const List<TapEffect> all = [
    TapEffect(id: 'effect_none', name: 'None', cost: 0),
    TapEffect(
      id: 'effect_sparkles',
      name: 'Sparkles',
      cost: 150,
      particles: ['✨', '⭐'],
    ),
    TapEffect(
      id: 'effect_hearts',
      name: 'Hearts',
      cost: 250,
      particles: ['❤️', '💖', '💕'],
    ),
    TapEffect(
      id: 'effect_confetti',
      name: 'Confetti',
      cost: 600,
      particles: ['🎉', '🎊', '✨'],
    ),
    TapEffect(
      id: 'effect_fire',
      name: 'Fire',
      cost: 900,
      particles: ['🔥', '💥'],
    ),
    TapEffect(
      id: 'effect_lightning',
      name: 'Lightning',
      cost: 1500,
      particles: ['⚡', '💫'],
    ),
    TapEffect(
      id: 'effect_coins',
      name: 'Coin Burst',
      cost: 3500,
      particles: ['🪙', '💰', '💎'],
    ),
  ];
}

/// A title shown under the player's name on the share card and leaderboard.
class PlayerTitle extends Cosmetic {
  const PlayerTitle({
    required super.id,
    required super.name,
    required super.cost,
  });

  @override
  CosmeticType get type => CosmeticType.title;

  static const List<PlayerTitle> all = [
    PlayerTitle(id: 'title_none', name: 'No Title', cost: 0),
    PlayerTitle(id: 'title_rookie', name: 'Rookie Ticker', cost: 100),
    PlayerTitle(id: 'title_rhythm', name: 'Rhythm Keeper', cost: 300),
    PlayerTitle(id: 'title_sharp', name: 'Sharpshooter', cost: 700),
    PlayerTitle(id: 'title_ms', name: 'Millisecond Master', cost: 1500),
    PlayerTitle(id: 'title_chronos', name: 'Chronos', cost: 3000),
    PlayerTitle(id: 'title_timelord', name: 'Time Lord', cost: 6000),
  ];
}

/// What encases the player's profile picture: a colored ring, plus optional
/// decorations around it. Frames are the only cosmetic with a gameplay
/// effect: a small Ticks boost that stacks with the pet's.
class ProfileFrame extends Cosmetic {
  /// Empty means a plain ring in the theme's colors.
  final List<Color> colors;

  /// Extra Ticks per run while equipped, e.g. 0.02 = +2%.
  final double boost;

  /// The ring spins slowly.
  final bool animated;

  /// The glow breathes in and out.
  final bool pulse;

  /// Emoji that circle around the picture, e.g. flames.
  final String? orbit;
  final int orbitCount;

  /// Emoji sitting on top of the ring (e.g. a crown) and under it.
  final String? topper;
  final String? bottom;

  const ProfileFrame({
    required super.id,
    required super.name,
    required super.cost,
    this.colors = const [],
    this.boost = 0,
    this.animated = false,
    this.pulse = false,
    this.orbit,
    this.orbitCount = 6,
    this.topper,
    this.bottom,
  });

  @override
  CosmeticType get type => CosmeticType.frame;

  String get boostLabel => "+${(boost * 100).round()}%";

  /// True if anything is drawn outside the ring.
  bool get hasDecorations => orbit != null || topper != null || bottom != null;

  /// True if the frame needs to keep animating.
  bool get isMoving => animated || pulse || orbit != null;

  static const List<ProfileFrame> all = [
    ProfileFrame(id: 'frame_none', name: 'Plain', cost: 0),
    ProfileFrame(
      id: 'frame_bronze',
      name: 'Bronze',
      cost: 250,
      colors: [Color(0xFFCD7F32), Color(0xFF8D5524), Color(0xFFE0A060)],
      boost: 0.01,
    ),
    ProfileFrame(
      id: 'frame_silver',
      name: 'Silver Stars',
      cost: 600,
      colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E), Color(0xFFFFFFFF)],
      boost: 0.02,
      orbit: '✦',
      orbitCount: 4,
    ),
    ProfileFrame(
      id: 'frame_gold',
      name: 'Golden Laurel',
      cost: 1500,
      colors: [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFFFFF8E1)],
      boost: 0.03,
      orbit: '🌿',
      orbitCount: 6,
      bottom: '🏅',
    ),
    ProfileFrame(
      id: 'frame_flame',
      name: 'Inferno',
      cost: 2000,
      colors: [Color(0xFFFFEA00), Color(0xFFFF6D00), Color(0xFFD50000)],
      boost: 0.03,
      animated: true,
      pulse: true,
      orbit: '🔥',
      orbitCount: 8,
    ),
    ProfileFrame(
      id: 'frame_diamond',
      name: 'Diamond',
      cost: 3000,
      colors: [Color(0xFF80DEEA), Color(0xFFE1F5FE), Color(0xFF4FC3F7)],
      boost: 0.04,
      animated: true,
      orbit: '✨',
      orbitCount: 6,
      bottom: '💎',
    ),
    ProfileFrame(
      id: 'frame_storm',
      name: 'Storm',
      cost: 3500,
      colors: [Color(0xFF00E5FF), Color(0xFF2962FF), Color(0xFFAA00FF)],
      boost: 0.04,
      animated: true,
      pulse: true,
      orbit: '⚡',
      orbitCount: 5,
    ),
    ProfileFrame(
      id: 'frame_royal',
      name: 'Royal',
      cost: 4500,
      colors: [Color(0xFFFFD700), Color(0xFF8E24AA), Color(0xFFFFD700)],
      boost: 0.05,
      pulse: true,
      orbit: '⭐',
      orbitCount: 6,
      topper: '👑',
    ),
    ProfileFrame(
      id: 'frame_prism',
      name: 'Prism',
      cost: 5000,
      colors: [
        Color(0xFFFF1744),
        Color(0xFFFFEA00),
        Color(0xFF00E676),
        Color(0xFF2979FF),
        Color(0xFFD500F9),
        Color(0xFFFF1744),
      ],
      boost: 0.05,
      animated: true,
      pulse: true,
      orbit: '🌈',
      orbitCount: 4,
      topper: '✨',
    ),
  ];
}

/// The gradient behind the player's profile card.
class ProfileBanner extends Cosmetic {
  /// Empty means the plain card color.
  final List<Color> colors;

  /// Faint emoji pattern drawn on top of the gradient.
  final String? pattern;

  const ProfileBanner({
    required super.id,
    required super.name,
    required super.cost,
    this.colors = const [],
    this.pattern,
  });

  @override
  CosmeticType get type => CosmeticType.banner;

  static const List<ProfileBanner> all = [
    ProfileBanner(id: 'banner_none', name: 'Plain', cost: 0),
    ProfileBanner(
      id: 'banner_sunset',
      name: 'Sunset',
      cost: 200,
      colors: [Color(0xFFFF7043), Color(0xFFEC407A)],
    ),
    ProfileBanner(
      id: 'banner_ocean',
      name: 'Ocean',
      cost: 200,
      colors: [Color(0xFF0277BD), Color(0xFF26C6DA)],
    ),
    ProfileBanner(
      id: 'banner_aurora',
      name: 'Aurora',
      cost: 700,
      colors: [Color(0xFF1DE9B6), Color(0xFF651FFF)],
      pattern: '✨',
    ),
    ProfileBanner(
      id: 'banner_lava',
      name: 'Lava',
      cost: 1200,
      colors: [Color(0xFF212121), Color(0xFFD50000), Color(0xFFFF6D00)],
      pattern: '🔥',
    ),
    ProfileBanner(
      id: 'banner_galaxy',
      name: 'Galaxy',
      cost: 2500,
      colors: [Color(0xFF0D0221), Color(0xFF3F1D9C), Color(0xFF7B1FA2)],
      pattern: '⭐',
    ),
  ];
}
