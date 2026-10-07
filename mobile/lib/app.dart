import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/monitoring/presentation/pipeline_controller.dart';
import 'services/notifications/push_service.dart';

class VitalGuardApp extends ConsumerWidget {
  const VitalGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Mantiene vivo el análisis de audio mientras haya un monitoreo experimental activo.
    ref.read(pipelineProvider);

    // Al iniciar sesión (o restaurar la sesión) se activan las notificaciones push.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        ref.read(pushServiceProvider).start();
      }
    });

    return MaterialApp.router(
      title: 'Vital Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
