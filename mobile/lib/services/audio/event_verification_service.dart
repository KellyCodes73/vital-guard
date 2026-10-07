/// Resultado del análisis de UNA ventana corta de audio.
/// (En la Fase 8 lo producirá el analizador experimental; por ahora lo simula el modo DEMO.)
class AnalysisWindow {
  final bool unusualPattern; // ¿esta ventana parece un patrón inusual?
  final double confidence; // 0..1
  final double noiseLevel; // 0..1 (ruido ambiental)
  final DateTime timestamp;

  const AnalysisWindow({
    required this.unusualPattern,
    required this.confidence,
    required this.noiseLevel,
    required this.timestamp,
  });
}

class VerificationResult {
  final bool confirmed;
  final double confidence;
  final String reason;

  const VerificationResult({required this.confirmed, required this.confidence, required this.reason});
}

/// Decide si un posible patrón se confirma, considerando:
/// persistencia, repetición, confianza del análisis y ruido ambiental.
/// No es un criterio clínico: es una verificación heurística para el MVP.
class EventVerificationService {
  final int minWindows;
  final double minUnusualRatio; // persistencia
  final int minConsecutive; // repetición
  final double minAvgConfidence; // confianza
  final double maxNoise; // ruido ambiental

  const EventVerificationService({
    this.minWindows = 4,
    this.minUnusualRatio = 0.6,
    this.minConsecutive = 3,
    this.minAvgConfidence = 0.6,
    this.maxNoise = 0.7,
  });

  VerificationResult evaluate(List<AnalysisWindow> windows) {
    if (windows.length < minWindows) {
      return const VerificationResult(
          confirmed: false, confidence: 0, reason: 'Muy pocas ventanas para verificar');
    }

    final noisy = windows.where((w) => w.noiseLevel > maxNoise).length;
    if (noisy / windows.length > 0.5) {
      return const VerificationResult(
          confirmed: false, confidence: 0, reason: 'Demasiado ruido ambiental');
    }

    final unusual = windows.where((w) => w.unusualPattern).toList();
    if (unusual.length / windows.length < minUnusualRatio) {
      return const VerificationResult(
          confirmed: false, confidence: 0, reason: 'El patrón no persiste');
    }

    var longest = 0;
    var current = 0;
    for (final w in windows) {
      current = w.unusualPattern ? current + 1 : 0;
      if (current > longest) longest = current;
    }
    if (longest < minConsecutive) {
      return const VerificationResult(
          confirmed: false, confidence: 0, reason: 'El patrón no se repite de forma consecutiva');
    }

    final avg = unusual.map((w) => w.confidence).reduce((a, b) => a + b) / unusual.length;
    if (avg < minAvgConfidence) {
      return VerificationResult(
          confirmed: false, confidence: avg, reason: 'Confianza del análisis insuficiente');
    }

    return VerificationResult(confirmed: true, confidence: avg, reason: 'Patrón persistente y repetido');
  }
}
