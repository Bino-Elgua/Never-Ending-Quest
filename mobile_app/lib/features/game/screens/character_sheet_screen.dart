import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_status_provider.dart';
import '../providers/plot_provider.dart';
import '../models/character.dart';
import '../../../core/haptic_service.dart';
import '../../../core/socket_service.dart';

class CharacterSheetScreen extends ConsumerWidget {
  const CharacterSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('ADVENTURERS', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5B181),
            labelColor: const Color(0xFFE5B181),
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'HERO', icon: Icon(Icons.person)),
              Tab(text: 'PARTY', icon: Icon(Icons.group)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HeroTab(),
            _PartyTab(),
          ],
        ),
      ),
    );
  }
}

class _HeroTab extends ConsumerStatefulWidget {
  const _HeroTab();

  @override
  ConsumerState<_HeroTab> createState() => _HeroTabState();
}

class _HeroTabState extends ConsumerState<_HeroTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(gameStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status.characters.isEmpty) {
          return const Center(child: Text('No active characters found.'));
        }
        final character = status.characters[0];
        
        final filteredInventory = character.inventory.where((item) {
          return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 (item.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CharacterCardView(character: character, isPlayer: true),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Equipment & Artifacts'),
                _StorageButton(),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                hintStyle: GoogleFonts.spectral(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              style: GoogleFonts.spectral(color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildInventoryCards(filteredInventory),
            const SizedBox(height: 24),
            if (character.spells != null && character.spells!.isNotEmpty) ...[
              _buildSectionHeader('Arcane Spells'),
              const SizedBox(height: 8),
              _buildSpellCards(character.spells!),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE5B181))),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
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

  Widget _buildInventoryCards(List<InventoryItem> inventory) {
    return Column(
      children: inventory.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          onTap: () => HapticService.light(),
          leading: const Icon(Icons.shield_outlined, color: Color(0xFFE5B181)),
          title: Text(item.name, style: GoogleFonts.spectral(fontSize: 18, fontWeight: FontWeight.w600)),
          subtitle: item.description != null ? Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
          trailing: Text(item.quantity != null ? 'x${item.quantity}' : '${item.weight ?? 0} lbs', style: const TextStyle(fontSize: 12, color: Colors.white38)),
        ),
      )).toList(),
    );
  }

  Widget _buildSpellCards(List<String> spells) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: spells.map((spell) => ActionChip(
        onPressed: () => HapticService.medium(),
        backgroundColor: const Color(0xFF5D001E).withOpacity(0.2),
        side: const BorderSide(color: Color(0xFF5D001E)),
        label: Text(spell, style: GoogleFonts.spectral(color: Colors.white)),
        avatar: const Icon(Icons.auto_fix_high, size: 16, color: Color(0xFFE5B181)),
      )).toList(),
    );
  }
}

class _PartyTab extends ConsumerWidget {
  const _PartyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final npcs = ref.watch(npcProvider);

    if (npcs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 64, color: Colors.white10),
            const SizedBox(height: 16),
            Text('Travelling alone for now...', style: GoogleFonts.cinzel(color: Colors.white38)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(npcProvider.notifier).refresh(),
              child: const Text('REFRESH PARTY'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(npcProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: npcs.length,
        itemBuilder: (context, index) {
          return _CharacterCardView(character: npcs[index], isPlayer: false);
        },
      ),
    );
  }
}

class _CharacterCardView extends StatelessWidget {
  final Character character;
  final bool isPlayer;

  const _CharacterCardView({required this.character, required this.isPlayer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildIdentityCard(context),
        const SizedBox(height: 16),
        _buildStatGrid(),
        if (!isPlayer) const Divider(height: 48, color: Colors.white10),
      ],
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPlayer ? const Color(0xFF5D001E) : Colors.green.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: isPlayer ? const Color(0xFF5D001E) : Colors.green.withOpacity(0.2),
                  child: Icon(isPlayer ? Icons.person : Icons.support_agent, size: 40, color: Colors.white),
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
                      if (character.alignment != null)
                        Text(character.alignment!, style: GoogleFonts.spectral(fontSize: 12, color: Colors.white38)),
                    ],
                  ),
                ),
                if (character.armorClass != null)
                  _buildMiniStat('AC', '${character.armorClass}'),
              ],
            ),
            const SizedBox(height: 20),
            _buildHPBar(),
            if (character.xp != null) ...[
              const SizedBox(height: 12),
              _buildXPBar(),
            ],
            if (character.currency != null) ...[
              const SizedBox(height: 16),
              _buildCurrencyRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.cinzel(fontSize: 10, color: Colors.white38)),
          Text(value, style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFE5B181))),
        ],
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

  Widget _buildXPBar() {
    if (character.nextLevelXp == null || character.nextLevelXp == 0) return const SizedBox.shrink();
    final percent = (character.xp! / character.nextLevelXp!).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EXPERIENCE', style: GoogleFonts.cinzel(fontSize: 10, color: Colors.white38)),
            Text('${character.xp} / ${character.nextLevelXp}', style: GoogleFonts.spectral(fontSize: 10, color: Colors.white38)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white.withOpacity(0.02),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE5B181)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyRow() {
    final c = character.currency!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCurrencyItem('${c.gold}', 'GP', Colors.amber),
        _buildCurrencyItem('${c.silver}', 'SP', Colors.blueGrey),
        _buildCurrencyItem('${c.copper}', 'CP', Colors.orangeAccent),
      ],
    );
  }

  Widget _buildCurrencyItem(String val, String unit, Color color) {
    return Row(
      children: [
        Text(val, style: GoogleFonts.spectral(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 4),
        Text(unit, style: GoogleFonts.cinzel(fontSize: 10, color: color.withOpacity(0.7), fontWeight: FontWeight.bold)),
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
}

class _StorageButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showStorageModal(context, ref),
      icon: const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFFE5B181)),
      label: Text('STORAGE', style: GoogleFonts.cinzel(fontSize: 12, color: const Color(0xFFE5B181))),
    );
  }

  void _showStorageModal(BuildContext context, WidgetRef ref) {
    HapticService.light();
    final socket = ref.read(socketServiceProvider);
    socket.send('request_storage_data', {});

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _StorageView(socket: socket),
    );
  }
}

class _StorageView extends StatefulWidget {
  final SocketService socket;
  const _StorageView({required this.socket});

  @override
  State<_StorageView> createState() => _StorageViewState();
}

class _StorageViewState extends State<_StorageView> {
  List<dynamic>? _storageData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.socket.stream.listen((event) {
      if (event['event'] == 'storage_data_response') {
        if (mounted) {
          setState(() {
            _storageData = event['data']?['storage'] ?? [];
            _loading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text('SAFE KEEPINGS', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE5B181))),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_storageData == null || _storageData!.isEmpty)
            const Expanded(child: Center(child: Text('No external storage found.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _storageData!.length,
                itemBuilder: (context, index) {
                  final container = _storageData![index];
                  return Card(
                    color: Colors.black26,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Text(container['name'], style: GoogleFonts.cinzel(color: const Color(0xFFE5B181))),
                      subtitle: Text(container['location'], style: GoogleFonts.spectral(fontSize: 12, color: Colors.white38)),
                      children: [
                        ... (container['contents'] as List? ?? []).map((item) => ListTile(
                          title: Text(item['item_name'], style: GoogleFonts.spectral()),
                          trailing: Text('x${item['quantity']}', style: const TextStyle(color: Colors.white54)),
                        )).toList(),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
