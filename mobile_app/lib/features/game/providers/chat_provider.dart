import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:never_ending_quest/core/api_client.dart';

class ChatMessage {
  final String role;
  final String content;
  final String? username;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, this.username, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'unknown',
      content: json['content'] ?? '',
      username: json['username'],
    );
  }
}

final chatHistoryProvider = FutureProvider<List<ChatMessage>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/game/chat-history');
  final List<dynamic> data = response.data;
  return data.map((json) => ChatMessage.fromJson(json)).toList();
});

class ChatState extends StateNotifier<List<ChatMessage>> {
  ChatState() : super([]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
  
  void setHistory(List<ChatMessage> history) {
    state = history;
  }
}

final activeChatProvider = StateNotifierProvider<ChatState, List<ChatMessage>>((ref) {
  return ChatState();
});
