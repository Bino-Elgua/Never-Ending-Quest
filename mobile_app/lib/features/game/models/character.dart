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
  final int? armorClass;
  final int? initiative;
  final int? xp;
  final int? nextLevelXp;
  final Currency? currency;

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
    this.armorClass,
    this.initiative,
    this.xp,
    this.nextLevelXp,
    this.currency,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    // Handle both mobile and web backend field names
    final abilities = json['abilities'] as Map<String, dynamic>?;
    final statsJson = json['stats'] ?? abilities ?? {};

    return Character(
      name: json['name'] ?? 'Unknown',
      race: json['race'] ?? 'Unknown',
      characterClass: json['class'] ?? 'Unknown',
      level: json['level'] ?? 1,
      stats: Stats.fromJson(statsJson),
      background: List<String>.from(json['background'] ?? []),
      inventory: (json['inventory'] as List? ?? [])
          .map((i) => InventoryItem.fromJson(i))
          .toList(),
      spells: json['spells'] != null ? List<String>.from(json['spells']) : null,
      alignment: json['alignment'],
      hp: json['hp'] ?? json['hitPoints'] ?? 10,
      maxHp: json['maxHp'] ?? json['maxHitPoints'] ?? 10,
      armorClass: json['armorClass'],
      initiative: json['initiative'],
      xp: json['experience_points'] ?? json['xp'],
      nextLevelXp: json['exp_required_for_next_level'],
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
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
  final int? quantity;

  InventoryItem({
    required this.name,
    this.description,
    this.weight,
    this.type,
    this.quantity,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json['name'] ?? json['item_name'] ?? 'Unknown',
      description: json['description'],
      weight: json['weight'],
      type: json['type'],
      quantity: json['quantity'],
    );
  }
}

class Currency {
  final int gold;
  final int silver;
  final int copper;

  Currency({required this.gold, required this.silver, required this.copper});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      gold: json['gold'] ?? 0,
      silver: json['silver'] ?? 0,
      copper: json['copper'] ?? 0,
    );
  }
}
