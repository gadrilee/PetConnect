import 'package:flutter/material.dart';

import '../../core/theme.dart';

enum TipoAviso {
  info,
  exito,
  error,
  advertencia,
}

/// Un bloque que le dice a la persona qué pasó, o qué va a pasar, en el lugar
/// donde importa. En Figma es la pieza "Feedback".
///
/// REGLA DE LA PIEZA
/// -----------------
/// Sin título mide siempre 64 de alto, con relleno de 16 y hasta dos líneas de
/// texto. El ícono y el texto llevan el color del tipo, y **el tipo se
/// reconoce por el color antes de leer**. Entre tipos cambian sólo el color y
/// el ícono, nunca el tamaño: la pantalla no salta cuando aparece o cambia.
///
/// Con [titulo] cuenta un resultado en dos partes, qué pasó y qué significa.
/// Ese no tiene alto fijo. AUTO LAYOUT: crece con el texto.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.mensaje,
    this.tipo = TipoAviso.info,
    this.icono,
    this.titulo,
  });

  final String mensaje;
  final TipoAviso tipo;

  /// Qué ícono acompaña al mensaje. Si no se pasa, lo decide el tipo. Se
  /// cambia cuando el ícono dice *de qué* se trata (el candado del WhatsApp)
  /// y el color dice *qué tan grave* es.
  final IconData? icono;

  /// Título opcional, arriba del mensaje.
  final String? titulo;

  /// El ícono que corresponde a cada tipo. La misma tabla que usa el toast.
  static IconData iconoDe(TipoAviso tipo) => switch (tipo) {
        TipoAviso.info => Icons.info_outline,
        TipoAviso.exito => Icons.check_circle_outline,
        TipoAviso.error => Icons.error_outline,
        TipoAviso.advertencia => Icons.warning_amber_outlined,
      };

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

    final decoracion = BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(Medida.radio),
      border: Border.all(color: contenido),
    );
    final iconoWidget = Icon(icono ?? iconoDe(tipo), size: 24, color: contenido);

    if (titulo != null) {
      return Container(
        padding: const EdgeInsets.all(Espacio.md),
        decoration: decoracion,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconoWidget,
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo!,
                    style: AppText.button(context)
                        .copyWith(color: contenido, letterSpacing: 0),
                  ),
                  const SizedBox(height: Espacio.xs),
                  Text(
                    mensaje,
                    style: AppText.caption(context)
                        .copyWith(color: contenido, height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
      decoration: decoracion,
      child: Row(
        children: [
          iconoWidget,
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

  /// Muestra este componente como un aviso flotante, abajo de la pantalla.
  ///
  /// Es la unica forma de avisar algo pasajero en la app: las pantallas no
  /// arman su propio SnackBar.
  static void mostrarToast(
    BuildContext context, {
    required String mensaje,
    required TipoAviso tipo,
    IconData? icono,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).padding.bottom + Espacio.md,
        right: Espacio.md,
        left: Espacio.md,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Aviso(icono: icono, mensaje: mensaje, tipo: tipo),
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
