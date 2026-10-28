import 'cosmetics.dart';

/// Everything shown on a player's profile card: what they've equipped, what
/// they own, and their lifetime stats. Built by ProfileService.
class PlayerProfile {
  final String name;

  /// An uploaded photo. Shown instead of [avatarEmoji] when set.
  final String? avatarPhotoPath;

  /// Emoji shown when there is no photo (the equipped pet), or null to show
  /// the first letter of [name].
  final String? avatarEmoji;

  final ProfileFrame frame;
  final ProfileBanner banner;

  /// Null when no title is equipped.
  final String? title;

  /// Frames and banners the player owns, defaults included.
  final List<Cosmetic> unlockedItems;

  final int lifetimeTicks;
  final int perfectTaps;
  final int bestWinStreak;

  const PlayerProfile({
    required this.name,
    this.avatarPhotoPath,
    required this.avatarEmoji,
    required this.frame,
    required this.banner,
    required this.title,
    required this.unlockedItems,
    required this.lifetimeTicks,
    required this.perfectTaps,
    required this.bestWinStreak,
  });

  String get initial => name.isEmpty ? "?" : name[0].toUpperCase();

  /// Extra Ticks per run from the profile (the frame), e.g. 0.03 = +3%.
  double get boost => frame.boost;

  /// A copy with a different frame, for shop previews.
  PlayerProfile previewWith({required ProfileFrame frame}) {
    return PlayerProfile(
      name: name,
      avatarPhotoPath: avatarPhotoPath,
      avatarEmoji: avatarEmoji,
      frame: frame,
      banner: banner,
      title: title,
      unlockedItems: unlockedItems,
      lifetimeTicks: lifetimeTicks,
      perfectTaps: perfectTaps,
      bestWinStreak: bestWinStreak,
    );
  }
}
