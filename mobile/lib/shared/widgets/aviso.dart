import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum TipoAviso {
  info,
  error,
}

/// Un bloque de información que interrumpe el flujo normal para advertir o explicar algo.
///
/// REGLA DE LA PIEZA:
/// Mide exactamente 64 de alto, con un padding interno de 16. Diseñado para
/// contener exactamente dos líneas de texto.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.icono,
    required this.mensaje,
    this.tipo = TipoAviso.info,
  });

  final IconData icono;
  final String mensaje;
  final TipoAviso tipo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    final (Color fondo, Color contenido) = switch (tipo) {
      TipoAviso.info => (
          esquema.surfaceContainerHighest.withValues(alpha: 0.5),
          esquema.onSurfaceVariant
        ),
      TipoAviso.error => (esquema.errorContainer, esquema.onErrorContainer),
    };

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: tipo == TipoAviso.info
            ? Border.all(color: esquema.outline.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          Icon(icono, size: 24, color: contenido),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Text(
              mensaje,
              style: texto.bodySmall?.copyWith(
                color: contenido,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
