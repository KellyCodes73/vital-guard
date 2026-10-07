import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/monitoring_models.dart';

class MonitoringRepository {
  final Dio _dio;
  MonitoringRepository(this._dio);

  Map<String, dynamic> _map(dynamic data) => Map<String, dynamic>.from(data as Map);

  Future<MonitoringConfig> getConfig() async {
    final res = await _dio.get('/api/monitoring/config');
    return MonitoringConfig.fromJson(_map(res.data));
  }

  Future<MonitoringConfig> updateConfig(MonitoringConfig config) async {
    final res = await _dio.put('/api/monitoring/config', data: config.toJson());
    return MonitoringConfig.fromJson(_map(res.data));
  }

  Future<MonitoringSession> start({required bool demoMode}) async {
    final res = await _dio.post('/api/monitoring/start', data: {'demoMode': demoMode});
    return MonitoringSession.fromJson(_map(res.data));
  }

  Future<MonitoringSession> stop(int sessionId) async {
    final res = await _dio.post('/api/monitoring/$sessionId/stop');
    return MonitoringSession.fromJson(_map(res.data));
  }

  /// Devuelve null si no hay monitoreo activo (el backend responde 204).
  Future<MonitoringSession?> getActive() async {
    final res = await _dio.get('/api/monitoring/active');
    final data = res.data;
    if (res.statusCode == 204 || data is! Map) return null;
    return MonitoringSession.fromJson(Map<String, dynamic>.from(data));
  }
}

final monitoringRepositoryProvider = Provider<MonitoringRepository>(
  (ref) => MonitoringRepository(ref.watch(dioProvider)),
);
