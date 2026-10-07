import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/monitoring_repository.dart';
import '../domain/monitoring_models.dart';

class MonitoringState {
  final bool loading;
  final MonitoringConfig? config;
  final MonitoringSession? activeSession;
  final String? error;

  const MonitoringState({
    this.loading = false,
    this.config,
    this.activeSession,
    this.error,
  });

  bool get isActive => activeSession != null;
}

class MonitoringController extends Notifier<MonitoringState> {
  @override
  MonitoringState build() {
    // Si cambia el usuario (cierra sesión / entra otro), se reinicia el estado.
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null) return const MonitoringState();
    Future.microtask(refresh);
    return const MonitoringState(loading: true);
  }

  MonitoringRepository get _repo => ref.read(monitoringRepositoryProvider);

  Future<void> refresh() async {
    state = MonitoringState(
        loading: true, config: state.config, activeSession: state.activeSession);
    try {
      final config = await _repo.getConfig();
      final active = await _repo.getActive();
      state = MonitoringState(config: config, activeSession: active);
    } catch (e) {
      state = MonitoringState(
        config: state.config,
        activeSession: state.activeSession,
        error: apiErrorMessage(e),
      );
    }
  }

  /// Lanza excepción si falla (la pantalla muestra el mensaje).
  Future<void> saveConfig(MonitoringConfig config) async {
    final saved = await _repo.updateConfig(config);
    state = MonitoringState(config: saved, activeSession: state.activeSession);
  }

  Future<void> start({required bool demoMode}) async {
    final session = await _repo.start(demoMode: demoMode);
    state = MonitoringState(config: state.config, activeSession: session);
  }

  Future<void> stop() async {
    final session = state.activeSession;
    if (session == null) return;
    await _repo.stop(session.id);
    state = MonitoringState(config: state.config);
  }
}

final monitoringProvider =
    NotifierProvider<MonitoringController, MonitoringState>(MonitoringController.new);
