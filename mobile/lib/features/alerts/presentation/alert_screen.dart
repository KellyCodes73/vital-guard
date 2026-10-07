import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../monitoring/presentation/monitoring_controller.dart';
import '../../../services/location/location_service.dart';
import '../data/alert_repository.dart';
import '../data/event_repository.dart';
import '../domain/respiratory_event.dart';

enum _Phase { counting, resolving, escalating, resolved, notified, noHelper, failed }

/// Alerta local: el usuario tiene unos segundos para pulsar "ESTOY BIEN".
/// Si no responde, se escala la alerta a su persona de confianza.
class AlertScreen extends ConsumerStatefulWidget {
  final int eventId;
  const AlertScreen({super.key, required this.eventId});

  @override
  ConsumerState<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends ConsumerState<AlertScreen> {
  late final int _total;
  late int _remaining;
  Timer? _timer;
  _Phase _phase = _Phase.counting;
  String? _error;
  String? _locationNote;

  bool get _isFinal =>
      _phase == _Phase.resolved || _phase == _Phase.notified || _phase == _Phase.noHelper;

  @override
  void initState() {
    super.initState();
    _total = ref.read(monitoringProvider).config?.alertTimeoutSeconds ?? 30;
    _remaining = _total;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (_phase != _Phase.counting || !mounted) return;
    setState(() => _remaining--);
    if (_remaining <= 0) _escalate();
  }

  Future<void> _resolve() async {
    if (_phase != _Phase.counting) return;
    setState(() {
      _phase = _Phase.resolving;
      _error = null;
    });
    try {
      await ref.read(eventRepositoryProvider).resolve(widget.eventId);
      if (mounted) setState(() => _phase = _Phase.resolved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.counting;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  Future<void> _escalate() async {
    if (_phase != _Phase.counting && _phase != _Phase.failed) return;
    setState(() {
      _phase = _Phase.escalating;
      _error = null;
    });
    try {
      final ev = await ref.read(eventRepositoryProvider).escalate(widget.eventId);
      if (!mounted) return;
      setState(() {
        if (ev.status == EventStatuses.notified) {
          _phase = _Phase.notified;
          _locationNote = 'Compartiendo tu ubicación de forma temporal...';
        } else if (ev.status == EventStatuses.noHelper) {
          _phase = _Phase.noHelper;
        } else {
          _phase = _Phase.resolved;
        }
      });
      if (ev.status == EventStatuses.notified && ev.alertId != null) {
        _shareLocation(ev.alertId!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.failed;
          _error = apiErrorMessage(e);
        });
      }
    }
  }

  /// Comparte la ubicación actual SOLO durante esta alerta (queda disponible un tiempo limitado).
  Future<void> _shareLocation(int alertId) async {
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      await ref.read(alertRepositoryProvider).shareLocation(
            alertId: alertId,
            latitude: pos.latitude,
            longitude: pos.longitude,
            accuracyMeters: pos.accuracy,
          );
      if (mounted) {
        setState(() => _locationNote =
            'Ubicación compartida de forma temporal con tu persona de confianza.');
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() => _locationNote =
            '${e.message} Tu persona de confianza fue avisada, pero sin tu ubicación.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationNote = 'No se pudo compartir la ubicación: ${apiErrorMessage(e)}');
      }
    }
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  List<Color> get _gradient {
    switch (_phase) {
      case _Phase.counting:
      case _Phase.resolving:
      case _Phase.escalating:
      case _Phase.failed:
        return const [Color(0xFF7C2D12), Color(0xFFB45309)];
      default:
        return const [AppColors.deepBlue, AppColors.petrol];
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isFinal,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradient,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(padding: const EdgeInsets.all(24), child: _content()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (_phase) {
      case _Phase.counting:
      case _Phase.resolving:
        return _counting();
      case _Phase.escalating:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text('Avisando a tu persona de confianza...',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        );
      case _Phase.failed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.white),
            const SizedBox(height: 16),
            const Text('No se pudo enviar la alerta',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xCCFFFFFF))),
            const SizedBox(height: 24),
            _whiteButton('REINTENTAR', _escalate),
          ],
        );
      case _Phase.resolved:
        return _final(
          icon: Icons.check_circle_outline,
          title: 'Registrado como atendido',
          text: 'Qué bueno que estás bien. El monitoreo continúa.',
        );
      case _Phase.notified:
        return _final(
          icon: Icons.notifications_active_outlined,
          title: 'Se avisó a tu persona de confianza',
          text: 'Recibirá la alerta en su aplicación y podrá confirmar la recepción.',
          note: _locationNote,
        );
      case _Phase.noHelper:
        return _final(
          icon: Icons.person_off_outlined,
          title: 'No hay persona de confianza vinculada',
          text: 'No pudimos avisar a nadie. El evento quedó registrado en tu historial.',
        );
    }
  }

  Widget _counting() {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.warning_amber_rounded, size: 56, color: Colors.white),
        const SizedBox(height: 16),
        const Text('Se detectó un posible patrón respiratorio inusual',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text('Vital Guard identificó un patrón que requiere verificación.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
        const SizedBox(height: 28),
        SizedBox(
          width: 170,
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: (_remaining / _total).clamp(0.0, 1.0).toDouble(),
                  strokeWidth: 10,
                  color: Colors.white,
                  backgroundColor: const Color(0x33FFFFFF),
                ),
              ),
              Text('${_remaining < 0 ? 0 : _remaining}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 56, fontWeight: FontWeight.w300)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Si no respondes, avisaremos a tu persona de confianza.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xCCFFFFFF))),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFE0B2))),
        ],
        const Spacer(),
        SizedBox(
          height: 76,
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.deepBlue,
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            onPressed: _phase == _Phase.counting ? _resolve : null,
            child: _phase == _Phase.resolving
                ? const SizedBox(
                    width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3))
                : const Text('ESTOY BIEN'),
          ),
        ),
      ],
    );
  }

  Widget _final({
    required IconData icon,
    required String title,
    required String text,
    String? note,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 72, color: AppColors.sky),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
        if (note != null) ...[
          const SizedBox(height: 14),
          Text(note,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
        ],
        const SizedBox(height: 32),
        _whiteButton('VOLVER AL MONITOREO', _exit),
      ],
    );
  }

  Widget _whiteButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.deepBlue,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
