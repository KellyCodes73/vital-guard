import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_format.dart';
import '../../../widgets/error_banner.dart';
import '../../alerts/data/event_repository.dart';
import '../../alerts/domain/respiratory_event.dart';

final eventHistoryProvider = FutureProvider.autoDispose<List<RespiratoryEvent>>((ref) async {
  return ref.watch(eventRepositoryProvider).list();
});

Color _statusColor(String status) {
  switch (status) {
    case EventStatuses.resolved:
      return const Color(0xFF2E7D32);
    case EventStatuses.notified:
      return const Color(0xFFB45309);
    case EventStatuses.noHelper:
      return AppColors.error;
    case EventStatuses.closed:
      return AppColors.petrol;
    default:
      return AppColors.textMuted;
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case EventStatuses.resolved:
      return Icons.check_circle_outline;
    case EventStatuses.notified:
      return Icons.notifications_active_outlined;
    case EventStatuses.noHelper:
      return Icons.person_off_outlined;
    case EventStatuses.closed:
      return Icons.lock_outline;
    default:
      return Icons.hourglass_empty;
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(eventHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de eventos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(eventHistoryProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ErrorBanner(apiErrorMessage(e)),
                    TextButton(
                      onPressed: () => ref.invalidate(eventHistoryProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Aún no hay eventos registrados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = events[i];
                    final d = e.detectedAt.toLocal();
                    final color = _statusColor(e.status);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(_statusIcon(e.status), color: color, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    e.isDemo
                                        ? 'Posible patrón respiratorio inusual (demo)'
                                        : 'Posible patrón respiratorio inusual',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
                                const SizedBox(height: 2),
                                Text('${formatDate(d)} · ${formatHm(d)}',
                                    style: const TextStyle(color: AppColors.textMuted)),
                                const SizedBox(height: 4),
                                Text(e.statusLabel,
                                    style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
