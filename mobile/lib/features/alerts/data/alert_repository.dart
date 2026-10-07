import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/alert_info.dart';

class AlertRepository {
  final Dio _dio;
  AlertRepository(this._dio);

  AlertInfo _alert(dynamic data) => AlertInfo.fromJson(Map<String, dynamic>.from(data as Map));

  /// Auxiliador: alertas recientes.
  Future<List<AlertInfo>> list() async {
    final res = await _dio.get('/api/alerts');
    return (res.data as List).map(_alert).toList();
  }

  /// Auxiliador: detalle (con ubicación temporal si sigue vigente).
  Future<AlertInfo> get(int id) async {
    final res = await _dio.get('/api/alerts/$id');
    return _alert(res.data);
  }

  /// Auxiliador: confirma la recepción.
  Future<AlertInfo> acknowledge(int id) async {
    final res = await _dio.post('/api/alerts/$id/acknowledge');
    return _alert(res.data);
  }

  /// Usuario monitoreado: comparte su ubicación durante su alerta.
  Future<void> shareLocation({
    required int alertId,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
  }) async {
    await _dio.post('/api/alerts/$alertId/location', data: {
      'latitude': latitude,
      'longitude': longitude,
      'accuracyMeters': ?accuracyMeters,
    });
  }
}

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepository(ref.watch(dioProvider)),
);
