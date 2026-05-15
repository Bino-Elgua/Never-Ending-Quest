import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:never_ending_quest/core/api_client.dart';
import '../models/character.dart';

class GameStatus {
  final List<Character> characters;
  final Map<String, dynamic>? current_location;
  final String? module;

  GameStatus({
    required this.characters,
    this.current_location,
    this.module,
  });

  factory GameStatus.fromJson(Map<String, dynamic> json) {
    return GameStatus(
      characters: (json['characters'] as List? ?? [])
          .map((c) => Character.fromJson(c))
          .toList(),
      current_location: json['current_location'],
      module: json['module'],
    );
  }
}

final gameStatusProvider = FutureProvider<GameStatus>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('api/v1/game/status');
  return GameStatus.fromJson(response.data);
});
