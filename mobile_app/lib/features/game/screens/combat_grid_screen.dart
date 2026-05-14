import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/combat_provider.dart';
import '../../../core/haptic_service.dart';

class CombatGridScreen extends ConsumerWidget {
  const CombatGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combatAsync = ref.watch(combatStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tactical Grid', style: GoogleFonts.cinzel()),
      ),
      body: combatAsync.when(
        data: (state) => _CombatGridView(state: state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CombatGridView extends StatefulWidget {
  final CombatState state;

  const _CombatGridView({required this.state});

  @override
  State<_CombatGridView> createState() => _CombatGridViewState();
}

class _CombatGridViewState extends State<_CombatGridView> {
  Combatant? _selectedCombatant;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Round: ${widget.state.turn}', style: GoogleFonts.cinzel(fontSize: 18)),
              ElevatedButton(
                onPressed: () => HapticService.medium(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D001E)),
                child: const Text('End Turn'),
              ),
            ],
          ),
        ),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (_selectedCombatant != null && _selectedCombatant!.isPlayer) {
                  if (details.primaryVelocity! > 0) {
                    _performSwipeAction('Right/Attack');
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(32),
                child: _buildGrid(),
              ),
            ),
          ),
        ),
        _buildCombatantList(),
      ],
    );
  }

  void _performSwipeAction(String action) {
    HapticService.heavy();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Action performed: $action'), duration: const Duration(seconds: 1)),
    );
  }

  Widget _buildGrid() {
    const int gridSize = 10;
    return Column(
      children: List.generate(gridSize, (y) {
        return Row(
          children: List.generate(gridSize, (x) {
            final combatant = _getCombatantAt(x, y);
            return DragTarget<Combatant>(
              onWillAccept: (data) => combatant == null,
              onAccept: (data) {
                HapticService.light();
                // Logic to update position via API/WebSocket
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white10),
                    color: (x + y) % 2 == 0 ? Colors.white.withOpacity(0.02) : Colors.transparent,
                  ),
                  child: combatant != null ? _buildToken(combatant) : null,
                );
              },
            );
          }),
        );
      }),
    );
  }

  Combatant? _getCombatantAt(int x, int y) {
    try {
      return widget.state.combatants.firstWhere((c) => c.position[0] == x && c.position[1] == y);
    } catch (e) {
      return null;
    }
  }

  Widget _buildToken(Combatant combatant) {
    return Draggable<Combatant>(
      data: combatant,
      feedback: Opacity(opacity: 0.7, child: _tokenCore(combatant)),
      childWhenDragging: const SizedBox(width: 60, height: 60),
      onDragStarted: () {
        HapticService.light();
        setState(() => _selectedCombatant = combatant);
      },
      child: _tokenCore(combatant),
    );
  }

  Widget _tokenCore(Combatant combatant) {
    final isSelected = _selectedCombatant?.id == combatant.id;
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticService.light();
          setState(() => _selectedCombatant = combatant);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: combatant.isPlayer ? const Color(0xFF5D001E) : Colors.black,
            border: Border.all(
              color: isSelected ? Colors.yellow : (combatant.isPlayer ? const Color(0xFFE5B181) : Colors.red),
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Center(
            child: Text(
              combatant.name.substring(0, 1),
              style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombatantList() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF5D001E))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: widget.state.combatants.length,
        itemBuilder: (context, index) {
          final c = widget.state.combatants[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedCombatant = c),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedCombatant?.id == c.id ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: _selectedCombatant?.id == c.id ? Border.all(color: const Color(0xFFE5B181)) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(c.name, style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: c.hp / c.maxHp,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(c.isPlayer ? Colors.green : Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text('HP: ${c.hp}/${c.maxHp}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
