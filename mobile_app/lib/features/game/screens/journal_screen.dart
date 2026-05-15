import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../providers/plot_provider.dart';
import '../models/quest.dart';
import 'package:intl/intl.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('THE CHRONICLE', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5B181),
            labelColor: const Color(0xFFE5B181),
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'LOG', icon: Icon(Icons.history_edu)),
              Tab(text: 'QUESTS', icon: Icon(Icons.map)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LogTab(),
            _QuestTab(),
          ],
        ),
      ),
    );
  }
}

class _LogTab extends ConsumerWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(chatHistoryProvider('default_room'));
    return historyAsync.when(
      data: (messages) => _JournalListView(messages: messages),
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE5B181))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _QuestTab extends ConsumerWidget {
  const _QuestTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(plotProvider);
    
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text('No quest objectives discovered yet...', style: GoogleFonts.cinzel(color: Colors.white38)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(plotProvider.notifier).refresh(),
              child: const Text('REFRESH'),
            ),
          ],
        ),
      );
    }

    final activeQuests = quests.where((q) => q.status != 'completed').toList();
    final completedQuests = quests.where((q) => q.status == 'completed').toList();

    return RefreshIndicator(
      onRefresh: () async => ref.read(plotProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (activeQuests.isNotEmpty) ...[
            _buildSectionHeader('Current Objectives'),
            ...activeQuests.map((q) => _QuestCard(quest: q)),
          ],
          if (completedQuests.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader('Tales of Completion'),
            ...completedQuests.map((q) => _QuestCard(quest: q)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.cinzel(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE5B181),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final Quest quest;

  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = quest.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted ? Colors.green.withOpacity(0.3) : const Color(0xFF5D001E),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : const Color(0xFFE5B181),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quest.title,
                    style: GoogleFonts.cinzel(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quest.description,
              style: GoogleFonts.spectral(
                fontSize: 16,
                color: isCompleted ? Colors.white38 : Colors.white70,
              ),
            ),
            if (quest.sideQuests != null && quest.sideQuests!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              ...quest.sideQuests!.map((sq) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.white24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sq.title,
                            style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            sq.description,
                            style: GoogleFonts.spectral(fontSize: 14, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _JournalListView extends StatelessWidget {
  final List<ChatMessage> messages;

  const _JournalListView({required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text('The pages are blank...', style: GoogleFonts.cinzel(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final bool isAssistant = msg.role == 'assistant';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAssistant ? Icons.menu_book : Icons.person_pin,
                    size: 14,
                    color: isAssistant ? const Color(0xFFE5B181) : const Color(0xFF5D001E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAssistant ? 'THE DUNGEON MASTER' : (msg.username?.toUpperCase() ?? 'THE HERO'),
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isAssistant ? const Color(0xFFE5B181).withOpacity(0.7) : Colors.white38,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: GoogleFonts.spectral(fontSize: 10, color: Colors.white24),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                msg.content,
                style: GoogleFonts.spectral(
                  fontSize: 16,
                  color: isAssistant ? Colors.white.withOpacity(0.9) : Colors.white60,
                  height: 1.5,
                  fontStyle: isAssistant ? FontStyle.normal : FontStyle.italic,
                ),
              ),
              if (index < messages.length - 1)
                const Divider(height: 32, color: Colors.white10),
            ],
          ),
        );
      },
    );
  }
}
