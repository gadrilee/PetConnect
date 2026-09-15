import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// El icono de la app con su nombre debajo, en el login.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Icono de 72 y el nombre en la cifra destacada (Inter Bold 24), con 8 entre
/// los dos. Solo aparece en Ingresar: adentro de la app el nombre va en el
/// encabezado.
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
          style: AppText.cifra(context).copyWith(color: AppColors.text),
        ),
      ],
    );
  }
}
