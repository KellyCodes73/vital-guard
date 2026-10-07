import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/alert_repository.dart';
import '../domain/alert_info.dart';

class AlertInboxState {
  final bool loaded;
  final List<AlertInfo> alerts;
  final String? error;

  const AlertInboxState({this.loaded = false, this.alerts = const [], this.error});

  List<AlertInfo> get active => alerts.where((a) => a.isActive).toList();
}

/// Bandeja de alertas del auxiliador. Se actualiza sola cada 5 segundos
/// (respaldo de las notificaciones push, que se agregan en la Fase 7B).
class AlertInboxController extends Notifier<AlertInboxState> {
  bool _disposed = false;

  @override
  AlertInboxState build() {
    _disposed = false;
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null) return const AlertInboxState();

    Future.microtask(refresh);
    final timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh(silent: true));
    ref.onDispose(() {
      _disposed = true;
      timer.cancel();
    });
    return const AlertInboxState();
  }

  Future<void> refresh({bool silent = false}) async {
    try {
      final alerts = await ref.read(alertRepositoryProvider).list();
      if (_disposed) return;
      state = AlertInboxState(loaded: true, alerts: alerts);
    } catch (e) {
      if (_disposed || silent) return;
      state = AlertInboxState(loaded: state.loaded, alerts: state.alerts, error: apiErrorMessage(e));
    }
  }
}

final alertInboxProvider =
    NotifierProvider<AlertInboxController, AlertInboxState>(AlertInboxController.new);
