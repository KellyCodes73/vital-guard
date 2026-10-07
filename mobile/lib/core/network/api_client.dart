import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import 'server_settings.dart';
import 'token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Dirección del servidor elegida por el usuario (login -> Servidor), si existe.
      final custom = await ref.read(serverSettingsProvider).readCustom();
      if (custom != null) options.baseUrl = custom;
      final token = await ref.read(tokenStorageProvider).read();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));
  return dio;
});

/// Convierte cualquier error en un mensaje legible para el usuario.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.unknown:
        return 'No se pudo conectar con el servidor. Revisa que el backend esté '
            'encendido y que la dirección sea correcta (en Iniciar sesión, botón "Servidor").';
      default:
        break;
    }
    final code = error.response?.statusCode;
    if (code != null) return 'Error del servidor ($code).';
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}
