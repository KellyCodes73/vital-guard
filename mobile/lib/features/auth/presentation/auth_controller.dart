import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  const AuthState({required this.status, this.user});
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restoreSession);
    return const AuthState(status: AuthStatus.unknown);
  }

  /// Al abrir la app: si hay token guardado, intenta recuperar la sesión.
  Future<void> _restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 1200)); // deja ver el splash
    final storage = ref.read(tokenStorageProvider);
    try {
      final token = await storage.read();
      if (token == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await ref.read(authRepositoryProvider).me();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await storage.delete();
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    final res = await ref.read(authRepositoryProvider).login(email, password);
    await ref.read(tokenStorageProvider).write(res.token);
    state = AuthState(status: AuthStatus.authenticated, user: res.user);
  }

  Future<void> register({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
    required Role role,
  }) async {
    final res = await ref.read(authRepositoryProvider).register(
          name: name,
          lastName: lastName,
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          role: role,
        );
    await ref.read(tokenStorageProvider).write(res.token);
    state = AuthState(status: AuthStatus.authenticated, user: res.user);
  }

  Future<void> logout() async {
    // El teléfono deja de recibir las alertas de esta cuenta.
    try {
      await ref.read(dioProvider).delete('/api/users/me/fcm-token');
    } catch (_) {
      // Si no hay conexión, igual se cierra la sesión.
    }
    await ref.read(tokenStorageProvider).delete();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
