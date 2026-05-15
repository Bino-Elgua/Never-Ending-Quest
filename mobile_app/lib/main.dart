import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/campaigns/campaign_list_screen.dart';
import 'features/game/screens/narration_screen.dart';
import 'features/game/screens/character_sheet_screen.dart';
import 'features/game/screens/combat_grid_screen.dart';
import 'features/game/screens/journal_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/toolkit/screens/toolkit_screen.dart';

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
      debugShowCheckedModeBanner: false,
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
        textTheme: GoogleFonts.spectralTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
          bodyLarge: GoogleFonts.spectral(fontSize: 18),
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
    const JournalScreen(),
    const AdventureMasterHub(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
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
        unselectedItemColor: Colors.white24,
        selectedLabelStyle: GoogleFonts.cinzel(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cinzel(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            activeIcon: Icon(Icons.auto_awesome, color: Color(0xFFE5B181)),
            label: 'QUEST',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: Color(0xFFE5B181)),
            label: 'HERO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            activeIcon: Icon(Icons.grid_view_rounded, color: Color(0xFFE5B181)),
            label: 'TACTICS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu),
            activeIcon: Icon(Icons.history_edu, color: Color(0xFFE5B181)),
            label: 'JOURNAL',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.castle_outlined),
            activeIcon: Icon(Icons.castle, color: Color(0xFFE5B181)),
            label: 'MASTER',
          ),
        ],
      ),
    );
  }
}

class AdventureMasterHub extends StatelessWidget {
  const AdventureMasterHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('MASTER HUB', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFFE5B181),
            labelColor: const Color(0xFFE5B181),
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.cinzel(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'CAMPAIGNS', icon: Icon(Icons.map)),
              Tab(text: 'TOOLKIT', icon: Icon(Icons.build)),
              Tab(text: 'ARCANE', icon: Icon(Icons.settings)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CampaignListScreen(),
            ToolkitScreen(),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}
