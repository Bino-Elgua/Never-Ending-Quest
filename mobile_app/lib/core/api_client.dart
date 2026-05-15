import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConfig.baseUrl);
});

class ApiClient {
  final String baseUrl;
  final Dio _dio;

  ApiClient({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('Requesting: ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('Response from ${response.requestOptions.uri}: ${response.statusCode}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('Error from ${e.requestOptions.uri}: ${e.message}');
        return handler.next(e);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      if (e.response?.statusCode == 404) {
        return Exception(
          'Cannot connect to game server. '
          'Make sure the backend is running: python run_web.py\n'
          'Expected at: $baseUrl'
        );
      }
      return Exception('API Error: ${e.response?.statusCode} - ${e.response?.data}');
    }
    return Exception('Network Error: ${e.message}');
  }
}
