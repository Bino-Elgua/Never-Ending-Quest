import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  // Replace with actual backend URL
  return SocketService(url: 'ws://localhost:5000/socket.io/?EIO=4&transport=websocket');
});

class SocketService {
  final String url;
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  SocketService({required this.url});

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect({String? campaignId, String? username}) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    _channel!.stream.listen((message) {
      try {
        final decoded = jsonDecode(message);
        _controller.add(decoded);
      } catch (e) {}
    }, onDone: () {
      _controller.add({'event': 'disconnected'});
    }, onError: (error) {
      _controller.add({'event': 'error', 'message': error.toString()});
    });

    if (campaignId != null) {
      send('join_campaign', {
        'campaign_id': campaignId,
        'username': username ?? 'Adventurer'
      });
    }
  }

  void send(String event, dynamic data) {
    if (_channel != null) {
      // Standard Socket.IO framing would be better here, but for this 
      // prototype we assume the backend handles the EIO=4 websocket format.
      _channel!.sink.add(jsonEncode({'event': event, 'data': data}));
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
