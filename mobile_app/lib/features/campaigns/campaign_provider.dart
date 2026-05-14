import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:never_ending_quest/core/api_client.dart';

final campaignsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/campaigns/list');
  return response.data;
});

final saveGamesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/campaigns/saves');
  return response.data;
});
