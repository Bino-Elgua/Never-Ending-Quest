import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../../../core/socket_service.dart';

class NarrationScreen extends ConsumerStatefulWidget {
  const NarrationScreen({super.key});

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAutoSpeakEnabled = true;
  String _campaignId = 'default_room';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final socket = ref.read(socketServiceProvider);
      socket.connect(campaignId: _campaignId, username: 'Mobile User');
      
      socket.stream.listen((event) {
        if (event['event'] == 'game_output') {
          final data = event['data'];
          if (data['type'] == 'narration' || data['type'] == 'user-input') {
            ref.read(activeChatProvider.notifier).addMessage(
              ChatMessage(
                role: data['type'] == 'user-input' ? 'user' : 'assistant',
                content: data['content'],
                username: data['username']
              ),
            );
            if (data['type'] == 'narration' && _isAutoSpeakEnabled) {
              ref.read(voiceServiceProvider).speak(data['content']);
            }
            _scrollToBottom();
          }
        } else if (event['event'] == 'player_joined') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${event['data']['username']} has joined the quest!')),
          );
        }
      });
      
      ref.read(chatHistoryProvider.future).then((history) {
        ref.read(activeChatProvider.notifier).setHistory(history);
        _scrollToBottom();
      });
    });
  }

  void _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final aiState = ref.read(aiProvider);
    if (aiState.source == AIProviderSource.remote) {
      ref.read(socketServiceProvider).send('user_input', {
        'input': text,
        'campaign_id': _campaignId,
        'username': 'Mobile User'
      });
    } else {
      // Local generation path
      final response = await ref.read(aiProvider.notifier).generateResponse(text);
      ref.read(activeChatProvider.notifier).addMessage(
        ChatMessage(role: 'assistant', content: response),
      );
      if (_isAutoSpeakEnabled) {
        ref.read(voiceServiceProvider).speak(response);
      }
    }

    _inputController.clear();
    _scrollToBottom();
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (msg.username != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 2),
              child: Text(
                msg.username!,
                style: GoogleFonts.spectral(fontSize: 12, color: Colors.white38),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF5D001E) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isUser ? 12 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 12),
              ),
              border: isUser ? null : Border.all(color: const Color(0xFFE5B181).withOpacity(0.3)),
            ),
            child: Text(
              msg.content,
              style: GoogleFonts.spectral(
                fontSize: 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildInputArea() {
    final isListening = ref.watch(voiceServiceProvider).isListening;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? Colors.red : const Color(0xFFE5B181),
            ),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'What do you do?',
                hintStyle: GoogleFonts.cinzel(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF5D001E)),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF5D001E),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
