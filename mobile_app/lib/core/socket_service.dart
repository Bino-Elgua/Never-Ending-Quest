import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final wsUrl = ApiConfig.host.replaceFirst('http', 'ws');
  return SocketService(url: '$wsUrl/socket.io/?EIO=4&transport=websocket');
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
      final msg = message.toString();
      
      if (msg.startsWith('40')) {
        if (campaignId != null) {
          send('join_campaign', {
            'campaign_id': campaignId,
            'username': username ?? 'Adventurer'
          });
        }
      }
      else if (msg.startsWith('42')) {
        try {
          final jsonStr = msg.substring(2);
          final decoded = jsonDecode(jsonStr);
          if (decoded is List && decoded.length >= 2) {
            _controller.add({'event': decoded[0], 'data': decoded[1]});
          }
        } catch (e) {
          print('Error decoding socket message: $e');
        }
      }
    }, onDone: () {
      _controller.add({'event': 'disconnected'});
    }, onError: (error) {
      _controller.add({'event': 'error', 'message': error.toString()});
    });
  }

  void send(String event, dynamic data) {
    if (_channel != null) {
      final payload = jsonEncode([event, data]);
      _channel!.sink.add('42$payload');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
