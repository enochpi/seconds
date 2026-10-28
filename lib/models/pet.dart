class Pet {
  final String id;
  final String emoji;
  final String name;
  final int cost;

  /// Extra Ticks earned per run while equipped, e.g. 0.05 = +5%.
  final double bonus;

  const Pet({
    required this.id,
    required this.emoji,
    required this.name,
    required this.cost,
    required this.bonus,
  });

  String get bonusLabel => "+${(bonus * 100).round()}%";

  // Rank animals (Sloth, Cobra, Fox...) are left out so pets never get
  // confused with your rank.
  static const List<Pet> all = [
    Pet(id: 'hamster', emoji: '🐹', name: 'Hamster', cost: 200, bonus: 0.05),
    Pet(id: 'bunny', emoji: '🐰', name: 'Bunny', cost: 600, bonus: 0.10),
    Pet(id: 'owl', emoji: '🦉', name: 'Owl', cost: 1200, bonus: 0.15),
    Pet(id: 'panda', emoji: '🐼', name: 'Panda', cost: 2800, bonus: 0.20),
    Pet(id: 'dragon', emoji: '🐉', name: 'Dragon', cost: 8000, bonus: 0.30),
  ];

  static Pet? byId(String? id) {
    for (final pet in all) {
      if (pet.id == id) return pet;
    }

    return null;
  }
}
