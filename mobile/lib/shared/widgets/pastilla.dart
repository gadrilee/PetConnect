import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los tonos de una pastilla.
enum TonoPastilla { neutro, primario, exito, error, advertencia, sobreImagen }

/// Una etiqueta chica con fondo, como un estado o la fecha sobre una foto.
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
        TonoPastilla.neutro => (
            AppColors.text.withValues(alpha: 0.06),
            AppColors.text.withValues(alpha: 0.7),
          ),
        TonoPastilla.primario => (
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary,
          ),
        TonoPastilla.exito => (
            AppColors.success.withValues(alpha: 0.12),
            AppColors.success,
          ),
        TonoPastilla.error => (
            AppColors.error.withValues(alpha: 0.12),
            AppColors.error,
          ),
        TonoPastilla.advertencia => (
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.warning,
          ),
        TonoPastilla.sobreImagen => (
            AppColors.text.withValues(alpha: 0.7),
            AppColors.surface,
          ),
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
