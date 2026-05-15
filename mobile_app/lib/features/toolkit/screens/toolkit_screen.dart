import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/toolkit_provider.dart';

class ToolkitScreen extends ConsumerStatefulWidget {
  const ToolkitScreen({super.key});

  @override
  ConsumerState<ToolkitScreen> createState() => _ToolkitScreenState();
}

class _ToolkitScreenState extends ConsumerState<ToolkitScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _packController = TextEditingController(text: 'photorealistic');
  final TextEditingController _styleController = TextEditingController(text: 'photorealistic');
  List<dynamic> _monsters = [];
  final List<String> _selectedMonsters = [];
  bool _isLoadingMonsters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMonsters();
  }

  Future<void> _loadMonsters() async {
    setState(() => _isLoadingMonsters = true);
    final monsters = await ref.read(toolkitProvider.notifier).getMonsters(_packController.text);
    setState(() {
      _monsters = monsters;
      _isLoadingMonsters = false;
    });
  }

  Future<void> _generateSelected() async {
    if (_selectedMonsters.isEmpty) return;
    
    final success = await ref.read(toolkitProvider.notifier).generateMonsters(
      _packController.text,
      _styleController.text,
      _selectedMonsters,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Generation started!' : 'Generation failed')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _packController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEVELOPER TOOLKIT', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4CAF50),
          labelColor: const Color(0xFF4CAF50),
          tabs: const [
            Tab(text: 'MONSTERS', icon: Icon(Icons.pets)),
            Tab(text: 'NPCS', icon: Icon(Icons.people)),
            Tab(text: 'PACKS', icon: Icon(Icons.inventory_2)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonsterGenerator(),
          _buildNPCGenerator(),
          _buildPackManager(),
        ],
      ),
    );
  }

  Widget _buildMonsterGenerator() {
    final isGenerating = ref.watch(toolkitProvider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Monster Generator', Icons.auto_awesome),
          const SizedBox(height: 16),
          _buildTextField('Pack Name', 'e.g. photorealistic', _packController),
          const SizedBox(height: 12),
          _buildTextField('Style', 'photorealistic', _styleController),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select Monsters:', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(onPressed: _loadMonsters, icon: const Icon(Icons.refresh, size: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: _isLoadingMonsters 
              ? const Center(child: CircularProgressIndicator())
              : _monsters.isEmpty
                ? const Center(child: Text('No monsters found', style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    itemCount: _monsters.length,
                    itemBuilder: (context, index) {
                      final monster = _monsters[index];
                      final name = monster['name'] ?? 'Unknown';
                      final id = monster['id'] ?? '';
                      return CheckboxListTile(
                        title: Text(name),
                        value: _selectedMonsters.contains(id),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) _selectedMonsters.add(id);
                            else _selectedMonsters.remove(id);
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : _generateSelected,
              icon: isGenerating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bolt),
              label: Text(isGenerating ? 'GENERATING...' : 'GENERATE SELECTED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPCGenerator() {
    return const Center(child: Text('NPC Generator coming soon'));
  }

  Widget _buildPackManager() {
    return const Center(child: Text('Pack Manager coming soon'));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFA500)),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFFA500))),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cinzel(fontSize: 12, color: Colors.white54)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
