class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:6001',
  );

  static const String apiBasePath = 'Api/V1.0';

  static const String hubsBasePath = 'hubs';

  static String get restBaseUrl => '$baseUrl/$apiBasePath';

  static String get hubsBaseUrl => '$baseUrl/$hubsBasePath';
}

extension ResolveUploadUrl on String? {
  String? resolveUploadUrl() {
    final value = this;
    if (value == null || value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://')) return value;
    return '${ApiConfig.baseUrl}$value';
  }
}
