import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/config/app_router.dart';
import '../../../core/network/api_client.dart';
import '../../../services/audio/audio_capture_service.dart';
import '../../../services/audio/audio_preprocessing_service.dart';
import '../../../services/audio/event_verification_service.dart';
import '../../../services/audio/monitoring_pipeline.dart';
import '../../../services/audio/respiratory_analysis_service.dart';
import '../../alerts/data/event_repository.dart';
import '../../alerts/domain/respiratory_event.dart';
import '../domain/monitoring_models.dart';
import 'monitoring_controller.dart';

class PipelineState {
  final bool running;
  final double level; // 0..1 (medidor)
  final bool baselineReady;
  final int silentSeconds;
  final double threshold;
  final bool verifying;
  final String? error;

  const PipelineState({
    this.running = false,
    this.level = 0,
    this.baselineReady = false,
    this.silentSeconds = 0,
    this.threshold = 0.012,
    this.verifying = false,
    this.error,
  });

  PipelineState copyWith({
    bool? running,
    double? level,
    bool? baselineReady,
    int? silentSeconds,
    double? threshold,
    bool? verifying,
    String? error,
    bool clearError = false,
  }) =>
      PipelineState(
        running: running ?? this.running,
        level: level ?? this.level,
        baselineReady: baselineReady ?? this.baselineReady,
        silentSeconds: silentSeconds ?? this.silentSeconds,
        threshold: threshold ?? this.threshold,
        verifying: verifying ?? this.verifying,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Mantiene el análisis de audio activo mientras exista un monitoreo EXPERIMENTAL en curso
/// (sesión activa sin modo demostración), sin importar en qué pantalla esté el usuario.
class PipelineController extends Notifier<PipelineState> {
  MonitoringPipeline? _pipeline;
  int? _sessionId;
  int _generation = 0;

  @override
  PipelineState build() {
    ref.listen<MonitoringState>(monitoringProvider, (previous, next) => _sync(next.activeSession));
    ref.onDispose(() {
      _generation++;
      _pipeline?.stop();
      _pipeline = null;
      _disableWakelock();
    });
    Future.microtask(() => _sync(ref.read(monitoringProvider).activeSession));
    return const PipelineState();
  }

  void _sync(MonitoringSession? session) {
    if (session == null || session.demoMode) {
      if (_pipeline != null) _stopPipeline();
      return;
    }
    if (_pipeline != null && _sessionId == session.id) return;
    if (_pipeline != null) _stopPipeline();
    _startPipeline(session);
  }

  Future<void> _startPipeline(MonitoringSession session) async {
    final gen = ++_generation;
    _sessionId = session.id;

    final pipeline = MonitoringPipeline(
      capture: ref.read(audioCaptureServiceProvider),
      preprocessing: const AudioPreprocessingService(),
      analyzer: ExperimentalEnergyAnalyzer(),
      verifier: const EventVerificationService(),
      onLevel: (rms) {
        if (gen != _generation) return;
        state = state.copyWith(level: (rms * 12).clamp(0.0, 1.0).toDouble());
      },
      onWindow: (window, diagnostics, verifying) {
        if (gen != _generation) return;
        state = state.copyWith(
          baselineReady: diagnostics.baselineReady,
          silentSeconds: diagnostics.silentWindows * 2,
          threshold: diagnostics.activeThreshold,
          verifying: verifying,
        );
      },
      onConfirmed: (result) => _onConfirmed(gen, session.id, result),
      onError: (error) {
        if (gen != _generation) return;
        state = state.copyWith(running: false, error: error.toString());
      },
    );

    _pipeline = pipeline;
    state = const PipelineState(running: true);
    try {
      await WakelockPlus.enable(); // la pantalla no se apaga mientras se monitorea
    } catch (e) {
      debugPrint('No se pudo mantener la pantalla encendida: $e');
    }
    await pipeline.start();
  }

  void _stopPipeline() {
    _generation++;
    final pipeline = _pipeline;
    _pipeline = null;
    _sessionId = null;
    state = const PipelineState();
    pipeline?.stop();
    _disableWakelock();
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Sin importancia: solo libera la pantalla.
    }
  }

  /// La verificación confirmó un posible patrón: se registra el evento y se abre la alerta local.
  Future<void> _onConfirmed(int gen, int sessionId, VerificationResult result) async {
    try {
      final event = await ref.read(eventRepositoryProvider).create(
            sessionId: sessionId,
            confidence: result.confidence,
            source: EventSources.experimental,
          );
      if (gen != _generation) return;
      ref.read(routerProvider).push('/alert/${event.id}');
    } catch (e) {
      if (gen != _generation) return;
      state = state.copyWith(error: apiErrorMessage(e));
    }
  }
}

final pipelineProvider = NotifierProvider<PipelineController, PipelineState>(PipelineController.new);
