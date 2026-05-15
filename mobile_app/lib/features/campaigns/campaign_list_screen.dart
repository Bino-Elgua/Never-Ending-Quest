import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'campaign_provider.dart';

class CampaignListScreen extends ConsumerWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final savesAsync = ref.watch(saveGamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Adventures', style: GoogleFonts.cinzel()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(campaignsProvider);
          ref.invalidate(saveGamesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Current Campaign'),
            campaignsAsync.when(
              data: (data) => _buildCampaignCard(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading campaign: $e'),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Saved Adventures'),
            savesAsync.when(
              data: (saves) => _buildSaveList(saves),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading saves: $e'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('New Adventure'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF5D001E),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE5B181),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, Map<String, dynamic> data) {
    return Column(
      children: [
        Card(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFF5D001E), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              data['campaign_name'] ?? 'The Unnamed Quest',
              style: GoogleFonts.cinzel(fontSize: 20, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Module: ${data['current_module']}', style: GoogleFonts.spectral(color: const Color(0xFFE5B181))),
                Text('Location: ${data['hubs']?.isNotEmpty == true ? data['hubs'][0] : 'The Wilderness'}', style: GoogleFonts.spectral(color: Colors.white60)),
              ],
            ),
            trailing: const Icon(Icons.play_arrow, color: Color(0xFFE5B181), size: 32),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.save,
                label: 'SAVE',
                color: const Color(0xFF1A1A1A),
                onTap: () => _showSaveDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh,
                label: 'RESET',
                color: const Color(0xFF5D001E).withOpacity(0.5),
                onTap: () => _showResetDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF5D001E)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFE5B181)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('PRESERVE CHRONICLE', style: GoogleFonts.cinzel()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Save description...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              // Trigger save via API
              Navigator.pop(context);
            },
            child: const Text('SAVE', style: TextStyle(color: Color(0xFFE5B181))),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('VOID CURRENT QUEST?', style: GoogleFonts.cinzel()),
        content: const Text('This will reset your current progress. Your saved adventures will remain intact.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              // Trigger reset via API
              Navigator.pop(context);
            },
            child: const Text('RESET', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveList(List<dynamic> saves) {
    if (saves.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No saved adventures found.'),
        ),
      );
    }

    return Column(
      children: saves.map((save) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.history, color: Color(0xFFE5B181)),
          title: Text(save['description'] ?? 'Unnamed Save'),
          subtitle: Text(save['timestamp'] ?? 'Unknown Date'),
          onTap: () {},
        ),
      )).toList(),
    );
  }
}
