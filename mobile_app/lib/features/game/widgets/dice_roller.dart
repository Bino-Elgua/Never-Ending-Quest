import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/haptic_service.dart';

class DiceService {
  static final Random _random = Random();

  static int roll(int sides) {
    return _random.nextInt(sides) + 1;
  }
}

class DiceRollerSheet extends StatefulWidget {
  const DiceRollerSheet({super.key});

  @override
  State<DiceRollerSheet> createState() => _DiceRollerSheetState();
}

class _DiceRollerSheetState extends State<DiceRollerSheet> {
  int? _lastRoll;
  int? _lastSides;

  void _rollDice(int sides) {
    HapticService.heavy();
    setState(() {
      _lastSides = sides;
      _lastRoll = DiceService.roll(sides);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ARCANE DICE',
            style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFE5B181)),
          ),
          const SizedBox(height: 24),
          if (_lastRoll != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5D001E), width: 3),
              ),
              child: Column(
                children: [
                  Text(
                    '$_lastRoll',
                    style: GoogleFonts.cinzel(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'D$_lastSides',
                    style: GoogleFonts.spectral(fontSize: 14, color: Colors.white38),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildDiceButton(4, Icons.details),
              _buildDiceButton(6, Icons.square),
              _buildDiceButton(8, Icons.change_history),
              _buildDiceButton(10, Icons.hexagon),
              _buildDiceButton(12, Icons.hexagon_outlined),
              _buildDiceButton(20, Icons.diamond),
              _buildDiceButton(100, Icons.circle),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDiceButton(int sides, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _rollDice(sides),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF5D001E).withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5D001E)),
            ),
            child: Icon(icon, color: const Color(0xFFE5B181)),
          ),
        ),
        const SizedBox(height: 4),
        Text('D$sides', style: GoogleFonts.spectral(fontSize: 12)),
      ],
    );
  }
}
