import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los tonos de una pastilla.
enum TonoPastilla { neutro, primario, exito, error, advertencia }

/// Una etiqueta chica con fondo, como un estado o la fecha de una foto.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Siempre la misma forma: texto chico, fondo del tono y esquinas de pastilla.
/// El color dice que es antes de leer.
///
/// AUTO LAYOUT: el ancho lo pone la palabra, nunca un numero fijo.
class Pastilla extends StatelessWidget {
  const Pastilla(this.texto, {super.key, this.tono = TonoPastilla.neutro});

  final String texto;
  final TonoPastilla tono;

  /// Fondo y texto de cada tono.
  static (Color fondo, Color texto) coloresDe(TonoPastilla tono) =>
      switch (tono) {
        TonoPastilla.neutro => (AppColors.text06, AppColors.text70),
        TonoPastilla.primario => (AppColors.primary12, AppColors.primary),
        TonoPastilla.exito => (AppColors.success12, AppColors.success),
        TonoPastilla.error => (AppColors.error12, AppColors.error),
        TonoPastilla.advertencia => (AppColors.warning12, AppColors.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (fondo, color) = coloresDe(tono);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.md,
        vertical: Espacio.xs,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medida.radio * 2),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption(context).copyWith(color: color),
      ),
    );
  }
}
