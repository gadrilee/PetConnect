import 'package:flutter/material.dart';

enum TipoEstado {
  pendiente,
  aprobada,
  rechazada,
}

/// Etiqueta que indica el estado de una solicitud.
///
/// REGLA DE LA PIEZA:
/// Mide exactamente 88x24 con radio de 12. Centrada en un ancho de 360px
/// cae perfecto en la grilla base 8.
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({super.key, required this.estado});

  final TipoEstado estado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    final (Color fondo, Color colorTexto, String etiqueta) = switch (estado) {
      TipoEstado.pendiente => (
          esquema.surfaceContainerHighest,
          esquema.onSurfaceVariant,
          'Pendiente'
        ),
      TipoEstado.aprobada => (
          esquema.primaryContainer,
          esquema.onPrimaryContainer,
          'Aprobada'
        ),
      TipoEstado.rechazada => (
          esquema.errorContainer,
          esquema.onErrorContainer,
          'Rechazada'
        ),
    };

    return Container(
      width: 88,
      height: 24,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        etiqueta,
        style: texto.labelSmall?.copyWith(
          color: colorTexto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
