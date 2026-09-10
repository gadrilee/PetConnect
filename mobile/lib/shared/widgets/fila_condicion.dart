import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Un dato con su icono: una condicion del anuncio, un servicio o un detalle
/// de una tarjeta.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Icono a la izquierda y texto a la derecha, siempre con 8 entre los dos. El
/// icono orienta, no decora: si no aporta a distinguir el dato, sobra.
///
/// Estaba escrita dos veces con tamanos distintos y despues aparecio copiada
/// dentro de cada tarjeta. Ahora es una sola pieza con opciones.
///
/// - FLEXBOX: el icono tiene su tamano y el texto toma el resto del ancho. En
///   linea, para ir dentro de un Wrap, la fila mide lo que su contenido.
/// - CONSTRAINTS: con [maxLineas] el texto se corta con puntos suspensivos en
///   vez de agrandar la tarjeta.
class FilaCondicion extends StatelessWidget {
  const FilaCondicion({
    super.key,
    required this.icono,
    required this.texto,
    this.colorIcono,
    this.tamanoIcono = 16,
    this.estilo,
    this.maxLineas,
    this.enLinea = false,
  });

  final IconData icono;
  final String texto;

  /// Por defecto, el gris de los textos secundarios.
  final Color? colorIcono;
  final double tamanoIcono;

  /// Por defecto, el cuerpo en gris.
  final TextStyle? estilo;

  /// `null` deja que el texto use las lineas que necesite.
  final int? maxLineas;

  /// `true` para usarla dentro de un Wrap, junto a otras.
  final bool enLinea;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    final textoWidget = Text(
      texto,
      maxLines: maxLineas,
      overflow: maxLineas == null ? null : TextOverflow.ellipsis,
      style: estilo ??
          Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.15,
                color: esquema.onSurfaceVariant,
              ),
    );

    return Row(
      mainAxisSize: enLinea ? MainAxisSize.min : MainAxisSize.max,
      // Una sola linea se centra con el icono; un texto largo arranca arriba.
      crossAxisAlignment: maxLineas == 1 || enLinea
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: tamanoIcono,
          color: colorIcono ?? esquema.onSurfaceVariant,
        ),
        const SizedBox(width: Espacio.sm),
        if (enLinea)
          Flexible(child: textoWidget)
        else
          Expanded(child: textoWidget),
      ],
    );
  }
}
