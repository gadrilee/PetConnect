import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Un dato con su icono: una condicion del anuncio, un servicio o un detalle
/// de una tarjeta.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Icono a la izquierda y texto a la derecha, siempre con 8 entre los dos. El
/// icono orienta, no decora: si no aporta a distinguir el dato, sobra. Por eso
/// va en Text 60 %, el gris minimo para un icono que orienta (3,5:1), y el
/// texto en Text 70 %, el del texto secundario sobre blanco (4,6:1).
///
/// Sobre un fondo tenido —un bloque suave— el 70 % ya no alcanza (4,2:1):
/// quien la ubica ahi pasa [sobreTinte] y el texto sube a Text 80 %.
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
    this.sobreTinte = false,
  });

  final IconData icono;
  final String texto;

  /// Por defecto, Text 60 %: el gris de los iconos que orientan.
  final Color? colorIcono;
  final double tamanoIcono;

  /// Por defecto, el cuerpo en Text 70 % (Text 80 % con [sobreTinte]).
  final TextStyle? estilo;

  /// `null` deja que el texto use las lineas que necesite.
  final int? maxLineas;

  /// `true` para usarla dentro de un Wrap, junto a otras.
  final bool enLinea;

  /// `true` cuando la fila va sobre un fondo tenido, como un bloque suave: el
  /// texto por defecto pasa de Text 70 % a Text 80 %, que es lo que se lee
  /// sobre ese gris. No cambia un [estilo] pasado a mano.
  final bool sobreTinte;

  /// El color del texto por defecto segun el fondo.
  static Color colorTexto({required bool sobreTinte}) =>
      sobreTinte ? AppColors.text80 : AppColors.text70;

  @override
  Widget build(BuildContext context) {
    final textoWidget = Text(
      texto,
      maxLines: maxLineas,
      overflow: maxLineas == null ? null : TextOverflow.ellipsis,
      style: estilo ??
          AppText.body(context).copyWith(
            height: 1.15,
            color: colorTexto(sobreTinte: sobreTinte),
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
          color: colorIcono ?? AppColors.text60,
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
