import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import 'bloque.dart';

/// Como se muestra el precio final.
enum EstiloPrecio {
  /// La barra verde con "Precio final" y la cifra en claro: la de Publicar y
  /// la que encabeza el resumen del anuncio.
  barra,

  /// El bloque gris con la etiqueta arriba y la cifra en verde: el resumen
  /// que acompana una confirmacion, como Solicitar visita.
  resumen,
}

/// El precio final de un anuncio, el criterio de descarte n.º 1 del brief.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El precio final se lee igual en toda la app: siempre la etiqueta "Precio
/// final" y la cifra en `AppText.cifra`, seguida de "Bs / mes". Cambia solo
/// el estilo, [barra] o [resumen]; **ninguna pantalla vuelve a escribir la
/// etiqueta y la cifra sueltas**. Estaba escrita tres veces: en Publicar, en
/// Anuncio y en Solicitar visita.
///
/// **El monto se formatea una sola vez, aca, con [formatear]**: las pantallas
/// pasan el valor crudo de la API y el mismo `1250.00` se lee `1.250` en
/// todas. Habia tres formateadores para un solo numero, y la misma cifra
/// salia "1250.00" en Anuncio y "1.250" en Publicar.
///
/// - AUTO LAYOUT: estira a lo ancho y mide lo que su contenido.
/// - FLEXBOX (barra): la etiqueta a la izquierda y la cifra a la derecha
///   mientras entran en una linea. Si la cifra no entra —un precio largo en un
///   telefono, o la barra dentro de otro bloque— baja entera a la linea
///   siguiente. Responsive no es achicar: la cifra no se corta ni se encoge.
class PrecioFinal extends StatelessWidget {
  const PrecioFinal({
    super.key,
    required this.monto,
    this.estilo = EstiloPrecio.barra,
  });

  /// El monto crudo, tal como llega de la API (`1250.00`), sin la moneda y
  /// sin formatear: de escribirlo se ocupa la pieza.
  final String monto;

  final EstiloPrecio estilo;

  /// La etiqueta, para no repetirla en las pruebas.
  static const String etiqueta = 'Precio final';

  /// Como se escribe un monto en toda la app: `1250.00` se lee `1.250`,
  /// `650.00` se lee `650`. Punto de miles y sin decimales de mas, como en
  /// Figma (1.100 Bs). Es el unico formateador de precios; las pantallas no
  /// tienen el suyo.
  static String formatear(String monto) => NumberFormat.decimalPattern('es')
      .format(double.tryParse(monto) ?? 0);

  /// La cifra completa que se muestra para un [monto] crudo.
  static String cifraDe(String monto) => '${formatear(monto)} Bs / mes';

  @override
  Widget build(BuildContext context) {
    final cifra = cifraDe(monto);

    return switch (estilo) {
      EstiloPrecio.barra => Bloque(
          tono: TonoBloque.primario,
          // CONSTRAINTS: la barra ocupa todo el ancho que le den, aunque el
          // padre no la estire; por eso el Wrap tiene con que repartir.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Espacio.md,
              runSpacing: Espacio.xs,
              children: [
                Text(
                  etiqueta,
                  style: AppText.button(context)
                      .copyWith(color: AppColors.surface),
                ),
                Text(
                  cifra,
                  style:
                      AppText.cifra(context).copyWith(color: AppColors.surface),
                ),
              ],
            ),
          ),
        ),
      EstiloPrecio.resumen => Bloque(
          tono: TonoBloque.suave,
          hijos: [
            Text(
              etiqueta,
              style: AppText.caption(context).copyWith(color: AppColors.text70),
            ),
            const SizedBox(height: Espacio.sm),
            Text(
              cifra,
              style: AppText.cifra(context).copyWith(color: AppColors.primary),
            ),
          ],
        ),
    };
  }
}
