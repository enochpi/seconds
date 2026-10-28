import 'package:flutter/foundation.dart';

import '../models/cosmetics.dart';
import 'storage_service.dart';

class CosmeticsService {
  /// Bumped whenever something is equipped, so the app can restyle itself.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static bool owns(Cosmetic item) {
    return item.isDefault ||
        StorageService.getOwnedCosmeticIds().contains(item.id);
  }

  static bool isEquipped(Cosmetic item) => equipped(item.type).id == item.id;

  static Cosmetic equipped(CosmeticType type) {
    return Cosmetic.byId(type, StorageService.getEquippedCosmeticId(type)) ??
        Cosmetic.ofType(type).first;
  }

  static ButtonSkin get button => equipped(CosmeticType.button) as ButtonSkin;

  static TimerStyle get timer => equipped(CosmeticType.timer) as TimerStyle;

  static BackgroundStyle get background =>
      equipped(CosmeticType.background) as BackgroundStyle;

  static AppFont get font => equipped(CosmeticType.font) as AppFont;

  static TapEffect get tapEffect =>
      equipped(CosmeticType.tapEffect) as TapEffect;

  /// The equipped title's text, or null if none.
  static String? get titleText {
    final title = equipped(CosmeticType.title);
    return title.isDefault ? null : title.name;
  }

  /// Buys (if needed) and equips. Returns false if the player can't afford it.
  static Future<bool> buy(Cosmetic item) async {
    if (!owns(item)) {
      final paid = await StorageService.spendTicks(item.cost);
      if (!paid) return false;

      await StorageService.addOwnedCosmetic(item.id);
    }

    await equip(item);
    return true;
  }

  static Future<void> equip(Cosmetic item) async {
    if (!owns(item)) return;

    await StorageService.setEquippedCosmeticId(item.type, item.id);
    changes.value++;
  }
}
