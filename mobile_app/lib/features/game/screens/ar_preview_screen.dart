import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ARMonsterPreviewScreen extends StatelessWidget {
  final String monsterName;

  const ARMonsterPreviewScreen({super.key, required this.monsterName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Preview', style: GoogleFonts.cinzel()),
      ),
      body: Stack(
        children: [
          // Placeholder for actual AR View (ARCore/ARKit)
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.camera_alt, size: 100, color: Colors.white24),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5B181)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monsterName,
                    style: GoogleFonts.cinzel(fontSize: 24, color: const Color(0xFFE5B181)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Positioning 3D Model in your room...',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D001E)),
                    child: const Text('Close Preview'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
