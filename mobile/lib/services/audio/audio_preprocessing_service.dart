import 'dart:math';
import 'dart:typed_data';

/// Características de una ventana de audio. Solo contiene VALORES DE INTENSIDAD:
/// el audio original ya se descartó en este punto.
class AudioFeatures {
  final List<double> frameRms; // intensidad (RMS, 0..1) de cada tramo de 100 ms
  final double meanRms;
  final double peakRms;
  final DateTime timestamp;

  const AudioFeatures({
    required this.frameRms,
    required this.meanRms,
    required this.peakRms,
    required this.timestamp,
  });
}

/// Convierte audio PCM de 16 bits (little-endian, mono) en ventanas de características.
/// No guarda audio: solo acumula la energía del tramo actual.
class AudioPreprocessingService {
  const AudioPreprocessingService({
    this.sampleRate = 16000,
    this.frameMs = 100,
    this.framesPerWindow = 20, // 20 x 100 ms = ventanas de 2 s
  });

  final int sampleRate;
  final int frameMs;
  final int framesPerWindow;

  int get frameSamples => sampleRate * frameMs ~/ 1000;
  double get windowSeconds => framesPerWindow * frameMs / 1000;

  /// [onFrame] se llama cada 100 ms con la intensidad actual (para el medidor de nivel).
  Stream<AudioFeatures> windows(
    Stream<Uint8List> pcm16, {
    void Function(double frameRms)? onFrame,
  }) async* {
    final frames = <double>[];
    var sumSquares = 0.0;
    var count = 0;
    int? pending; // primer byte de una muestra cuando el fragmento termina "cortado"

    await for (final chunk in pcm16) {
      for (var i = 0; i < chunk.length; i++) {
        final b = chunk[i];
        if (pending == null) {
          pending = b;
          continue;
        }
        var sample = pending | (b << 8);
        pending = null;
        if (sample >= 32768) sample -= 65536;
        final s = sample / 32768.0;
        sumSquares += s * s;
        count++;

        if (count == frameSamples) {
          final rms = sqrt(sumSquares / count);
          sumSquares = 0.0;
          count = 0;
          onFrame?.call(rms);
          frames.add(rms);
          if (frames.length == framesPerWindow) {
            yield _features(frames);
            frames.clear();
          }
        }
      }
    }
  }

  AudioFeatures _features(List<double> frames) {
    final copy = List<double>.from(frames);
    final mean = copy.reduce((a, b) => a + b) / copy.length;
    final peak = copy.reduce(max);
    return AudioFeatures(frameRms: copy, meanRms: mean, peakRms: peak, timestamp: DateTime.now());
  }
}
