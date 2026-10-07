import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/vital_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.deepBlue, AppColors.petrol],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VitalLogo(size: 110, onDark: true),
            SizedBox(height: 24),
            Text('Vital Guard',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Apoyo preventivo mientras duermes',
                style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 15)),
            SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.sky),
            ),
          ],
        ),
      ),
    );
  }
}
