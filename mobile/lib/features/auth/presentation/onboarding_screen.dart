import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/disclaimer_text.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String text;
  const _OnboardingPage(this.icon, this.title, this.text);
}

const _pages = <_OnboardingPage>[
  _OnboardingPage(
    Icons.nightlight_round,
    'Monitoreo preventivo',
    'Vital Guard analiza señales de audio mientras duermes para identificar un '
        'posible patrón respiratorio inusual. No es un dispositivo médico ni diagnostica.',
  ),
  _OnboardingPage(
    Icons.lock_outline,
    'Tu privacidad primero',
    'El análisis está diseñado para hacerse en tu teléfono. No se guardan '
        'grabaciones de toda la noche y solo se registran los eventos.',
  ),
  _OnboardingPage(
    Icons.people_outline,
    'Persona de confianza',
    'Si no respondes a una alerta, avisamos a la persona que tú elijas y se '
        'comparte tu ubicación solo mientras dura esa alerta. Puedes revocar el acceso cuando quieras.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Omitir'),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final p = _pages[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: AppColors.mist),
                              child: Icon(p.icon, size: 62, color: AppColors.petrol),
                            ),
                            const SizedBox(height: 36),
                            Text(p.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepBlue)),
                            const SizedBox(height: 14),
                            Text(p.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, height: 1.4, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.petrol : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: FilledButton(
                    onPressed: () {
                      if (isLast) {
                        context.go('/login');
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(isLast ? 'Comenzar' : 'Siguiente'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: DisclaimerText(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
