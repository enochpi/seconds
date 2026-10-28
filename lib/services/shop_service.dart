import '../models/pet.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ShopService {
  static Pet? get equippedPet => Pet.byId(StorageService.getEquippedPetId());

  static bool ownsPet(Pet pet) {
    return StorageService.getOwnedPetIds().contains(pet.id);
  }

  /// Returns false if the player can't afford it.
  static Future<bool> buyMode(GameMode mode) async {
    if (StorageService.isModeUnlocked(mode)) return true;

    final paid = await StorageService.spendTicks(
      GameConstants.modeUnlockCost(mode),
    );
    if (!paid) return false;

    await StorageService.unlockMode(mode);
    return true;
  }

  /// Buys and equips the pet. Returns false if the player can't afford it.
  static Future<bool> buyPet(Pet pet) async {
    if (!ownsPet(pet)) {
      final paid = await StorageService.spendTicks(pet.cost);
      if (!paid) return false;

      await StorageService.addOwnedPet(pet.id);
    }

    await StorageService.setEquippedPetId(pet.id);
    return true;
  }

  static int get streakShields => StorageService.getStreakShields();

  /// Returns false if the player can't afford it.
  static Future<bool> buyStreakShield() async {
    final paid =
        await StorageService.spendTicks(GameConstants.streakShieldCost);
    if (!paid) return false;

    await StorageService.setStreakShields(streakShields + 1);
    return true;
  }

  static Future<void> equipPet(Pet pet) async {
    if (!ownsPet(pet)) return;

    await StorageService.setEquippedPetId(pet.id);
  }
}
