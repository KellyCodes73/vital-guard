import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/alert_screen.dart';
import '../../features/alerts/presentation/helper_alert_screen.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/monitoring/presentation/monitored_home_screen.dart';
import '../../features/monitoring/presentation/monitoring_active_screen.dart';
import '../../features/monitoring/presentation/monitoring_config_screen.dart';
import '../../features/trusted_contact/presentation/helper_home_screen.dart';
import '../../features/trusted_contact/presentation/accept_invite_screen.dart';
import '../../features/trusted_contact/presentation/trusted_contact_screen.dart';

/// Muestra el Home que corresponde al rol del usuario.
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();
    return user.role == Role.helper ? const HelperHomeScreen() : const MonitoredHomeScreen();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  const authRoutes = {'/onboarding', '/login', '/register'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final loc = state.matchedLocation;

      if (status == AuthStatus.unknown) {
        return loc == '/splash' ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        if (loc == '/splash') return '/onboarding';
        return authRoutes.contains(loc) ? null : '/login';
      }
      // authenticated
      if (loc == '/splash' || authRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeGate()),
      GoRoute(path: '/monitoring/config', builder: (context, state) => const MonitoringConfigScreen()),
      GoRoute(path: '/monitoring/active', builder: (context, state) => const MonitoringActiveScreen()),
      GoRoute(
        path: '/alert/:id',
        builder: (context, state) => AlertScreen(eventId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
      GoRoute(
        path: '/helper-alert/:id',
        builder: (context, state) =>
            HelperAlertScreen(alertId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/trusted-contact', builder: (context, state) => const TrustedContactScreen()),
      GoRoute(path: '/trusted-contact/accept', builder: (context, state) => const AcceptInviteScreen()),
    ],
  );
});
