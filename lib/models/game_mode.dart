enum GameMode { free, exact }

class GameModeInfo {
  final GameMode mode;
  final String name;
  final String description;
  final bool isUnlocked;
  final int? unlockRequirement;

  GameModeInfo({
    required this.mode,
    required this.name,
    required this.description,
    required this.isUnlocked,
    this.unlockRequirement,
  });
}
