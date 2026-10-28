import 'dart:math';

import '../models/cosmetics.dart';
import 'cosmetics_service.dart';
import 'storage_service.dart';

class MysteryBoxResult {
  final Cosmetic item;

  /// True if the player already owned it, so it was turned into Ticks.
  final bool wasDuplicate;
  final int refundTicks;

  const MysteryBoxResult({
    required this.item,
    required this.wasDuplicate,
    required this.refundTicks,
  });
}

/// A box that drops one random cosmetic. Cheaper items drop far more often;
/// duplicates are converted to half their price in Ticks.
class MysteryBoxService {
  static const int cost = 250;

  /// Drop chance out of 100 for each rarity.
  static const Map<Rarity, int> dropWeights = {
    Rarity.common: 65,
    Rarity.rare: 25,
    Rarity.epic: 8,
    Rarity.legendary: 2,
  };

  static final Random _random = Random();

  static int get freeBoxes => StorageService.getFreeMysteryBoxes();

  /// Opens a free box if the player has one, otherwise pays [cost]. Returns
  /// null if they can't afford it.
  static Future<MysteryBoxResult?> open() async {
    if (freeBoxes > 0) {
      await StorageService.setFreeMysteryBoxes(freeBoxes - 1);
    } else {
      final paid = await StorageService.spendTicks(cost);
      if (!paid) return null;
    }

    final item = _rollItem();

    if (CosmeticsService.owns(item)) {
      final refund = max(25, item.cost ~/ 2);
      await StorageService.addTicks(refund);

      return MysteryBoxResult(
        item: item,
        wasDuplicate: true,
        refundTicks: refund,
      );
    }

    await StorageService.addOwnedCosmetic(item.id);

    return MysteryBoxResult(item: item, wasDuplicate: false, refundTicks: 0);
  }

  static Cosmetic _rollItem() {
    final rarity = _rollRarity();
    final pool =
        Cosmetic.allPaid.where((item) => item.rarity == rarity).toList();
    final candidates = pool.isEmpty ? Cosmetic.allPaid : pool;

    return candidates[_random.nextInt(candidates.length)];
  }

  static Rarity _rollRarity() {
    final total = dropWeights.values.reduce((a, b) => a + b);
    var roll = _random.nextInt(total);

    for (final entry in dropWeights.entries) {
      if (roll < entry.value) return entry.key;
      roll -= entry.value;
    }

    return Rarity.common;
  }

  static String get _today {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  /// True if sharing today would still earn a free box.
  static bool get shareRewardAvailable =>
      StorageService.getLastShareRewardDay() != _today;

  /// Gives one free box for sharing, at most once a day. Returns true if a
  /// box was given.
  static Future<bool> rewardShare() async {
    if (!shareRewardAvailable) return false;

    await StorageService.setLastShareRewardDay(_today);
    await StorageService.setFreeMysteryBoxes(freeBoxes + 1);
    return true;
  }
}
