import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Una accion de menor peso, sin borde ni relleno, como "No tengo cuenta".
///
/// REGLA DE LA PIEZA
/// -----------------
/// Se usa para salidas o caminos alternativos, nunca para la accion principal
/// de la pantalla. Lleva el color principal para que se lea como tocable.
class BotonTexto extends StatelessWidget {
  const BotonTexto({
    super.key,
    required this.etiqueta,
    required this.alTocar,
    this.icono,
  });

  final String etiqueta;

  /// `null` la deshabilita.
  final VoidCallback? alTocar;

  /// Icono opcional a la izquierda de la etiqueta.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final color = alTocar == null
        ? AppColors.text.withValues(alpha: 0.38)
        : AppColors.primary;
    final texto = Text(
      etiqueta,
      style: AppText.button(context).copyWith(color: color),
    );

    if (icono == null) return TextButton(onPressed: alTocar, child: texto);

    return TextButton.icon(
      onPressed: alTocar,
      icon: Icon(icono, size: 16, color: color),
      label: texto,
    );
  }
}
