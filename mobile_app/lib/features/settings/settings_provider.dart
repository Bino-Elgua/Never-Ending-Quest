import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:never_ending_quest/core/api_client.dart';

class SettingsState {
  final String openAiKey;
  final String openRouterKey;
  final bool useOpenRouter;

  SettingsState({
    this.openAiKey = '',
    this.openRouterKey = '',
    this.useOpenRouter = false,
  });

  SettingsState copyWith({
    String? openAiKey,
    String? openRouterKey,
    bool? useOpenRouter,
  }) {
    return SettingsState(
      openAiKey: openAiKey ?? this.openAiKey,
      openRouterKey: openRouterKey ?? this.openRouterKey,
      useOpenRouter: useOpenRouter ?? this.useOpenRouter,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      openAiKey: prefs.getString('openai_key') ?? '',
      openRouterKey: prefs.getString('openrouter_key') ?? '',
      useOpenRouter: prefs.getBool('use_openrouter') ?? false,
    );
  }

  Future<void> updateOpenAiKey(String key, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_key', key);
    state = state.copyWith(openAiKey: key);
    await _syncWithBackend(ref);
  }

  Future<void> updateOpenRouterKey(String key, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openrouter_key', key);
    state = state.copyWith(openRouterKey: key);
    await _syncWithBackend(ref);
  }

  Future<void> toggleOpenRouter(bool value, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_openrouter', value);
    state = state.copyWith(useOpenRouter: value);
    await _syncWithBackend(ref);
  }

  Future<void> _syncWithBackend(WidgetRef ref) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      await apiClient.post('api/v1/config/update-keys', data: {
        'openai_key': state.openAiKey,
        'openrouter_key': state.openRouterKey,
        'use_openrouter': state.useOpenRouter,
      });
    } catch (e) {
      print('Failed to sync keys with backend: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
