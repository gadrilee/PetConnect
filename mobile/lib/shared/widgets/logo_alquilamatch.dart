import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LogoAlquilaMatch extends StatelessWidget {
  const LogoAlquilaMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icon/app_icon_foreground.png',
          height: 72,
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          'AlquilaMatch',
          style: AppText.heading(context).copyWith(
            color: AppColors.text,
            fontSize: 24, 
          ),
        ),
      ],
    );
  }
}
