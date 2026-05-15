import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket_service.dart';
import '../models/quest.dart';
import '../models/character.dart';

final plotProvider = StateNotifierProvider<PlotNotifier, List<Quest>>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return PlotNotifier(socket);
});

class PlotNotifier extends StateNotifier<List<Quest>> {
  final SocketService _socket;

  PlotNotifier(this._socket) : super([]) {
    _socket.stream.listen((event) {
      if (event['event'] == 'plot_data_response') {
        final data = event['data'];
        if (data != null && data['plotPoints'] != null) {
          final List<dynamic> points = data['plotPoints'];
          state = points
              .where((q) => q['status'] != 'not started')
              .map((q) => Quest.fromJson(q))
              .toList();
        }
      }
    });
  }

  void refresh() {
    _socket.send('request_plot_data', {});
  }
}

final npcProvider = StateNotifierProvider<NPCNotifier, List<Character>>((ref) {
  final socket = ref.watch(socketServiceProvider);
  return NPCNotifier(socket);
});

class NPCNotifier extends StateNotifier<List<Character>> {
  final SocketService _socket;

  NPCNotifier(this._socket) : super([]) {
    _socket.stream.listen((event) {
      if (event['event'] == 'player_data_response') {
        final dataType = event['dataType'];
        if (dataType == 'npcs') {
          final List<dynamic> data = event['data'] ?? [];
          state = data.map((n) => Character.fromJson(n)).toList();
        }
      }
    });
  }

  void refresh() {
    _socket.send('request_player_data', {'dataType': 'npcs'});
  }
}
