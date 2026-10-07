import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/respiratory_event.dart';

class EventRepository {
  final Dio _dio;
  EventRepository(this._dio);

  RespiratoryEvent _event(dynamic data) =>
      RespiratoryEvent.fromJson(Map<String, dynamic>.from(data as Map));

  Future<RespiratoryEvent> create({
    required int sessionId,
    required double confidence,
    required String source,
  }) async {
    final res = await _dio.post('/api/events', data: {
      'sessionId': sessionId,
      'confidence': confidence,
      'source': source,
    });
    return _event(res.data);
  }

  Future<List<RespiratoryEvent>> list() async {
    final res = await _dio.get('/api/events');
    return (res.data as List).map(_event).toList();
  }

  Future<RespiratoryEvent> resolve(int id) async {
    final res = await _dio.post('/api/events/$id/resolve');
    return _event(res.data);
  }

  Future<RespiratoryEvent> escalate(int id) async {
    final res = await _dio.post('/api/events/$id/escalate');
    return _event(res.data);
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(dioProvider)),
);
