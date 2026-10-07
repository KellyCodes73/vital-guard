import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../widgets/disclaimer_text.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/info_card.dart';
import '../../alerts/presentation/alert_inbox_controller.dart';
import '../../auth/presentation/auth_controller.dart';
import 'trusted_contact_controller.dart';

class HelperHomeScreen extends ConsumerWidget {
  const HelperHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final tc = ref.watch(trustedContactProvider);
    final inbox = ref.watch(alertInboxProvider);

    // Si llega una alerta nueva mientras el auxiliador está en esta pantalla, se abre sola.
    ref.listen<AlertInboxState>(alertInboxProvider, (prev, next) {
      if (prev == null || !prev.loaded) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final before = prev.alerts.map((a) => a.id).toSet();
      final fresh = next.alerts.where((a) => a.isActive && !before.contains(a.id)).toList();
      if (fresh.isNotEmpty) context.push('/helper-alert/${fresh.first.id}');
    });

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
                      child: Text('Hola, ${user?.name ?? ''}',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepBlue)),
                    ),
                    IconButton(
                      tooltip: 'Actualizar',
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.read(trustedContactProvider.notifier).refresh();
                        ref.read(alertInboxProvider.notifier).refresh();
                      },
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Eres persona de confianza',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 20),
                if (tc.error != null) ...[
                  ErrorBanner(tc.error!),
                  const SizedBox(height: 14),
                ],
                if (inbox.error != null) ...[
                  ErrorBanner(inbox.error!),
                  const SizedBox(height: 14),
                ],
                const Text('Alertas',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
                const SizedBox(height: 10),
                if (inbox.alerts.isEmpty)
                  InfoCard(
                    icon: Icons.notifications_none,
                    title: 'Sin alertas por ahora',
                    subtitle: inbox.loaded
                        ? 'Te avisaremos si alguien necesita ayuda'
                        : 'Cargando...',
                  )
                else
                  for (final a in inbox.alerts.take(5)) ...[
                    InfoCard(
                      icon: a.isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      title: 'Alerta · ${a.monitoredUser?.fullName ?? 'Usuario'}',
                      subtitle: a.isActive
                          ? 'ACTIVA · ${formatHm(a.eventDetectedAt.toLocal())} · toca para ver'
                          : 'Recepción confirmada · ${formatHm(a.eventDetectedAt.toLocal())}',
                      onTap: () => context.push('/helper-alert/${a.id}'),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 10),
                const Text('Personas vinculadas',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
                const SizedBox(height: 10),
                if (tc.links.isEmpty)
                  InfoCard(
                    icon: Icons.link,
                    title: 'Sin vinculaciones',
                    subtitle: tc.loading ? 'Cargando...' : 'Aún no tienes personas vinculadas',
                  )
                else
                  for (final link in tc.links) ...[
                    InfoCard(
                      icon: Icons.person_outline,
                      title: link.monitoredUser?.fullName ?? 'Usuario',
                      subtitle: link.acceptedAt == null
                          ? 'Vinculación activa'
                          : 'Vinculación activa · desde ${formatDate(link.acceptedAt!.toLocal())}',
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                FilledButton.icon(
                  icon: const Icon(Icons.pin_outlined),
                  label: const Text('Vincular con un código'),
                  onPressed: () => context.push('/trusted-contact/accept'),
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
