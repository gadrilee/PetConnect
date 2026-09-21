import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/propietario/data/anuncio.dart';
import 'bloque.dart';
import 'foto_inmueble.dart';
import 'precio_final.dart';

/// De qué anuncio se está hablando, en dos renglones y una foto.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Aparece cuando la pantalla decide algo **sobre un anuncio** y no lo está
/// listando: aprobar o rechazar una solicitud, marcarlo como alquilado. No es
/// una tarjeta de lista —no se toca, no lleva estado ni acciones—, es el
/// encabezado que dice "esto es de lo que estamos hablando".
///
/// La foto va primero y mide 64, como en todas las tarjetas de la app. Con
/// cuatro anuncios publicados los títulos se parecen entre sí ("Habitación a
/// aprox 10 / 20 / 40 min de la UAGRM"): la foto dice cuál es antes de que
/// haya que leer. Por eso está también acá y no sólo en las listas.
///
/// Estaba escrita dos veces, en Marcar como alquilado y en el Detalle de la
/// solicitud, y sólo una de las dos tenía la foto. Ahora es una sola.
class ResumenAnuncio extends StatelessWidget {
  const ResumenAnuncio({super.key, required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final precio = PrecioFinal.formatear(anuncio.precioFinal);

    return Bloque(
      // FLEXBOX: la foto mide lo suyo y el texto toma el resto.
      hijos: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FotoInmueble(url: anuncio.fotoPrincipal, ancho: 64, alto: 64),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anuncio.titulo,
                    style: AppText.button(context)
                        .copyWith(color: AppColors.text, letterSpacing: 0),
                  ),
                  const SizedBox(height: Espacio.sm),
                  Text(
                    'Tipo: ${anuncio.tipoEspacio.etiqueta} · $precio Bs/mes',
                    style: AppText.caption(context)
                        .copyWith(color: AppColors.text70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
