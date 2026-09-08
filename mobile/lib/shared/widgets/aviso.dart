import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum TipoAviso {
  info,
  exito,
  error,
  advertencia,
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
    final (Color fondo, Color contenido) = switch (tipo) {
      TipoAviso.info => (
          AppColors.text.withValues(alpha: 0.05),
          AppColors.text
        ),
      TipoAviso.exito => (
          AppColors.success.withValues(alpha: 0.1),
          AppColors.success
        ),
      TipoAviso.error => (
          AppColors.error.withValues(alpha: 0.1),
          AppColors.error
        ),
      TipoAviso.advertencia => (
          AppColors.warning.withValues(alpha: 0.1),
          AppColors.warning
        ),
    };

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medida.radio),
        border: Border.all(color: contenido),
      ),
      child: Row(
        children: [
          Icon(icono, size: 24, color: contenido),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Text(
              mensaje,
              style: AppText.caption(context).copyWith(
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

  /// Muestra este componente como un "Toast" flotante en la parte superior derecha.
  static void mostrarToast(
    BuildContext context, {
    required String mensaje,
    required TipoAviso tipo,
    IconData? icono,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final iconData = icono ??
        switch (tipo) {
          TipoAviso.info => Icons.info_outline,
          TipoAviso.exito => Icons.check_circle_outline,
          TipoAviso.error => Icons.error_outline,
          TipoAviso.advertencia => Icons.warning_amber_outlined,
        };

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        right: 16,
        left: 16,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Aviso(
                icono: iconData,
                mensaje: mensaje,
                tipo: tipo,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}
