import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/trusted_contact_models.dart';

class TrustedContactRepository {
  final Dio _dio;
  TrustedContactRepository(this._dio);

  TrustedContactLink _link(dynamic data) =>
      TrustedContactLink.fromJson(Map<String, dynamic>.from(data as Map));

  Future<List<TrustedContactLink>> list() async {
    final res = await _dio.get('/api/trusted-contacts');
    final data = res.data as List;
    return data.map(_link).toList();
  }

  Future<TrustedContactLink> invite() async {
    final res = await _dio.post('/api/trusted-contacts/invite');
    return _link(res.data);
  }

  Future<TrustedContactLink> accept(String code) async {
    final res = await _dio.post('/api/trusted-contacts/accept', data: {'code': code});
    return _link(res.data);
  }

  Future<void> revoke(int id) async {
    await _dio.delete('/api/trusted-contacts/$id');
  }
}

final trustedContactRepositoryProvider = Provider<TrustedContactRepository>(
  (ref) => TrustedContactRepository(ref.watch(dioProvider)),
);
