import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/app_user.dart';

class AuthResult {
  final String token;
  final AppUser user;
  const AuthResult(this.token, this.user);
}

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _parse(res.data);
  }

  Future<AuthResult> register({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required Role role,
  }) async {
    final res = await _dio.post('/api/auth/register', data: {
      'name': name,
      'lastName': lastName,
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'role': role.apiValue,
    });
    return _parse(res.data);
  }

  Future<AppUser> me() async {
    final res = await _dio.get('/api/users/me');
    return AppUser.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  AuthResult _parse(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AuthResult(
      map['token'] as String,
      AppUser.fromJson(Map<String, dynamic>.from(map['user'] as Map)),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
