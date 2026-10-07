import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class VitalLogo extends StatelessWidget {
  final double size;
  final bool onDark;
  const VitalLogo({super.key, this.size = 72, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onDark ? const Color(0x26FFFFFF) : AppColors.mist,
      ),
      child: Icon(
        Icons.shield_outlined,
        size: size * 0.55,
        color: onDark ? Colors.white : AppColors.petrol,
      ),
    );
  }
}
