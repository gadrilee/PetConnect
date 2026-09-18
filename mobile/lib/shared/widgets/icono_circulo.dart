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
///
/// El neutro usa Text 70 % sobre Text 10 %: es lo minimo que da 3:1 para un
/// icono sobre ese gris (con 60 % quedaba en 2,9:1 y con 50 % en 2,3:1).
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

  /// El color del icono y del circulo relleno.
  static Color colorDe(TonoIcono tono) => switch (tono) {
        TonoIcono.primario => AppColors.primary,
        TonoIcono.neutro => AppColors.text70,
        TonoIcono.exito => AppColors.success,
        TonoIcono.error => AppColors.error,
      };

  /// El fondo del circulo suave: el tinte de 10 % del color del tono, tomado
  /// de AppColors y no calculado aca.
  static Color fondoSuaveDe(TonoIcono tono) => switch (tono) {
        TonoIcono.primario => AppColors.primary10,
        TonoIcono.neutro => AppColors.text10,
        TonoIcono.exito => AppColors.success10,
        TonoIcono.error => AppColors.error10,
      };

  @override
  Widget build(BuildContext context) {
    final color = colorDe(tono);

    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        color: relleno ? color : fondoSuaveDe(tono),
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
