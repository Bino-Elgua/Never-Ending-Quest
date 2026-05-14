import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _openaiController;
  late TextEditingController _openrouterController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _openaiController = TextEditingController(text: settings.openAiKey);
    _openrouterController = TextEditingController(text: settings.openRouterKey);
  }

  @override
  void dispose() {
    _openaiController.dispose();
    _openrouterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Arcane Settings', style: GoogleFonts.cinzel()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('AI Configuration'),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'OpenAI API Key',
            controller: _openaiController,
            hint: 'sk-...',
            onChanged: (val) => ref.read(settingsProvider.notifier).updateOpenAiKey(val, ref),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'OpenRouter API Key',
            controller: _openrouterController,
            hint: 'sk-or-...',
            onChanged: (val) => ref.read(settingsProvider.notifier).updateOpenRouterKey(val, ref),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text('Use OpenRouter Smart Routing', style: GoogleFonts.spectral(fontSize: 18)),
            subtitle: const Text('Routes tasks to specialized models (Claude, Gemini, etc.)'),
            value: settings.useOpenRouter,
            activeColor: const Color(0xFFE5B181),
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleOpenRouter(val, ref),
          ),
          const SizedBox(height: 40),
          _buildSectionHeader('Application'),
          ListTile(
            title: const Text('Version'),
            trailing: const Text('0.3.5 (Alpha)'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Clear Cache'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.cinzel(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFE5B181),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spectral(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF5D001E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5B181)),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
