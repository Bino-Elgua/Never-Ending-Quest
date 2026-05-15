import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/ai_provider.dart';
import '../widgets/dice_roller.dart';
import '../../../core/socket_service.dart';
import '../../../core/voice_service.dart';
import '../../../core/haptic_service.dart';

class NarrationScreen extends ConsumerStatefulWidget {
  const NarrationScreen({super.key});

  @override
  ConsumerState<NarrationScreen> createState() => _NarrationScreenState();
}

class _NarrationScreenState extends ConsumerState<NarrationScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAutoSpeakEnabled = true;
  final String _campaignId = 'default_room';
  String _timeOfDayImage = 'midday.jpg';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final socket = ref.read(socketServiceProvider);
      socket.connect(campaignId: _campaignId, username: 'Mobile User');
      
      socket.stream.listen((event) {
        final type = event['event'];
        final data = event['data'];

        if (type == 'game_output') {
          if (data['type'] == 'narration' || data['type'] == 'user-input') {
            ref.read(activeChatProvider.notifier).addMessage(
              ChatMessage(
                role: data['type'] == 'user-input' ? 'user' : 'assistant',
                content: data['content'],
                username: data['username'],
                imageUrl: data['image_url']
              ),
            );
            if (data['type'] == 'narration' && _isAutoSpeakEnabled) {
              ref.read(voiceServiceProvider).speak(data['content']);
            }
            _scrollToBottom();
          }
        } else if (type == 'media_update') {
          ref.read(activeChatProvider.notifier).addMessage(
            ChatMessage(
              role: 'assistant',
              content: data['description'] ?? 'A new vision appears...',
              imageUrl: data['url']
            ),
          );
          _scrollToBottom();
        } else if (type == 'time_update') {
          _updateTimeOfDay(data['time']);
        } else if (type == 'player_joined') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['username']} has joined the quest!')),
          );
        }
      });
      
      ref.read(chatHistoryProvider(_campaignId).future).then((history) {
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

  void _showDiceRoller() {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const DiceRollerSheet(),
    );
  }

  void _toggleListening() async {
    final voiceService = ref.read(voiceServiceProvider);
    if (voiceService.isListening) {
      await voiceService.stopListening();
    } else {
      final success = await voiceService.startListening((text) {
        setState(() {
          _inputController.text = text;
        });
      });
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Speech recognition not available')),
          );
        }
      }
    }
    if (mounted) setState(() {});
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

  void _updateTimeOfDay(String timeStr) {
    if (timeStr.isEmpty) return;
    try {
      final hour = int.parse(timeStr.split(':')[0]);
      String newImage;
      if (hour >= 5 && hour < 9) {
        newImage = 'sunrise.jpg';
      } else if (hour >= 9 && hour < 17) {
        newImage = 'midday.jpg';
      } else if (hour >= 17 && hour < 21) {
        newImage = 'sunset.jpg';
      } else {
        newImage = 'nightfall.jpg';
      }
      if (newImage != _timeOfDayImage) {
        setState(() => _timeOfDayImage = newImage);
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(activeChatProvider);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('THE QUEST', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isAutoSpeakEnabled ? Icons.volume_up : Icons.volume_off, color: const Color(0xFFE5B181)),
            onPressed: () => setState(() => _isAutoSpeakEnabled = !_isAutoSpeakEnabled),
          ),
          IconButton(
            icon: const Icon(Icons.casino, color: Color(0xFFE5B181)),
            onPressed: _showDiceRoller,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Environmental Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'http://127.0.0.1:8357/static/media/environment/$_timeOfDayImage',
                fit: BoxFit.cover,                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 20),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg, msg.role == 'user');
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
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
                style: GoogleFonts.cinzel(fontSize: 10, color: Colors.white24, fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF5D001E).withOpacity(0.8) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              border: isUser ? null : Border.all(color: const Color(0xFFE5B181).withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      msg.imageUrl!.startsWith('http') ? msg.imageUrl! : 'http://127.0.0.1:8357${msg.imageUrl}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.black26,
                          child: const Center(child: CircularProgressIndicator(color: Color(0xFFE5B181))),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.black26,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white10)),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isListening = ref.watch(voiceServiceProvider).isListening;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                hintStyle: GoogleFonts.cinzel(color: Colors.white24, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              style: GoogleFonts.spectral(color: Colors.white, fontSize: 18),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFE5B181)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
