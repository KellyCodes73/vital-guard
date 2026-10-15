import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../services/alerts/alarm_service.dart';
import '../../../services/audio/demo_pattern_simulator.dart';
import '../../../services/audio/event_verification_service.dart';
import '../../alerts/data/event_repository.dart';
import '../../alerts/domain/respiratory_event.dart';
import 'monitoring_controller.dart';
import 'pipeline_controller.dart';

class MonitoringActiveScreen extends ConsumerStatefulWidget {
  const MonitoringActiveScreen({super.key});

  @override
  ConsumerState<MonitoringActiveScreen> createState() => _MonitoringActiveScreenState();
}

class _MonitoringActiveScreenState extends ConsumerState<MonitoringActiveScreen> {
  static const String _idleText = 'Analizando señales de audio...';

  Timer? _timer;
  bool _stopping = false;
  bool _detecting = false;
  String _statusText = _idleText;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    setState(() {
      _stopping = true;
      _error = null;
    });
    try {
      await ref.read(alarmServiceProvider).stop();
      await ref.read(monitoringProvider.notifier).stop();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  /// MODO DEMO: simula ventanas de análisis, las pasa por la verificación y,
  /// si se confirma, registra el evento y abre la alerta local.
  Future<void> _simulate(DemoScenario scenario, int sessionId) async {
    setState(() {
      _detecting = true;
      _error = null;
    });
    try {
      final windows = <AnalysisWindow>[];
      await for (final w in DemoPatternSimulator().simulate(scenario)) {
        windows.add(w);
        if (!mounted) return;
        setState(() => _statusText =
            'Verificando posible patrón (${windows.length}/${DemoPatternSimulator.windowCount})...');
      }

      final result = const EventVerificationService().evaluate(windows);
      if (!result.confirmed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Patrón no confirmado (${result.reason}). Se continúa el monitoreo.'),
        ));
        return;
      }

      final event = await ref.read(eventRepositoryProvider).create(
            sessionId: sessionId,
            confidence: result.confidence,
            source: EventSources.demo,
          );
      if (mounted) context.push('/alert/${event.id}');
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _detecting = false;
          _statusText = _idleText;
        });
      }
    }
  }

  Widget _banner(String text, {Color bg = const Color(0x33FFC107), Color fg = const Color(0xFFFFE082)}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _demoPanel(int sessionId) {
    const outline = Color(0x80FFFFFF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DFFC107)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Modo demostración',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFE082), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Simula el resultado del análisis (no hay un modelo médico real).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: outline),
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: _detecting ? null : () => _simulate(DemoScenario.unusualPattern, sessionId),
            child: const Text('Simular patrón inusual'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: outline),
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: _detecting ? null : () => _simulate(DemoScenario.falseAlarm, sessionId),
            child: const Text('Simular falsa alarma (ruido)'),
          ),
        ],
      ),
    );
  }

  /// Medidor del micrófono y datos del análisis experimental.
  Widget _experimentalPanel(PipelineState p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4DFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nivel de sonido',
              style: TextStyle(color: Color(0xCCFFFFFF), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: p.level,
              minHeight: 10,
              color: AppColors.sky,
              backgroundColor: const Color(0x33FFFFFF),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sonido de base: ${p.baselineReady ? 'detectado' : 'esperando'} · Silencio: ${p.silentSeconds} s',
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
          ),
          if (p.pausedUntil != null && p.pausedUntil!.isAfter(DateTime.now()))
            Text('En pausa hasta las ${formatHm(p.pausedUntil!)} (alerta reciente)',
                style: const TextStyle(
                    color: Color(0xFFFFE082), fontSize: 12, fontWeight: FontWeight.w600)),
          Text('Umbral de actividad: ${p.threshold.toStringAsFixed(3)}',
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
          if (p.error != null) ...[
            const SizedBox(height: 8),
            Text(p.error!, style: const TextStyle(color: Color(0xFFFFB4AB), fontSize: 13)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(monitoringProvider).activeSession;
    final pipeline = ref.watch(pipelineProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hay un monitoreo activo.'),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    }

    var elapsed = DateTime.now().difference(session.startedAt);
    if (elapsed.isNegative) elapsed = Duration.zero;

    final bool demo = session.demoMode;
    final String status;
    if (demo) {
      status = _statusText;
    } else if (pipeline.error != null) {
      status = 'No se pudo usar el micrófono';
    } else if (pipeline.verifying) {
      status = 'Posible patrón detectado: verificando...';
    } else if (pipeline.pausedUntil != null && pipeline.pausedUntil!.isAfter(DateTime.now())) {
      status = 'Análisis en pausa tras la última alerta';
    } else if (pipeline.running) {
      status = 'Escuchando... (el audio no se guarda)';
    } else {
      status = 'Iniciando el micrófono...';
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepBlue, AppColors.petrol],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (demo)
                      _banner('MODO DEMO – los resultados son simulados')
                    else
                      _banner('MODO EXPERIMENTAL – análisis de audio no clínico',
                          bg: const Color(0x337CC6E8), fg: AppColors.sky),
                    const SizedBox(height: 24),
                    ValueListenableBuilder<bool>(
                      valueListenable: ref.read(alarmServiceProvider).activeNotifier,
                      builder: (context, ringing, _) {
                        if (!ringing) return const SizedBox.shrink();
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0x33FF5252),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x99FF8A80)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.alarm, color: Color(0xFFFF8A80)),
                                  SizedBox(width: 8),
                                  Text('ALARMA SONANDO',
                                      style: TextStyle(
                                          color: Color(0xFFFF8A80),
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.deepBlue,
                                ),
                                onPressed: () => ref.read(alarmServiceProvider).stop(),
                                child: const Text('DETENER ALARMA'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Icon(Icons.nightlight_round, size: 56, color: AppColors.sky),
                    const SizedBox(height: 12),
                    const Text('Monitoreo en curso',
                        style: TextStyle(
                            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(formatDuration(elapsed),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Text('Inicio: ${formatHm(session.startedAt.toLocal())}',
                        style: const TextStyle(color: Color(0xB3FFFFFF))),
                    const SizedBox(height: 22),
                    Text(status,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (demo)
                      const SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          color: AppColors.sky,
                          backgroundColor: Color(0x33FFFFFF),
                        ),
                      )
                    else
                      _experimentalPanel(pipeline),
                    const SizedBox(height: 8),
                    Text(
                      demo
                          ? 'En modo demostración no se usa el micrófono: los resultados los simulan los botones.'
                          : 'El audio se analiza en tu teléfono y no se guarda ni se envía. '
                              'Deja el teléfono cerca y con la pantalla encendida.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                    ),
                    if (demo) ...[
                      const SizedBox(height: 22),
                      _demoPanel(session.id),
                    ],
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB4AB))),
                      ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.deepBlue,
                      ),
                      onPressed: (_stopping || _detecting) ? null : _stop,
                      child: _stopping
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('DETENER MONITOREO'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
