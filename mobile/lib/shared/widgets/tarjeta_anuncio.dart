import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/anuncios/data/anuncio.dart';

/// Cuanto espacio ocupa la tarjeta, segun el papel del anuncio en la pantalla.
enum TamanoTarjeta {
  /// El anuncio ES la decision: en los resultados, la tarjeta tiene que
  /// alcanzar para descartar sin abrirlo.
  completa,

  /// El anuncio es contexto: ya se decidio y solo hace falta reconocer cual
  /// era (una solicitud enviada, por ejemplo).
  compacta,
}

/// Un anuncio resumido.
///
/// REGLA DE LA PIEZA
/// -----------------
/// La foto va a la izquierda y **el precio se lee primero**, porque es el
/// criterio de descarte n.º 1. Entre tamanos cambian la foto y cuantos datos
/// entran; nunca cambia el orden ni que el precio venga acompanado de lo que
/// cubre.
///
/// **Por que existe esta pieza.** Antes estaba escrita dos veces, una por
/// pantalla. La prueba con usuaria mostro que un monto sin decir que incluye
/// no significa nada —vio "1.000 Bs" y pregunto "¿cuanto es con luz?"— y la
/// correccion se aplico solo a la copia de los resultados. La de la solicitud
/// siguio mostrando el precio pelado. Una sola pieza hace imposible que la
/// proxima correccion llegue a la mitad de las pantallas.
class TarjetaAnuncio extends StatelessWidget {
  const TarjetaAnuncio({
    super.key,
    required this.anuncio,
    this.tamano = TamanoTarjeta.completa,
    this.alTocar,
  });

  final Anuncio anuncio;
  final TamanoTarjeta tamano;

  /// Que hacer al tocarla. `null` la deja como bloque de lectura, sin
  /// respuesta al toque: prometer algo que no pasa es peor que no prometer.
  final VoidCallback? alTocar;

  bool get _esCompleta => tamano == TamanoTarjeta.completa;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final lado = _esCompleta ? 104.0 : 64.0;

    final contenido = Padding(
      padding: const EdgeInsets.all(Espacio.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _Foto(
              foto: anuncio.fotos.isNotEmpty ? anuncio.fotos.first : null,
              lado: lado,
            ),
          ),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titulo(esquema, texto),
                const SizedBox(height: Espacio.sm),

                // El precio y lo que cubre son un solo dato: separarlos fue
                // lo que obligo a preguntar durante la prueba.
                if (_esCompleta) ...[
                  Text(
                    '${anuncio.precioFinal} Bs / mes',
                    style: texto.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: esquema.onSurface,
                    ),
                  ),
                  const SizedBox(height: Espacio.sm),
                  Text(
                    cobertura(anuncio),
                    style: texto.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else
                  // En la compacta no sobra alto, asi que van en una linea.
                  // Lo que no se hace es dejar el monto solo.
                  Text(
                    '${anuncio.precioFinal} Bs / mes · ${cobertura(anuncio)}',
                    style: texto.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: Espacio.sm),
                Text(
                  '${anuncio.minutosCaminando} min caminando a la UAGRM',
                  style: texto.bodySmall?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // La flecha solo si de verdad se puede entrar.
          if (alTocar != null) const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );

    return Container(
      height: _esCompleta ? 136.0 : 96.0,
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: alTocar == null
          ? contenido
          : InkWell(onTap: alTocar, child: contenido),
    );
  }

  /// El titulo, o una barra gris si el anuncio no tiene.
  Widget _titulo(ColorScheme esquema, TextTheme texto) {
    if (anuncio.titulo.isNotEmpty) {
      return Text(
        anuncio.titulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: texto.labelLarge?.copyWith(
          color: esquema.onSurface,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Container(
      height: Espacio.sm,
      width: 140,
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Foto extends StatelessWidget {
  const _Foto({required this.foto, required this.lado});

  final FotoAnuncio? foto;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    Widget marcador([IconData icono = Icons.home_outlined]) => Container(
      width: lado,
      height: lado,
      color: esquema.surfaceContainerHighest,
      child: Icon(icono, color: esquema.onSurfaceVariant, size: lado / 2.75),
    );

    if (foto == null) return marcador();

    return Image.network(
      foto!.imagen,
      width: lado,
      height: lado,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => marcador(Icons.broken_image_outlined),
      loadingBuilder: (_, hijo, progreso) => progreso == null
          ? hijo
          : SizedBox(
              width: lado,
              height: lado,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}

/// Que cubre el precio final, en una sola linea.
///
/// Nombra tambien lo que NO esta incluido: omitirlo impide distinguir "no
/// entra en el precio" de "no lo dijeron", y es justo lo que obligo a una
/// usuaria a preguntar "¿cuanto es con luz?" durante la prueba.
String cobertura(Anuncio anuncio) {
  const nombres = {'agua': 'agua', 'luz': 'luz', 'internet': 'internet'};

  final incluidos = <String>[];
  final faltan = <String>[];
  nombres.forEach((clave, nombre) {
    (anuncio.serviciosIncluidos[clave] == true ? incluidos : faltan).add(
      nombre,
    );
  });

  if (faltan.isEmpty) return 'todo incluido';
  if (incluidos.isEmpty) return 'servicios no incluidos';
  return 'incluye ${incluidos.join(" y ")} · ${faltan.join(" y ")} no';
}
