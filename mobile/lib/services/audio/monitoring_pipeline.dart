import 'dart:async';

import 'audio_capture_service.dart';
import 'audio_preprocessing_service.dart';
import 'event_verification_service.dart';
import 'respiratory_analysis_service.dart';

/// Orquesta el análisis: captura -> preprocesamiento -> análisis -> verificación.
/// Cuando la verificación confirma un posible patrón, avisa con [onConfirmed].
class MonitoringPipeline {
  MonitoringPipeline({
    required this.capture,
    required this.preprocessing,
    required this.analyzer,
    required this.verifier,
    required this.onLevel,
    required this.onWindow,
    required this.onConfirmed,
    required this.onError,
    this.cooldown = const Duration(seconds: 90),
    this.historyLength = 5,
  });

  final AudioCaptureService capture;
  final AudioPreprocessingService preprocessing;
  final RespiratoryAnalysisService analyzer;
  final EventVerificationService verifier;

  /// Intensidad de cada tramo de 100 ms (medidor de nivel).
  final void Function(double frameRms) onLevel;

  /// Resultado de cada ventana de 2 s.
  final void Function(AnalysisWindow window, AnalyzerDiagnostics diagnostics, bool verifying) onWindow;

  /// Se llama cuando la verificación confirma un posible patrón.
  final void Function(VerificationResult result) onConfirmed;

  final void Function(Object error) onError;

  /// Tras una detección se pausa el análisis un tiempo, para no repetir la alerta.
  final Duration cooldown;
  final int historyLength;

  StreamSubscription<AudioFeatures>? _subscription;
  final List<AnalysisWindow> _history = [];
  DateTime? _pausedUntil;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      final bytes = await capture.start();
      if (!_running) {
        await capture.stop();
        return;
      }
      _subscription = preprocessing
          .windows(bytes, onFrame: (rms) {
            if (_running) onLevel(rms);
          })
          .listen(_onFeatures, onError: (Object e) {
            if (_running) onError(e);
          });
    } catch (e) {
      _running = false;
      onError(e);
    }
  }

  Future<void> stop() async {
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    await capture.stop();
    _history.clear();
    analyzer.reset();
  }

  void _onFeatures(AudioFeatures features) {
    if (!_running) return;

    final now = DateTime.now();
    final pausedUntil = _pausedUntil;
    if (pausedUntil != null && now.isBefore(pausedUntil)) return;

    final window = analyzer.analyze(features);
    _history.add(window);
    if (_history.length > historyLength) _history.removeAt(0);

    var verifying = false;
    if (window.unusualPattern) {
      verifying = true;
      final result = verifier.evaluate(_history);
      if (result.confirmed) {
        _history.clear();
        analyzer.reset();
        _pausedUntil = now.add(cooldown);
        onWindow(window, analyzer.diagnostics, false);
        onConfirmed(result);
        return;
      }
    }
    onWindow(window, analyzer.diagnostics, verifying);
  }
}
