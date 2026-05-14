import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/campaigns/campaign_list_screen.dart';
import 'features/game/screens/narration_screen.dart';
import 'features/game/screens/character_sheet_screen.dart';
import 'features/game/screens/combat_grid_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: NeverEndingQuestApp(),
    ),
  );
}

class NeverEndingQuestApp extends StatelessWidget {
  const NeverEndingQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeverEndingQuest',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF5D001E),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D001E),
          brightness: Brightness.dark,
          secondary: const Color(0xFFE5B181),
          surface: const Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.cinzelTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const NarrationScreen(),
    const CharacterSheetScreen(),
    const CombatGridScreen(),
    const CampaignListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: const Color(0xFFE5B181),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Quest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Hero',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Combat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Archive',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
