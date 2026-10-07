import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../services/audio/audio_capture_service.dart';
import '../../../services/location/location_service.dart';
import '../../../widgets/disclaimer_text.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/info_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../trusted_contact/presentation/trusted_contact_controller.dart';
import 'monitoring_controller.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Buenos días';
  if (hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

class MonitoredHomeScreen extends ConsumerStatefulWidget {
  const MonitoredHomeScreen({super.key});

  @override
  ConsumerState<MonitoredHomeScreen> createState() => _MonitoredHomeScreenState();
}

class _MonitoredHomeScreenState extends ConsumerState<MonitoredHomeScreen> {
  bool _demo = true;
  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Modo experimental: explica el uso del micrófono y pide permiso (el audio no se guarda ni se envía).
  Future<bool> _ensureMicrophoneConsent() async {
    final capture = ref.read(audioCaptureServiceProvider);
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso de micrófono'),
        content: const Text(
            'En modo experimental, Vital Guard analiza el sonido de tu entorno mientras duermes '
            'para identificar un posible patrón respiratorio inusual.\n\n'
            '• El audio se analiza en tu teléfono.\n'
            '• No se guarda ni se envía a ningún servidor: solo se calculan valores de intensidad.\n'
            '• Es una función experimental, no un dispositivo médico.\n\n'
            '¿Quieres continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (ok != true) return false;
    try {
      final granted = await capture.hasPermission();
      if (!granted) {
        _snack('Sin permiso de micrófono: concédelo en Ajustes o usa el modo demostración.');
      }
      return granted;
    } catch (_) {
      _snack('No se pudo acceder al micrófono.');
      return false;
    }
  }

  /// Pide el permiso de ubicación ANTES de dormir (durante una alerta ya no se podría pedir).
  Future<void> _ensureLocationConsent() async {
    final svc = ref.read(locationServiceProvider);
    try {
      if (await svc.hasPermission()) return;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Permiso de ubicación'),
          content: const Text(
              'Si no respondes a una alerta, Vital Guard compartirá tu ubicación con tu '
              'persona de confianza, solo de forma temporal mientras dure esa alerta. '
              'Nunca se comparte de forma permanente.\n\n'
              '¿Quieres permitir el acceso a tu ubicación?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Permitir')),
          ],
        ),
      );
      if (ok != true) {
        _snack('Sin permiso de ubicación: tu persona de confianza será avisada, pero sin tu ubicación.');
        return;
      }
      final granted = await svc.requestPermission();
      if (!granted) {
        _snack('Permiso de ubicación denegado: la alerta se enviará sin ubicación.');
      }
    } catch (_) {
      // Un problema con la ubicación nunca debe impedir iniciar el monitoreo.
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      if (!_demo && !await _ensureMicrophoneConsent()) return;
      await _ensureLocationConsent();
      await ref.read(monitoringProvider.notifier).start(demoMode: _demo);
      if (mounted) context.push('/monitoring/active');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final m = ref.watch(monitoringProvider);
    final active = m.activeSession;
    final cfg = m.config;

    final tc = ref.watch(trustedContactProvider).current;
    final String contacto;
    if (tc == null) {
      contacto = 'Sin vincular · toca para invitar';
    } else if (tc.isPending) {
      contacto = 'Invitación pendiente · toca para ver el código';
    } else {
      contacto = '${tc.helperUser?.fullName ?? 'Persona de confianza'} · Vinculación activa';
    }

    final String horario;
    if (cfg == null) {
      horario = m.loading ? 'Cargando...' : 'No disponible';
    } else {
      horario = '${cfg.startTime} – ${cfg.endTime} · '
          '${cfg.scheduledEnabled ? 'Programado' : 'Sin programar'}';
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${_greeting()}, ${user?.name ?? ''}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepBlue)),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.deepBlue, AppColors.petrol],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        active != null ? Icons.nightlight_round : Icons.nightlight_outlined,
                        size: 44,
                        color: AppColors.sky,
                      ),
                      const SizedBox(height: 12),
                      Text(active != null ? 'Monitoreo activo' : 'Monitoreo inactivo',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        active != null
                            ? 'Desde las ${formatHm(active.startedAt.toLocal())}'
                            : 'Listo para cuidar tu descanso',
                        style: const TextStyle(color: Color(0xB3FFFFFF)),
                      ),
                    ],
                  ),
                ),
                if (m.error != null) ...[
                  const SizedBox(height: 14),
                  ErrorBanner(m.error!),
                  TextButton(
                    onPressed: () => ref.read(monitoringProvider.notifier).refresh(),
                    child: const Text('Reintentar'),
                  ),
                ],
                const SizedBox(height: 20),
                if (active == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      title: const Text('Modo demostración'),
                      subtitle: Text(_demo
                          ? 'Los resultados serán simulados con los botones de prueba.'
                          : 'Modo experimental: analiza el micrófono de tu teléfono (no es un modelo médico).'),
                      value: _demo,
                      onChanged: (v) => setState(() => _demo = v),
                    ),
                  ),
                SizedBox(
                  height: 72,
                  child: FilledButton.icon(
                    icon: Icon(active != null ? Icons.visibility : Icons.play_arrow_rounded,
                        size: 32),
                    label: Text(active != null ? 'VER MONITOREO' : 'INICIAR MONITOREO'),
                    onPressed: _busy
                        ? null
                        : (active != null
                            ? () => context.push('/monitoring/active')
                            : _start),
                  ),
                ),
                const SizedBox(height: 20),
                InfoCard(
                  icon: Icons.people_outline,
                  title: 'Persona de confianza',
                  subtitle: contacto,
                  onTap: () => context.push('/trusted-contact'),
                ),
                const SizedBox(height: 12),
                InfoCard(
                  icon: Icons.schedule,
                  title: 'Horario de sueño',
                  subtitle: horario,
                  onTap: cfg == null ? null : () => context.push('/monitoring/config'),
                ),
                const SizedBox(height: 12),
                InfoCard(
                  icon: Icons.history,
                  title: 'Historial de eventos',
                  subtitle: 'Revisa los eventos anteriores',
                  onTap: () => context.push('/history'),
                ),
                const SizedBox(height: 24),
                const DisclaimerText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
