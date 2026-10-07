import 'dart:math';

import 'audio_preprocessing_service.dart';
import 'event_verification_service.dart';

/// Datos internos del analizador, solo para mostrarlos en pantalla (ajuste y demostración).
class AnalyzerDiagnostics {
  final bool baselineReady; // ¿hubo suficiente sonido "de base" antes del silencio?
  final int silentWindows; // ventanas silenciosas consecutivas
  final double activeThreshold; // umbral de intensidad que cuenta como "sonido"

  const AnalyzerDiagnostics({
    required this.baselineReady,
    required this.silentWindows,
    required this.activeThreshold,
  });
}

/// Analiza una ventana de audio y dice si parece un posible patrón respiratorio inusual.
/// Se puede reemplazar por un modelo real (TensorFlow Lite / LiteRT) sin tocar el resto de la app.
abstract class RespiratoryAnalysisService {
  AnalysisWindow analyze(AudioFeatures features);
  AnalyzerDiagnostics get diagnostics;
  void reset();
}

/// ANALIZADOR EXPERIMENTAL (NO CLÍNICO).
/// Heurística de energía: detecta que hubo sonido de base (como una respiración o ronquido)
/// y que después se produjo una pausa prolongada. No diagnostica nada: solo identifica
/// un "posible patrón respiratorio inusual" para pedir verificación al usuario.
class ExperimentalEnergyAnalyzer implements RespiratoryAnalysisService {
  ExperimentalEnergyAnalyzer({
    this.minActiveThreshold = 0.012,
    this.noiseFloorMultiplier = 2.5,
    this.activeRatioForSound = 0.10,
    this.silentRatio = 0.03,
    this.loudLimit = 0.25,
    this.historyWindows = 15, // 30 s de memoria para la línea base
    this.minActiveWindows = 4, // al menos 8 s de sonido en esos 30 s
    this.noiseHistoryWindows = 30, // 60 s para estimar el ruido de fondo
  });

  final double minActiveThreshold;
  final double noiseFloorMultiplier;
  final double activeRatioForSound;
  final double silentRatio;
  final double loudLimit;
  final int historyWindows;
  final int minActiveWindows;
  final int noiseHistoryWindows;

  final List<double> _quietLevels = [];
  final List<bool> _activeHistory = [];
  int _silentRun = 0;
  bool _baselineReady = false;
  double _threshold = 0.012;

  @override
  AnalysisWindow analyze(AudioFeatures f) {
    // Ruido de fondo: nivel "tranquilo" (percentil 20) de los últimos 60 s.
    final sorted = List<double>.of(f.frameRms)..sort();
    _quietLevels.add(sorted[(sorted.length * 0.2).floor()]);
    if (_quietLevels.length > noiseHistoryWindows) _quietLevels.removeAt(0);
    final noiseFloor = max(0.002, _percentile(_quietLevels, 0.2));
    _threshold = max(minActiveThreshold, noiseFloor * noiseFloorMultiplier);

    final activeFrames = f.frameRms.where((r) => r > _threshold).length;
    final activityRatio = activeFrames / f.frameRms.length;
    final isActive = activityRatio >= activeRatioForSound && f.meanRms < loudLimit;
    final isSilent = activityRatio < silentRatio;

    // La línea base se calcula con las ventanas ANTERIORES a esta.
    _baselineReady = _activeHistory.where((a) => a).length >= minActiveWindows;

    _silentRun = isSilent ? _silentRun + 1 : 0;
    _activeHistory.add(isActive);
    if (_activeHistory.length > historyWindows) _activeHistory.removeAt(0);

    final unusual = isSilent && _baselineReady;
    return AnalysisWindow(
      unusualPattern: unusual,
      confidence: unusual ? min(0.95, 0.55 + 0.08 * _silentRun) : 0.2,
      noiseLevel: (f.meanRms / 0.25).clamp(0.0, 1.0).toDouble(),
      timestamp: f.timestamp,
    );
  }

  @override
  AnalyzerDiagnostics get diagnostics => AnalyzerDiagnostics(
        baselineReady: _baselineReady,
        silentWindows: _silentRun,
        activeThreshold: _threshold,
      );

  @override
  void reset() {
    _quietLevels.clear();
    _activeHistory.clear();
    _silentRun = 0;
    _baselineReady = false;
  }

  double _percentile(List<double> values, double p) {
    final sorted = List<double>.of(values)..sort();
    return sorted[(p * (sorted.length - 1)).floor()];
  }
}
