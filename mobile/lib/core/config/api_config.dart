class ApiConfig {
  /// URL base del backend.
  /// - Chrome / Windows en la misma PC: http://localhost:8081
  /// - Teléfono real: usar la IP local de la PC, por ejemplo
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8081
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8081',
  );
}
