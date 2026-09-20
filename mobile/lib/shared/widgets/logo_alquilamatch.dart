import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// El logo de la app con su nombre debajo, en el login.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Logo de 72 y el nombre en la cifra destacada (Inter Bold 24), con 16 entre
/// los dos. Solo aparece en Ingresar: adentro de la app el nombre va en el
/// encabezado.
///
/// Usa `logo.png`, que es el dibujo solo, y **no** el archivo del icono de
/// launcher: ese trae 18 % de aire transparente arriba y abajo para la zona
/// segura del icono adaptativo, asi que los 72 declarados quedaban en 47 de
/// dibujo con 13 de nada a cada lado. Ademas ata esta pantalla al encuadre del
/// icono: reencuadrar uno movia el otro sin que nadie lo pidiera.
class LogoAlquilaMatch extends StatelessWidget {
  const LogoAlquilaMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/icon/logo.png', height: 72),
        const SizedBox(height: Espacio.md),
        Text(
          'AlquilaMatch',
          style: AppText.cifra(context).copyWith(color: AppColors.text),
        ),
      ],
    );
  }
}
