import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../widgets/error_banner.dart';
import '../data/alert_repository.dart';
import '../domain/alert_info.dart';
import 'alert_inbox_controller.dart';

/// Pantalla del auxiliador: alerta recibida, ubicación temporal y confirmar recepción.
class HelperAlertScreen extends ConsumerStatefulWidget {
  final int alertId;
  const HelperAlertScreen({super.key, required this.alertId});

  @override
  ConsumerState<HelperAlertScreen> createState() => _HelperAlertScreenState();
}

class _HelperAlertScreenState extends ConsumerState<HelperAlertScreen> {
  static const Color _warm = Color(0xFFB45309);

  AlertInfo? _alert;
  String? _error;
  bool _acking = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Se actualiza sola: la ubicación puede llegar unos segundos después de la alerta.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final a = await ref.read(alertRepositoryProvider).get(widget.alertId);
      if (mounted) {
        setState(() {
          _alert = a;
          _error = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final status = e is DioException ? e.response?.statusCode : null;
      if (status == 403 || status == 404) {
        // Acceso revocado o alerta inexistente: se deja de mostrar la información.
        setState(() {
          _alert = null;
          _error = apiErrorMessage(e);
        });
      } else if (!silent) {
        setState(() => _error = apiErrorMessage(e));
      }
    }
  }

  Future<void> _acknowledge() async {
    setState(() {
      _acking = true;
      _error = null;
    });
    try {
      final a = await ref.read(alertRepositoryProvider).acknowledge(widget.alertId);
      if (!mounted) return;
      setState(() => _alert = a);
      ref.read(alertInboxProvider.notifier).refresh(silent: true);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _acking = false);
    }
  }

  Future<void> _openMaps(LocationInfo loc) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la aplicación de mapas.')),
      );
    }
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Text('$label: ', style: const TextStyle(color: Color(0xCCFFFFFF))),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _locationSection(AlertInfo a) {
    final loc = a.location;
    if (loc != null) {
      final captured = loc.capturedAt.toLocal();
      final expires = loc.expiresAt.toLocal();
      final accuracy = loc.accuracyMeters == null ? '' : ' (±${loc.accuracyMeters!.round()} m)';
      return _card(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.petrol),
              SizedBox(width: 8),
              Text('Ubicación temporal',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.deepBlue, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}$accuracy',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Actualizada a las ${formatHm(captured)} · disponible hasta las ${formatHm(expires)}',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.navigation_outlined),
            label: const Text('ABRIR UBICACIÓN / NAVEGACIÓN'),
            onPressed: () => _openMaps(loc),
          ),
          const SizedBox(height: 10),
          const Text(
              'Esta ubicación se comparte temporalmente debido a una alerta activa.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ],
      ));
    }

    final expired = DateTime.now().isAfter(a.locationExpiresAt.toLocal());
    return _card(Row(
      children: [
        const Icon(Icons.location_off_outlined, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            expired
                ? 'La ubicación temporal ya no está disponible.'
                : 'Aún no hay ubicación disponible. Se actualizará automáticamente.',
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ),
      ],
    ));
  }

  Widget _guidance() => _card(const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orientaciones básicas',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepBlue, fontSize: 16)),
          SizedBox(height: 8),
          Text('• Intenta comunicarte con la persona o dirígete a su ubicación.',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text(
              '• Si no responde o parece estar en peligro, llama de inmediato a los servicios '
              'de emergencia de tu localidad.',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text(
              '• Vital Guard es una herramienta de apoyo preventivo: no diagnostica ni reemplaza la atención médica.',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ));

  Widget _empty() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(_error!),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final a = _alert;
    return Scaffold(
      appBar: AppBar(title: const Text('Alerta recibida')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: a == null
                ? _empty()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF7C2D12), Color(0xFFB45309)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.white),
                                SizedBox(width: 8),
                                Text('ALERTA RECIBIDA',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Vital Guard detectó un posible patrón respiratorio inusual en '
                              '${a.monitoredUser?.name ?? 'la persona vinculada'}.',
                              style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            _row('Hora del evento', formatHm(a.eventDetectedAt.toLocal())),
                            _row(
                                'Estado',
                                a.isActive
                                    ? 'Pendiente de confirmar'
                                    : 'Recepción confirmada'
                                        '${a.acknowledgedAt == null ? '' : ' a las ${formatHm(a.acknowledgedAt!.toLocal())}'}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _locationSection(a),
                      const SizedBox(height: 14),
                      _guidance(),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        ErrorBanner(_error!),
                      ],
                      const SizedBox(height: 18),
                      if (a.isActive)
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: _warm),
                          onPressed: _acking ? null : _acknowledge,
                          child: _acking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('CONFIRMAR RECEPCIÓN'),
                        )
                      else
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, color: AppColors.petrol),
                            SizedBox(width: 8),
                            Text('Recepción confirmada',
                                style: TextStyle(
                                    color: AppColors.petrol, fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
