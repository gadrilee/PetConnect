import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los tonos de un bloque. Cada uno dice cuanto tiene que llamar la atencion.
enum TonoBloque {
  /// Blanco con borde suave. La tarjeta por defecto.
  borde,

  /// Gris muy suave con borde. Agrupa datos que se leen juntos.
  suave,

  /// Tinte del color principal. Lo que la persona tiene que ver primero.
  destacado,

  /// Relleno del color principal, con texto claro. Uno por pantalla, como el
  /// precio final.
  primario,
}

/// Un contenedor con esquinas redondeadas: la tarjeta de toda la app.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Mismo radio, mismo relleno y los mismos cuatro tonos en todas las
/// pantallas. **Ninguna pantalla dibuja su propio BoxDecoration**: cambiar un
/// color o el radio aca lo cambia en todas las tarjetas.
///
/// AUTO LAYOUT: no tiene alto fijo. Mide lo que su contenido.
class Bloque extends StatelessWidget {
  const Bloque({
    super.key,
    this.child,
    this.hijos,
    this.tono = TonoBloque.borde,
    this.relleno = Espacio.md,
    this.colorBorde,
    this.alTocar,
  }) : assert(
          (child == null) != (hijos == null),
          'Pasa child o hijos, uno solo.',
        );

  /// El contenido tal cual.
  final Widget? child;

  /// Atajo para lo mas comun: una columna alineada a la izquierda.
  final List<Widget>? hijos;

  final TonoBloque tono;
  final double relleno;

  /// Reemplaza el borde del tono, por ejemplo con el color de un estado.
  final Color? colorBorde;

  /// Si se pasa, el bloque entero responde al toque.
  final VoidCallback? alTocar;

  /// Fondo y borde de cada tono.
  static (Color fondo, Color? borde) coloresDe(TonoBloque tono) =>
      switch (tono) {
        TonoBloque.borde => (
            AppColors.surface,
            AppColors.text.withValues(alpha: 0.1),
          ),
        TonoBloque.suave => (
            AppColors.text.withValues(alpha: 0.05),
            AppColors.text.withValues(alpha: 0.1),
          ),
        TonoBloque.destacado => (
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.3),
          ),
        TonoBloque.primario => (AppColors.primary, null),
      };

  @override
  Widget build(BuildContext context) {
    final (fondo, bordeDelTono) = coloresDe(tono);
    final borde = colorBorde ?? bordeDelTono;
    final contenido = child ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hijos!,
        );

    return Material(
      color: fondo,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medida.radio),
        side: borde == null ? BorderSide.none : BorderSide(color: borde),
      ),
      child: InkWell(
        onTap: alTocar,
        child: Padding(padding: EdgeInsets.all(relleno), child: contenido),
      ),
    );
  }
}
