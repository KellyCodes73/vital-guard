import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../widgets/error_banner.dart';
import '../domain/monitoring_models.dart';
import 'monitoring_controller.dart';

class MonitoringConfigScreen extends ConsumerStatefulWidget {
  const MonitoringConfigScreen({super.key});

  @override
  ConsumerState<MonitoringConfigScreen> createState() => _MonitoringConfigScreenState();
}

class _MonitoringConfigScreenState extends ConsumerState<MonitoringConfigScreen> {
  late String _start;
  late String _end;
  late bool _scheduled;
  late double _timeout;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = ref.read(monitoringProvider).config;
    _start = c?.startTime ?? '23:00';
    _end = c?.endTime ?? '07:00';
    _scheduled = c?.scheduledEnabled ?? false;
    _timeout = (c?.alertTimeoutSeconds ?? 30).clamp(10, 120).toDouble();
  }

  TimeOfDay _parse(String hm) {
    final parts = hm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _fmt(TimeOfDay t) => '${two(t.hour)}:${two(t.minute)}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(isStart ? _start : _end),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = _fmt(picked);
      } else {
        _end = _fmt(picked);
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(monitoringProvider.notifier).saveConfig(MonitoringConfig(
            startTime: _start,
            endTime: _end,
            scheduledEnabled: _scheduled,
            alertTimeoutSeconds: _timeout.round(),
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Configuración guardada')));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(Widget child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar monitoreo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _section(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Horario de sueño',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.deepBlue, fontSize: 16)),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bedtime_outlined, color: AppColors.petrol),
                      title: const Text('Hora de inicio'),
                      trailing: Text(_start,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      onTap: () => _pickTime(true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.wb_sunny_outlined, color: AppColors.petrol),
                      title: const Text('Hora de finalización'),
                      trailing: Text(_end,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      onTap: () => _pickTime(false),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Monitoreo programado'),
                      subtitle: const Text(
                          'Por ahora solo se guarda el horario: el monitoreo no inicia solo, '
                          'se inicia con el botón del inicio.'),
                      value: _scheduled,
                      onChanged: (v) => setState(() => _scheduled = v),
                    ),
                  ],
                )),
                const SizedBox(height: 14),
                _section(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tiempo de espera de la alerta',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.deepBlue, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text(
                        'Segundos que tendrás para pulsar "Estoy bien" antes de avisar a tu persona de confianza.',
                        style: TextStyle(color: AppColors.textMuted)),
                    Slider(
                      value: _timeout,
                      min: 10,
                      max: 120,
                      divisions: 11,
                      label: '${_timeout.round()} s',
                      onChanged: (v) => setState(() => _timeout = v),
                    ),
                    Center(
                      child: Text('${_timeout.round()} segundos',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                )),
                const SizedBox(height: 14),
                _section(const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permisos necesarios',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.deepBlue, fontSize: 16)),
                    SizedBox(height: 6),
                    Text(
                        'Micrófono (para analizar el audio), ubicación (solo durante una alerta) y '
                        'notificaciones. Se te pedirán, con tu consentimiento, cuando se active cada función.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                )),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ErrorBanner(_error!),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Guardar configuración'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
