import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_router.dart';
import '../../core/network/api_client.dart';
import '../../features/alerts/presentation/alert_inbox_controller.dart';

/// Notificaciones push (Firebase Cloud Messaging). Solo Android.
/// En el navegador no hace nada: ahí el auxiliador sigue viendo las alertas por consulta cada 5 s.
class PushService {
  PushService(this._ref);

  final Ref _ref;
  static bool _firebaseReady = false;

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// Se llama una vez en main(). Si Firebase no está configurado, la app sigue funcionando sin push.
  static Future<void> initFirebase() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase no disponible: $e');
    }
  }

  /// Pide permiso de notificaciones, registra el token del teléfono en el backend
  /// y deja listo el manejo de las notificaciones.
  Future<void> start() async {
    if (kIsWeb || !_firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(); // Android 13+: pide POST_NOTIFICATIONS
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Permiso de notificaciones denegado.');
        return;
      }

      final token = await messaging.getToken();
      if (token != null) await _sendToken(token);
      _tokenSub ??= messaging.onTokenRefresh.listen(_sendToken);

      // App abierta: no se muestra la notificación del sistema; se actualiza la bandeja al instante.
      _foregroundSub ??= FirebaseMessaging.onMessage.listen((_) {
        _ref.read(alertInboxProvider.notifier).refresh(silent: true);
      });

      // El usuario toca la notificación con la app en segundo plano.
      _openedSub ??= FirebaseMessaging.onMessageOpenedApp.listen(_openAlert);

      // La app estaba cerrada y se abrió al tocar la notificación.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openAlert(initial);
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  Future<void> _sendToken(String token) async {
    try {
      await _ref.read(dioProvider).put('/api/users/me/fcm-token', data: {'token': token});
    } catch (e) {
      debugPrint('No se pudo registrar el token FCM: ${apiErrorMessage(e)}');
    }
  }

  void _openAlert(RemoteMessage message) {
    final alertId = int.tryParse('${message.data['alertId'] ?? ''}');
    if (alertId == null) return;
    _ref.read(routerProvider).push('/helper-alert/$alertId');
  }

  void dispose() {
    _tokenSub?.cancel();
    _foregroundSub?.cancel();
    _openedSub?.cancel();
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(service.dispose);
  return service;
});
