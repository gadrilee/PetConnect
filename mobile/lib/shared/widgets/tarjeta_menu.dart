import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'bloque.dart';
import 'icono_circulo.dart';
import 'pastilla.dart';

/// Una opcion del menu de inicio.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Icono, titulo, detalle y a donde lleva, siempre en ese orden. Si todavia
/// no esta disponible, no se puede tocar y lo dice con una pastilla.
///
/// AUTO LAYOUT: alto minimo de 88, no fijo. Si el detalle ocupa dos lineas en
/// un telefono angosto, la tarjeta crece en vez de cortarlo.
class TarjetaMenu extends StatelessWidget {
  const TarjetaMenu({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.icono,
    this.alTocar,
  });

  final String titulo;
  final String detalle;
  final IconData icono;

  /// `null` la muestra como todavia no disponible.
  final VoidCallback? alTocar;

  /// Alto minimo del contenido: 88 menos el relleno de arriba y de abajo.
  static const double _altoMinimo = 56;

  @override
  Widget build(BuildContext context) {
    final habilitada = alTocar != null;

    return Bloque(
      alTocar: alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _altoMinimo),
        // FLEXBOX: icono fijo, textos flexibles y la flecha anclada a la
        // derecha.
        child: Row(
          children: [
            IconoCirculo(
              icono,
              tono: habilitada ? TonoIcono.primario : TonoIcono.neutro,
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppText.button(context).copyWith(
                      color: habilitada
                          ? AppColors.text
                          : AppColors.text.withValues(alpha: 0.38),
                    ),
                  ),
                  const SizedBox(height: Espacio.xs),
                  Text(
                    detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(context).copyWith(
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Espacio.md),
            if (habilitada)
              Icon(
                Icons.chevron_right,
                color: AppColors.text.withValues(alpha: 0.4),
              )
            else
              const Pastilla('Pendiente'),
          ],
        ),
      ),
    );
  }
}
