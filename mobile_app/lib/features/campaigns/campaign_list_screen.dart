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
              data: (data) => _buildCampaignCard(data),
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

  Widget _buildCampaignCard(Map<String, dynamic> data) {
    return Card(
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
            Text('Current Module: ${data['current_module']}'),
            Text('Hub: ${data['hubs']?.isNotEmpty == true ? data['hubs'][0] : 'None'}'),
          ],
        ),
        trailing: const Icon(Icons.play_arrow, color: Color(0xFFE5B181), size: 32),
        onTap: () {},
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
