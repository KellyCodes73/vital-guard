import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../widgets/error_banner.dart';
import '../domain/trusted_contact_models.dart';
import 'trusted_contact_controller.dart';

/// Pantalla del usuario monitoreado: invitar, ver el código y revocar el acceso.
class TrustedContactScreen extends ConsumerStatefulWidget {
  const TrustedContactScreen({super.key});

  @override
  ConsumerState<TrustedContactScreen> createState() => _TrustedContactScreenState();
}

class _TrustedContactScreenState extends ConsumerState<TrustedContactScreen> {
  Timer? _timer;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(trustedContactProvider.notifier).refresh(silent: true));
    // Mientras esta pantalla está abierta, se actualiza sola (para ver cuándo el auxiliador acepta).
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.read(trustedContactProvider.notifier).refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRevoke(TrustedContactLink link) async {
    final isPending = link.isPending;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPending ? '¿Cancelar la invitación?' : '¿Revocar el acceso?'),
        content: Text(isPending
            ? 'El código dejará de funcionar.'
            : 'Esta persona dejará de recibir tus alertas y ya no podrá ver ubicaciones tuyas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isPending ? 'Cancelar invitación' : 'Revocar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ref.read(trustedContactProvider.notifier).revoke(link.id));
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado')));
  }

  String _formatCode(String c) => c.length == 6 ? '${c.substring(0, 3)} ${c.substring(3)}' : c;

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );

  Widget _buildNone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.people_outline, size: 40, color: AppColors.petrol),
            SizedBox(height: 12),
            Text('Aún no tienes persona de confianza',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
            SizedBox(height: 8),
            Text(
                'Si identificamos un posible patrón respiratorio inusual y no respondes, '
                'avisaremos a esta persona. Solo podrá ver tu ubicación de forma temporal '
                'durante una alerta, nunca de forma permanente.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        )),
        const SizedBox(height: 20),
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Invitar persona de confianza'),
          onPressed: _busy
              ? null
              : () => _run(() => ref.read(trustedContactProvider.notifier).invite()),
        ),
      ],
    );
  }

  Widget _buildPending(TrustedContactLink link) {
    final exp = link.expiresAt?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(Column(
          children: [
            const Text('Código de invitación',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
            const SizedBox(height: 12),
            Text(_formatCode(link.inviteCode ?? ''),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.petrol)),
            const SizedBox(height: 8),
            if (exp != null)
              Text('Válido hasta ${formatDate(exp)} ${formatHm(exp)}',
                  style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            const Text(
                'Pídele a tu persona de confianza que abra Vital Guard con su cuenta de '
                'auxiliador y escriba este código.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted)),
          ],
        )),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código'),
          onPressed: () => _copy(link.inviteCode ?? ''),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => _confirmRevoke(link),
          child: const Text('Cancelar invitación'),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text('Esperando que acepte la invitación…',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildActive(TrustedContactLink link) {
    final since = link.acceptedAt?.toLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: AppColors.petrol, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.helperUser?.fullName ?? 'Persona de confianza',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepBlue)),
                      const Text('Vinculación activa',
                          style: TextStyle(color: AppColors.petrol)),
                    ],
                  ),
                ),
              ],
            ),
            if (since != null) ...[
              const SizedBox(height: 10),
              Text('Desde el ${formatDate(since)}',
                  style: const TextStyle(color: AppColors.textMuted)),
            ],
            const SizedBox(height: 12),
            const Text(
                'Esta persona solo podrá ver tu ubicación de forma temporal durante una '
                'alerta activa. Puedes revocar su acceso cuando quieras.',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        )),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          icon: const Icon(Icons.link_off),
          label: const Text('Revocar acceso'),
          onPressed: _busy ? null : () => _confirmRevoke(link),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = ref.watch(trustedContactProvider);
    final link = tc.current;

    Widget body;
    if (tc.loading && link == null) {
      body = const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (link == null) {
      body = _buildNone();
    } else if (link.isPending) {
      body = _buildPending(link);
    } else {
      body = _buildActive(link);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Persona de confianza'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(trustedContactProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                if (tc.error != null) ...[ErrorBanner(tc.error!), const SizedBox(height: 14)],
                if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 14)],
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
