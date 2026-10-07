import 'dart:math';

import 'event_verification_service.dart';

enum DemoScenario {
  /// Patrón que persiste y se repite: la verificación lo confirma.
  unusualPattern,

  /// Pocos sobresaltos con mucho ruido: la verificación lo descarta.
  falseAlarm,
}

/// MODO DEMO: genera resultados SIMULADOS de análisis (no hay audio ni modelo real).
/// Se sustituirá por el analizador experimental en la Fase 8.
class DemoPatternSimulator {
  static const int windowCount = 5;
  final Random _random = Random();

  Stream<AnalysisWindow> simulate(DemoScenario scenario) async* {
    for (var i = 0; i < windowCount; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      yield _window(scenario, i);
    }
  }

  AnalysisWindow _window(DemoScenario scenario, int index) {
    switch (scenario) {
      case DemoScenario.unusualPattern:
        return AnalysisWindow(
          unusualPattern: true,
          confidence: 0.78 + _random.nextDouble() * 0.14,
          noiseLevel: 0.1 + _random.nextDouble() * 0.2,
          timestamp: DateTime.now(),
        );
      case DemoScenario.falseAlarm:
        final unusual = index == 0 || index == 2;
        return AnalysisWindow(
          unusualPattern: unusual,
          confidence: 0.45 + _random.nextDouble() * 0.15,
          noiseLevel: 0.6 + _random.nextDouble() * 0.3,
          timestamp: DateTime.now(),
        );
    }
  }
}
