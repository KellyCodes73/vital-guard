import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vital_guard/services/audio/audio_preprocessing_service.dart';
import 'package:vital_guard/services/audio/event_verification_service.dart';
import 'package:vital_guard/services/audio/respiratory_analysis_service.dart';

/// Ventana de 20 tramos de 100 ms: [burstFrames] tramos con sonido y el resto con ruido de fondo.
AudioFeatures _window({required double base, double burst = 0, int burstFrames = 0}) {
  final frames = List<double>.generate(20, (i) => i < burstFrames ? burst : base);
  return AudioFeatures(
    frameRms: frames,
    meanRms: frames.reduce((a, b) => a + b) / frames.length,
    peakRms: frames.reduce(max),
    timestamp: DateTime.now(),
  );
}

List<AudioFeatures> _breathing(int n) =>
    List.generate(n, (_) => _window(base: 0.003, burst: 0.05, burstFrames: 6));

List<AudioFeatures> _silence(int n) => List.generate(n, (_) => _window(base: 0.003));

List<AudioFeatures> _loudNoise(int n) => List.generate(n, (_) => _window(base: 0.4));

/// Pasa las ventanas por el analizador y la verificación, como hace la app.
({int? firstUnusual, int? firstConfirmed}) _simulate(List<AudioFeatures> windows) {
  final analyzer = ExperimentalEnergyAnalyzer();
  const verifier = EventVerificationService();
  final history = <AnalysisWindow>[];
  int? firstUnusual;
  int? firstConfirmed;
  for (var i = 0; i < windows.length; i++) {
    final w = analyzer.analyze(windows[i]);
    history.add(w);
    if (history.length > 5) history.removeAt(0);
    if (w.unusualPattern) {
      firstUnusual ??= i;
      if (verifier.evaluate(history).confirmed) firstConfirmed ??= i;
    }
  }
  return (firstUnusual: firstUnusual, firstConfirmed: firstConfirmed);
}

Uint8List _sineBytes({required double seconds, double amplitude = 0.5}) {
  final n = (16000 * seconds).round();
  final data = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    final v = (amplitude * 32767 * sin(2 * pi * 440 * i / 16000)).round();
    data.setInt16(i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  group('AudioPreprocessingService', () {
    test('calcula bien la intensidad aunque los fragmentos lleguen cortados', () async {
      final bytes = _sineBytes(seconds: 4);
      final chunks = <Uint8List>[];
      for (var i = 0; i < bytes.length; i += 1001) {
        chunks.add(bytes.sublist(i, min(i + 1001, bytes.length)));
      }
      final windows =
          await const AudioPreprocessingService().windows(Stream.fromIterable(chunks)).toList();
      expect(windows.length, 2); // 4 s = 2 ventanas de 2 s
      expect(windows.first.frameRms.length, 20);
      expect(windows.first.meanRms, closeTo(0.5 / sqrt(2), 0.02));
    });

    test('el silencio da intensidad casi cero', () async {
      final silence = Uint8List(16000 * 2 * 2); // 2 s de ceros
      final windows =
          await const AudioPreprocessingService().windows(Stream.value(silence)).toList();
      expect(windows.length, 1);
      expect(windows.first.meanRms, lessThan(0.001));
    });
  });

  group('Analizador experimental + verificación', () {
    test('sonido de base seguido de una pausa prolongada se confirma como posible patrón', () {
      final result = _simulate([..._breathing(10), ..._silence(6)]);
      expect(result.firstUnusual, 10); // primera ventana silenciosa tras el sonido
      expect(result.firstConfirmed, isNotNull);
      expect(result.firstConfirmed!, inInclusiveRange(11, 14));
    });

    test('un cuarto en silencio (sin sonido previo) no genera ninguna alerta', () {
      final result = _simulate(_silence(20));
      expect(result.firstUnusual, isNull);
      expect(result.firstConfirmed, isNull);
    });

    test('un ruido fuerte y constante seguido de silencio no se confirma', () {
      final result = _simulate([..._loudNoise(10), ..._silence(6)]);
      expect(result.firstConfirmed, isNull);
    });

    test('mientras hay sonido de base normal no se detecta nada', () {
      final result = _simulate(_breathing(20));
      expect(result.firstUnusual, isNull);
    });
  });
}
