import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// El titulo de un grupo dentro de una pantalla, como "¿Qué querés hacer?" o
/// "1. Qué estás alquilando".
///
/// REGLA DE LA PIEZA
/// -----------------
/// Siempre el mismo tamano y el mismo color. La separacion con lo que sigue la
/// pone la pantalla, con la escala de Espacio.
class TituloSeccion extends StatelessWidget {
  const TituloSeccion(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: AppText.titulo(context).copyWith(color: AppColors.text),
    );
  }
}
