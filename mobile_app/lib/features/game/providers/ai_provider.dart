import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AIProviderSource { remote, local }

class AIProviderState {
  final AIProviderSource source;
  final bool isModelLoaded;
  final String? modelName;

  AIProviderState({
    required this.source,
    this.isModelLoaded = false,
    this.modelName,
  });

  AIProviderState copyWith({
    AIProviderSource? source,
    bool? isModelLoaded,
    String? modelName,
  }) {
    return AIProviderState(
      source: source ?? this.source,
      isModelLoaded: isModelLoaded ?? this.isModelLoaded,
      modelName: modelName ?? this.modelName,
    );
  }
}

class AIProviderNotifier extends StateNotifier<AIProviderState> {
  AIProviderNotifier() : super(AIProviderState(source: AIProviderSource.remote));

  void setSource(AIProviderSource source) {
    state = state.copyWith(source: source);
  }

  Future<void> loadLocalModel(String name) async {
    // Placeholder for llama_cpp_dart / ollama_dart initialization
    state = state.copyWith(isModelLoaded: false);
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading
    state = state.copyWith(isModelLoaded: true, modelName: name);
  }

  Future<String> generateResponse(String prompt) async {
    if (state.source == AIProviderSource.remote) {
      // Logic handled via WebSocket in NarrationScreen for now
      return "Processing via remote AI...";
    } else {
      if (!state.isModelLoaded) return "Local model not loaded.";
      // Placeholder for actual local LLM inference
      return "[Local AI Response to: $prompt]";
    }
  }
}

final aiProvider = StateNotifierProvider<AIProviderNotifier, AIProviderState>((ref) {
  return AIProviderNotifier();
});
