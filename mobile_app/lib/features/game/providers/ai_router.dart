import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:never_ending_quest/features/game/providers/ai_provider.dart';
import 'package:never_ending_quest/core/socket_service.dart';

enum InferenceDestination { local, cloud }

class AIInferenceRouter {
  final AIProviderNotifier localAi;
  final SocketService socketService;

  AIInferenceRouter({required this.localAi, required this.socketService});

  InferenceDestination _route(String prompt, String? taskType) {
    // Logic from TECHNICAL SPECIFICATIONS:
    // Local: NPC barks, basic environmental descriptions, input validation.
    // Cloud: Complex narrative shifts, summaries, game state validation.
    
    if (taskType == 'bark' || taskType == 'validation' || prompt.length < 50) {
      return InferenceDestination.local;
    }
    return InferenceDestination.cloud;
  }

  Future<void> processPrompt(String prompt, {String? taskType, String? campaignId}) async {
    final destination = _route(prompt, taskType);
    
    if (destination == InferenceDestination.local) {
      await localAi.generateResponse(prompt);
    } else {
      socketService.send('user_input', {
        'input': prompt,
        'campaign_id': campaignId ?? 'default_room',
        'task_type': taskType ?? 'narration'
      });
    }
  }
}

final aiRouter = Provider((ref) {
  return AIInferenceRouter(
    localAi: ref.watch(aiProvider.notifier),
    socketService: ref.watch(socketServiceProvider),
  );
});
