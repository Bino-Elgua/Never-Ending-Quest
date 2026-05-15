import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api_client.dart';

class ToolkitProvider extends StateNotifier<bool> {
  final ApiClient _apiClient;

  ToolkitProvider(this._apiClient) : super(false);

  Future<List<dynamic>> getPacks() async {
    try {
      final response = await _apiClient.get('/api/toolkit/packs');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMonsters(String packName) async {
    try {
      final response = await _apiClient.get('/api/toolkit/monsters?pack=$packName');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<bool> generateMonsters(String packName, String style, List<String> monsters) async {
    state = true; // loading
    try {
      final response = await _apiClient.post('/api/toolkit/generate', data: {
        'pack_name': packName,
        'style': style,
        'monsters': monsters,
      });
      state = false;
      return response.data['success'] == true;
    } catch (e) {
      state = false;
      return false;
    }
  }
}

final toolkitProvider = StateNotifierProvider<ToolkitProvider, bool>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ToolkitProvider(apiClient);
});
