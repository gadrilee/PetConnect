import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/tarjeta_anuncio.dart';
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
                  padding: const EdgeInsets.fromLTRB(
                    Espacio.lg,
                    Espacio.md,
                    Espacio.lg,
                    0,
                  ),
                  child: Text(
                    'Ordenados por cercanía a la UAGRM',
                    style: texto.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Espacio.lg,
                      Espacio.lg,
                      Espacio.lg,
                      Espacio.lg,
                    ),
                    itemCount: provider.resultados.length,
                    separatorBuilder: (_, i) =>
                        const SizedBox(height: Espacio.md),
                    itemBuilder: (ctx, i) {
                      final anuncio = provider.resultados[i];
                      return TarjetaAnuncio(
                        anuncio: anuncio,
                        alTocar: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AnuncioScreen(anuncioId: anuncio.id),
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

class _SinResultados extends StatelessWidget {
  const _SinResultados({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espacio.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error != null ? Icons.wifi_off_outlined : Icons.search_off,
              size: 64,
              color: esquema.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Espacio.md),
            Text(
              error ?? 'No encontramos anuncios\ncon esos filtros.',
              textAlign: TextAlign.center,
              style: texto.bodyLarge?.copyWith(color: esquema.onSurfaceVariant),
            ),
            if (error == null) ...[
              const SizedBox(height: Espacio.sm),
              Text(
                'Probá ampliando el precio o los minutos.',
                textAlign: TextAlign.center,
                style: texto.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
