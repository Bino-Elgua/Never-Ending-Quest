import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_status_provider.dart';
import '../models/character.dart';
import '../../../core/haptic_service.dart';

class CharacterSheetScreen extends ConsumerWidget {
  const CharacterSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(gameStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('The Hero', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: statusAsync.when(
        data: (status) {
          if (status.characters.isEmpty) {
            return const Center(child: Text('No active characters found.'));
          }
          final character = status.characters[0];
          return _CharacterCardView(character: character);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE5B181))),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CharacterCardView extends StatelessWidget {
  final Character character;

  const _CharacterCardView({required this.character});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildIdentityCard(),
        const SizedBox(height: 16),
        _buildStatGrid(),
        const SizedBox(height: 24),
        _buildSectionHeader('Equipment & Artifacts'),
        const SizedBox(height: 8),
        _buildInventoryCards(),
        const SizedBox(height: 24),
        if (character.spells != null && character.spells!.isNotEmpty) ...[
          _buildSectionHeader('Arcane Spells'),
          const SizedBox(height: 8),
          _buildSpellCards(),
        ],
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFE5B181),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildIdentityCard() {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF5D001E), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 35,
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
                        style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Level ${character.level} ${character.characterClass}',
                        style: GoogleFonts.spectral(fontSize: 18, color: const Color(0xFFE5B181)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildHPBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHPBar() {
    final percent = (character.hp / character.maxHp).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('VITALITY', style: GoogleFonts.cinzel(fontSize: 12, color: Colors.white60)),
            Text('${character.hp} / ${character.maxHp}', style: GoogleFonts.spectral(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.5 ? Colors.green.shade800 : (percent > 0.2 ? Colors.orange.shade800 : Colors.red.shade900),
            ),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    final stats = character.stats;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
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
    
    return InkWell(
      onTap: () => HapticService.light(),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: GoogleFonts.cinzel(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 4),
            Text('$value', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF5D001E).withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(modStr, style: GoogleFonts.spectral(fontSize: 14, color: const Color(0xFFE5B181))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryCards() {
    return Column(
      children: character.inventory.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          onTap: () => HapticService.light(),
          leading: const Icon(Icons.shield_outlined, color: Color(0xFFE5B181)),
          title: Text(item.name, style: GoogleFonts.spectral(fontSize: 18, fontWeight: FontWeight.w600)),
          subtitle: item.description != null ? Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: Text('${item.weight ?? 0} lbs', style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ),
      )).toList(),
    );
  }

  Widget _buildSpellCards() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: character.spells!.map((spell) => ActionChip(
        onPressed: () => HapticService.medium(),
        backgroundColor: const Color(0xFF5D001E).withOpacity(0.2),
        side: const BorderSide(color: Color(0xFF5D001E)),
        label: Text(spell, style: GoogleFonts.spectral(color: Colors.white)),
        avatar: const Icon(Icons.auto_fix_high, size: 16, color: Color(0xFFE5B181)),
      )).toList(),
    );
  }
}
