import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

class AudioCaptureException implements Exception {
  final String message;
  const AudioCaptureException(this.message);

  @override
  String toString() => message;
}

/// Captura del micrófono. Entrega audio PCM de 16 bits (mono) como un flujo de bytes.
/// El audio NO se guarda en ningún archivo: solo pasa por el preprocesamiento.
abstract class AudioCaptureService {
  /// Pide (si hace falta) el permiso del micrófono.
  Future<bool> hasPermission();

  Future<Stream<Uint8List>> start();

  Future<void> stop();
}

class RecordAudioCaptureService implements AudioCaptureService {
  static const int sampleRate = 16000;

  AudioRecorder? _recorder;

  @override
  Future<bool> hasPermission() async {
    final recorder = AudioRecorder();
    try {
      return await recorder.hasPermission();
    } finally {
      await recorder.dispose();
    }
  }

  @override
  Future<Stream<Uint8List>> start() async {
    await stop();
    final recorder = AudioRecorder();
    try {
      if (!await recorder.hasPermission()) {
        throw const AudioCaptureException('No hay permiso de micrófono.');
      }
      final stream = await recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ));
      _recorder = recorder;
      return stream;
    } catch (e) {
      await recorder.dispose();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder != null) {
      try {
        await recorder.stop();
      } finally {
        await recorder.dispose();
      }
    }
  }
}

final audioCaptureServiceProvider =
    Provider<AudioCaptureService>((ref) => RecordAudioCaptureService());
