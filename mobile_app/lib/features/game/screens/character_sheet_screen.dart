import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/game_status_provider.dart';
import '../models/character.dart';

class CharacterSheetScreen extends ConsumerWidget {
  const CharacterSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(gameStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Character Sheet', style: GoogleFonts.cinzel()),
      ),
      body: statusAsync.when(
        data: (status) {
          if (status.characters.isEmpty) {
            return const Center(child: Text('No active characters found.'));
          }
          final character = status.characters[0]; // Show first for now
          return _CharacterView(character: character);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CharacterView extends StatelessWidget {
  final Character character;

  const _CharacterView({required this.character});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _buildHeader(),
          const TabBar(
            indicatorColor: Color(0xFFE5B181),
            labelColor: Color(0xFFE5B181),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Stats'),
              Tab(text: 'Inventory'),
              Tab(text: 'Spells'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildStatsTab(),
                _buildInventoryTab(),
                _buildSpellsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0xFF5D001E), width: 2)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF5D001E),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.name,
                  style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Level ${character.level} ${character.characterClass}',
                  style: GoogleFonts.spectral(fontSize: 18, color: const Color(0xFFE5B181)),
                ),
                const SizedBox(height: 12),
                _buildHPBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHPBar() {
    final percent = (character.hp / character.maxHp).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('HP', style: GoogleFonts.cinzel(fontSize: 12)),
            Text('${character.hp} / ${character.maxHp}', style: GoogleFonts.cinzel(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.5 ? Colors.green : (percent > 0.2 ? Colors.orange : Colors.red),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final stats = character.stats;
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('STR', stats.strength),
        _buildStatCard('DEX', stats.dexterity),
        _buildStatCard('CON', stats.constitution),
        _buildStatCard('INT', stats.intelligence),
        _buildStatCard('WIS', stats.wisdom),
        _buildStatCard('CHA', stats.charisma),
      ],
    );
  }

  Widget _buildStatCard(String label, int value) {
    final modifier = (value - 10) ~/ 2;
    final modStr = modifier >= 0 ? '+$modifier' : '$modifier';
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.cinzel(fontSize: 14, color: Colors.white60)),
          const SizedBox(height: 4),
          Text('$value', style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(modStr, style: GoogleFonts.spectral(fontSize: 16, color: const Color(0xFFE5B181))),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    if (character.inventory.isEmpty) {
      return const Center(child: Text('Empty inventory.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: character.inventory.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = character.inventory[index];
        return ListTile(
          title: Text(item.name, style: GoogleFonts.spectral(fontSize: 18)),
          subtitle: item.description != null ? Text(item.description!) : null,
          trailing: item.weight != null ? Text('${item.weight} lbs') : null,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildSpellsTab() {
    final spells = character.spells;
    if (spells == null || spells.isEmpty) {
      return const Center(child: Text('No spells known.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: spells.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.auto_fix_high, color: Color(0xFFE5B181)),
          title: Text(spells[index], style: GoogleFonts.spectral(fontSize: 18)),
          onTap: () {},
        );
      },
    );
  }
}
