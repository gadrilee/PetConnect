import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los colores de un icono en circulo.
enum TonoIcono { primario, neutro, exito, error }

/// Un icono dentro de un circulo: el avatar del perfil, el icono de un menu o
/// el estado de una solicitud.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El icono mide siempre la mitad del circulo. Suave es tinte del color con
/// icono del color; relleno es el circulo lleno con icono claro.
class IconoCirculo extends StatelessWidget {
  const IconoCirculo(
    this.icono, {
    super.key,
    this.diametro = 48,
    this.tono = TonoIcono.primario,
    this.relleno = false,
  });

  final IconData icono;
  final double diametro;
  final TonoIcono tono;

  /// `true` llena el circulo; `false` lo deja con un tinte suave.
  final bool relleno;

  static Color colorDe(TonoIcono tono) => switch (tono) {
        TonoIcono.primario => AppColors.primary,
        TonoIcono.neutro => AppColors.text.withValues(alpha: 0.5),
        TonoIcono.exito => AppColors.success,
        TonoIcono.error => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(tono);

    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        color: relleno ? color : color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icono,
        size: diametro / 2,
        color: relleno ? AppColors.surface : color,
      ),
    );
  }
}
