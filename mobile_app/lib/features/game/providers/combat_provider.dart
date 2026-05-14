import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:never_ending_quest/core/api_client.dart';

class CombatState {
  final List<Combatant> combatants;
  final int turn;
  final Map<String, dynamic>? grid;

  CombatState({required this.combatants, required this.turn, this.grid});

  factory CombatState.fromJson(Map<String, dynamic> json) {
    return CombatState(
      combatants: (json['combatants'] as List? ?? [])
          .map((c) => Combatant.fromJson(c))
          .toList(),
      turn: json['turn'] ?? 0,
      grid: json['grid'],
    );
  }
}

class Combatant {
  final String id;
  final String name;
  final int hp;
  final int maxHp;
  final List<int> position; // [x, y]
  final bool isPlayer;

  Combatant({
    required this.id,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.position,
    required this.isPlayer,
  });

  factory Combatant.fromJson(Map<String, dynamic> json) {
    return Combatant(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      hp: json['hp'] ?? 0,
      maxHp: json['maxHp'] ?? 100,
      position: List<int>.from(json['position'] ?? [0, 0]),
      isPlayer: json['isPlayer'] ?? false,
    );
  }
}

final combatStateProvider = FutureProvider<CombatState>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  // This would be a real endpoint in the Python backend
  final response = await apiClient.get('/game/combat-status');
  return CombatState.fromJson(response.data);
});
