import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

/// Alarma local para despertar al usuario monitoreado cuando se detecta un posible patrón.
/// Suena como una sirena (sonido generado en memoria, sin archivos) y vibra hasta que
/// el usuario responde, o hasta que pasa el tiempo máximo.
class AlarmService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _autoStop;
  bool _active = false;
  Uint8List? _wav;

  /// Permite que la pantalla de monitoreo muestre el botón "DETENER ALARMA" mientras suena.
  final ValueNotifier<bool> activeNotifier = ValueNotifier<bool>(false);

  bool get isActive => _active;

  Future<void> start({Duration maxDuration = const Duration(minutes: 2)}) async {
    if (_active) return;
    _active = true;
    activeNotifier.value = true;
    _autoStop?.cancel();
    _autoStop = Timer(maxDuration, stop);

    try {
      // Usa el volumen de ALARMA del teléfono (no el de multimedia).
      await _player.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      _wav ??= _buildAlarmWav();
      await _player.play(BytesSource(_wav!, mimeType: 'audio/wav'));
    } catch (e) {
      debugPrint('No se pudo reproducir la alarma: $e');
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 600, 400, 600, 400, 900, 700], repeat: 0);
      }
    } catch (e) {
      debugPrint('No se pudo vibrar: $e');
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _active = false;
    activeNotifier.value = false;
    _autoStop?.cancel();
    _autoStop = null;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
    activeNotifier.dispose();
  }

  /// Sirena de 2 s (alterna 880 Hz y 660 Hz cada 0,25 s) en formato WAV PCM de 16 bits.
  /// Se repite en bucle sin cortes (los tramos empiezan y terminan en silencio).
  Uint8List _buildAlarmWav() {
    const sampleRate = 22050;
    const seconds = 2.0;
    final n = (sampleRate * seconds).round();
    final data = ByteData(44 + n * 2);

    void writeString(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    data.setUint32(40, n * 2, Endian.little);

    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final segment = (t / 0.25).floor();
      final freq = segment.isEven ? 880.0 : 660.0;
      final phase = (t % 0.25) / 0.25;
      final fade = min(1.0, min(phase, 1 - phase) * 12);
      final v = sin(2 * pi * freq * t) * 0.9 * fade;
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService();
  ref.onDispose(service.dispose);
  return service;
});
