class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  String get emoji {
    final spaceIndex = title.indexOf(' ');
    return spaceIndex == -1 ? title : title.substring(0, spaceIndex);
  }

  String get label {
    final spaceIndex = title.indexOf(' ');
    return spaceIndex == -1 ? title : title.substring(spaceIndex + 1);
  }
}
