class Character {
  final String name;
  final String race;
  final String characterClass;
  final int level;
  final Stats stats;
  final List<String> background;
  final List<InventoryItem> inventory;
  final List<String>? spells;
  final String? alignment;
  final int hp;
  final int maxHp;

  Character({
    required this.name,
    required this.race,
    required this.characterClass,
    required this.level,
    required this.stats,
    required this.background,
    required this.inventory,
    this.spells,
    this.alignment,
    required this.hp,
    required this.maxHp,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'] ?? 'Unknown',
      race: json['race'] ?? 'Unknown',
      characterClass: json['class'] ?? 'Unknown',
      level: json['level'] ?? 1,
      stats: Stats.fromJson(json['stats'] ?? {}),
      background: List<String>.from(json['background'] ?? []),
      inventory: (json['inventory'] as List? ?? [])
          .map((i) => InventoryItem.fromJson(i))
          .toList(),
      spells: json['spells'] != null ? List<String>.from(json['spells']) : null,
      alignment: json['alignment'],
      hp: json['hp'] ?? 10,
      maxHp: json['maxHp'] ?? 10,
    );
  }
}

class Stats {
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  Stats({
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      strength: json['strength'] ?? 10,
      dexterity: json['dexterity'] ?? 10,
      constitution: json['constitution'] ?? 10,
      intelligence: json['intelligence'] ?? 10,
      wisdom: json['wisdom'] ?? 10,
      charisma: json['charisma'] ?? 10,
    );
  }
}

class InventoryItem {
  final String name;
  final String? description;
  final int? weight;
  final String? type;

  InventoryItem({
    required this.name,
    this.description,
    this.weight,
    this.type,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      weight: json['weight'],
      type: json['type'],
    );
  }
}
