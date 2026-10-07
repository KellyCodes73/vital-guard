import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class DisclaimerText extends StatelessWidget {
  const DisclaimerText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Vital Guard es una herramienta de apoyo preventivo. '
      'No realiza diagnóstico médico ni reemplaza la atención profesional.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
  }
}
