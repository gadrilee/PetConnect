import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../anuncios/data/anuncio.dart';
import '../providers/buscar_provider.dart';
import 'anuncio_screen.dart';

/// Vista 02 — Resultados de búsqueda.
///
/// Lista de tarjetas ordenadas por cercania (el backend ya los ordena por
/// minutos_caminando ASC). Al tocar una tarjeta se navega al detalle.
class ResultadosScreen extends StatelessWidget {
  const ResultadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuscarProvider>();
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        leading: const BackButton(),
      ),
      body: provider.cargando
          ? const Center(child: CircularProgressIndicator())
          : provider.resultados.isEmpty
              ? _SinResultados(error: provider.error)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        'Ordenados por cercanía a la UAGRM',
                        style: texto.bodySmall
                            ?.copyWith(color: esquema.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: provider.resultados.length,
                        separatorBuilder: (_, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final anuncio = provider.resultados[i];
                          return _TarjetaAnuncio(
                            anuncio: anuncio,
                            alTocar: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AnuncioScreen(anuncioId: anuncio.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// --------------------------------------------------------- Widgets de apoyo

class _TarjetaAnuncio extends StatelessWidget {
  const _TarjetaAnuncio({required this.anuncio, required this.alTocar});

  final Anuncio anuncio;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto principal o placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _FotoMiniatura(
                  foto: anuncio.fotos.isNotEmpty ? anuncio.fotos.first : null,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título (placeholder con color si no hay)
                    if (anuncio.titulo.isNotEmpty)
                      Text(
                        anuncio.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.labelLarge
                            ?.copyWith(color: esquema.onSurface),
                      )
                    else
                      Container(
                        height: 10,
                        width: 140,
                        decoration: BoxDecoration(
                          color: esquema.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    const SizedBox(height: Espacio.sm),
                    // Precio
                    Text(
                      '${anuncio.precioFinal} Bs / mes',
                      style: texto.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: esquema.onSurface),
                    ),
                    // Que cubre ese precio, pegado a la cifra.
                    //
                    // La tarjeta repetia el mismo problema que encontro la
                    // prueba con usuaria en el detalle: mostraba el monto sin
                    // decir que incluye, y asi "1.000 Bs" no significa nada.
                    // El listado es donde primero se descarta, asi que tiene
                    // que responderlo sin abrir el anuncio.
                    Text(
                      _cobertura(anuncio),
                      style: texto.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Espacio.xs),
                    // Minutos
                    Text(
                      '${anuncio.minutosCaminando} min caminando',
                      style: texto.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                    const SizedBox(height: Espacio.xs),
                    // Mascotas + tipo
                    Text(
                      '${anuncio.aceptaMascotas ? "Acepta mascotas" : "Sin mascotas"} · ${anuncio.tipoEspacio.etiqueta}',
                      style: texto.bodySmall
                          ?.copyWith(color: esquema.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoMiniatura extends StatelessWidget {
  const _FotoMiniatura({this.foto});

  final FotoAnuncio? foto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    if (foto == null) {
      return Container(
        width: 88,
        height: 88,
        color: esquema.surfaceContainerHighest,
        child: Icon(Icons.home_outlined,
            color: esquema.onSurfaceVariant, size: 32),
      );
    }

    return Image.network(
      foto!.imagen,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      errorBuilder: (_, _, e) => Container(
        width: 88,
        height: 88,
        color: esquema.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined,
            color: esquema.onSurfaceVariant, size: 32),
      ),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              width: 88,
              height: 88,
              color: esquema.surfaceContainerHighest,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error != null ? Icons.wifi_off_outlined : Icons.search_off,
              size: 64,
              color: esquema.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              error ?? 'No encontramos anuncios\ncon esos filtros.',
              textAlign: TextAlign.center,
              style: texto.bodyLarge
                  ?.copyWith(color: esquema.onSurfaceVariant),
            ),
            if (error == null) ...[
              const SizedBox(height: 8),
              Text(
                'Probá ampliando el precio o los minutos.',
                textAlign: TextAlign.center,
                style: texto.bodySmall
                    ?.copyWith(color: esquema.onSurfaceVariant),
              ),
            ],
          ],
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
String _cobertura(Anuncio anuncio) {
  const nombres = {'agua': 'agua', 'luz': 'luz', 'internet': 'internet'};

  final incluidos = <String>[];
  final faltan = <String>[];
  nombres.forEach((clave, nombre) {
    (anuncio.serviciosIncluidos[clave] == true ? incluidos : faltan).add(nombre);
  });

  if (faltan.isEmpty) return 'todo incluido';
  if (incluidos.isEmpty) return 'servicios no incluidos';
  return 'incluye ${incluidos.join(" y ")} · ${faltan.join(" y ")} no';
}
