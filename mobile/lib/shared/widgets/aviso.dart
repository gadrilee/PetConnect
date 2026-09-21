import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../layout/pagina.dart';

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
///
/// **Un aviso nunca queda suelto ni alineado a la derecha.** Si la pantalla
/// tiene pie, el aviso va en `PieAcciones.aviso`; si no lo tiene, va en el
/// contenido o, cuando es pasajero, como [mostrarToast], que ocupa el margen
/// de la pagina igual que cualquier otro aviso.
///
/// Con [alTocar] el aviso lleva a algun lado. Sigue midiendo lo mismo: lo
/// unico que cambia es la flecha del final, que avisa que el toque sale de la
/// pantalla.
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.mensaje,
    this.tipo = TipoAviso.info,
    this.icono,
    this.titulo,
    this.alTocar,
  });

  final String mensaje;
  final TipoAviso tipo;

  /// Qué ícono acompaña al mensaje. Si no se pasa, lo decide el tipo. Se
  /// cambia cuando el ícono dice *de qué* se trata (el candado del WhatsApp)
  /// y el color dice *qué tan grave* es.
  final IconData? icono;

  /// Título opcional, arriba del mensaje.
  final String? titulo;

  /// Qué pasa al tocarlo. Sin esto el aviso solo informa, que es lo normal:
  /// se pone cuando el aviso ES el camino a algo, como la ubicación que abre
  /// el mapa.
  final VoidCallback? alTocar;

  /// El ícono que corresponde a cada tipo. La misma tabla que usa el toast.
  static IconData iconoDe(TipoAviso tipo) => switch (tipo) {
        TipoAviso.info => Icons.info_outline,
        TipoAviso.exito => Icons.check_circle_outline,
        TipoAviso.error => Icons.error_outline,
        TipoAviso.advertencia => Icons.warning_amber_outlined,
      };

  @override
  Widget build(BuildContext context) {
    // Fondo y contenido de cada tipo (Figma: Feedback Info / Éxito / Error /
    // Advertencia). Los fondos son tintes de AppColors, no se calculan aca.
    final (Color fondo, Color contenido) = switch (tipo) {
      TipoAviso.info => (AppColors.text05, AppColors.text),
      TipoAviso.exito => (AppColors.success10, AppColors.success),
      TipoAviso.error => (AppColors.error08, AppColors.error),
      TipoAviso.advertencia => (AppColors.warning12, AppColors.warning),
    };

    final decoracion = BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(Medida.radio),
      border: Border.all(color: contenido),
    );
    final iconoWidget = Icon(icono ?? iconoDe(tipo), size: 24, color: contenido);

    return _conToque(_cuerpo(context, decoracion, iconoWidget, contenido));
  }

  /// La caja del aviso: `Container` como siempre, y `Ink` sólo cuando se
  /// toca, para que la onda se vea sobre el fondo en vez de quedar tapada por
  /// él. El aviso que no lleva a ningún lado se dibuja igual que antes.
  Widget _caja({
    double? alto,
    required EdgeInsets relleno,
    required BoxDecoration decoracion,
    required Widget hijo,
  }) {
    return alTocar == null
        ? Container(
            height: alto,
            padding: relleno,
            decoration: decoracion,
            child: hijo,
          )
        : Ink(
            height: alto,
            padding: relleno,
            decoration: decoracion,
            child: hijo,
          );
  }

  /// El aviso, y arriba el toque cuando lo hay.
  Widget _conToque(Widget cuerpo) {
    if (alTocar == null) return cuerpo;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(Medida.radio),
          child: cuerpo,
        ),
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    BoxDecoration decoracion,
    Widget iconoWidget,
    Color contenido,
  ) {
    // La flecha del final: solo cuando el aviso lleva a algun lado.
    final flecha = alTocar == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: Espacio.sm),
            child: Icon(Icons.open_in_new, size: 20, color: contenido),
          );

    if (titulo != null) {
      return _caja(
        relleno: const EdgeInsets.all(Espacio.md),
        decoracion: decoracion,
        hijo: Row(
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
            ?flecha,
          ],
        ),
      );
    }

    return _caja(
      alto: 64,
      relleno: const EdgeInsets.symmetric(horizontal: Espacio.md),
      decoracion: decoracion,
      hijo: Row(
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
          ?flecha,
        ],
      ),
    );
  }

  /// Aviso pasajero para pantallas SIN pie, abajo de la pantalla.
  ///
  /// Si la pantalla tiene pie, el aviso va en `PieAcciones.aviso`, nunca
  /// flotando. Las pantallas no arman su propio SnackBar.
  ///
  /// CONSTRAINTS: ocupa el mismo margen que el contenido de la pagina (24 a
  /// cada lado), centrado y sin pasar el ancho de un formulario, para que se
  /// vea igual que cualquier otro aviso y no como una burbuja suelta.
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
        right: Espacio.lg,
        left: Espacio.lg,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: AnchoPagina.formulario.maximo),
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
