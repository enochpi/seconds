import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cosmetics.dart';
import '../models/profile_model.dart';
import 'cosmetics_service.dart';
import 'shop_service.dart';
import 'storage_service.dart';

/// Builds the player's profile and tracks the lifetime stats shown on it.
/// Frames and banners are bought and equipped like any other
/// cosmetic (see CosmeticsService).
class ProfileService {
  static ProfileFrame get frame =>
      CosmeticsService.equipped(CosmeticType.frame) as ProfileFrame;

  static ProfileBanner get banner =>
      CosmeticsService.equipped(CosmeticType.banner) as ProfileBanner;

  /// Extra Ticks per run from the equipped frame. Adds to the pet's bonus.
  static double getProfileBoost() => frame.boost;

  /// The uploaded photo, if there is one and it's still on disk.
  static String? get photoPath {
    final path = StorageService.getAvatarPhotoPath();
    if (path == null || !File(path).existsSync()) return null;

    return path;
  }

  static PlayerProfile get current {
    return PlayerProfile(
      name: StorageService.getPlayerName(),
      avatarPhotoPath: photoPath,
      avatarEmoji: ShopService.equippedPet?.emoji,
      frame: frame,
      banner: banner,
      title: CosmeticsService.titleText,
      unlockedItems: [
        for (final type in [
          CosmeticType.frame,
          CosmeticType.banner,
        ])
          ...Cosmetic.ofType(type).where(CosmeticsService.owns),
      ],
      lifetimeTicks: StorageService.getLifetimeTicksEarned(),
      perfectTaps: StorageService.getLifetimePerfectTaps(),
      bestWinStreak: StorageService.getBestWinStreak(),
    );
  }

  /// Lets the player pick a photo from their gallery and uses it as their
  /// profile picture. Returns false if they cancelled.
  static Future<bool> pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return false;

    // Copy it into the app's own folder so it survives the gallery changing.
    // A new name each time stops Flutter showing the old cached image.
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(picked.path).copy(path);

    final old = StorageService.getAvatarPhotoPath();
    if (old != null && File(old).existsSync()) await File(old).delete();

    await StorageService.setAvatarPhotoPath(path);
    CosmeticsService.changes.value++;
    return true;
  }

  /// Goes back to the pet emoji (or name initial).
  static Future<void> removePhoto() async {
    final old = StorageService.getAvatarPhotoPath();
    if (old != null && File(old).existsSync()) await File(old).delete();

    await StorageService.setAvatarPhotoPath(null);
    CosmeticsService.changes.value++;
  }

  /// Called once per finished run. Lifetime Ticks are counted by
  /// StorageService.addTicks.
  static Future<void> recordRun({
    required int perfectTaps,
    required int winStreak,
  }) async {
    if (perfectTaps > 0) await StorageService.addPerfectTaps(perfectTaps);
    await StorageService.saveBestWinStreak(winStreak);
  }
}
