class ApiConfig {
  static const String host = String.fromEnvironment(
    'API_HOST', defaultValue: 'http://127.0.0.1:8357'
  );
  static const String baseUrl = '$host';
}
