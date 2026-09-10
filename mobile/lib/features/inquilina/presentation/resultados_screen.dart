import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/resumen_busqueda.dart';
import '../../../shared/widgets/tarjeta_anuncio.dart';
import '../providers/buscar_provider.dart';
import 'anuncio_screen.dart';

/// Vista 03 — Resultados de búsqueda.
///
/// Lista de tarjetas ordenadas por cercania (el backend ya los ordena por
/// minutos_caminando ASC). Al tocar una tarjeta se navega al detalle.
class ResultadosScreen extends StatelessWidget {
  const ResultadosScreen({super.key});

  static const _titulo = 'Resultados';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuscarProvider>();
    final filtros = provider.filtros;
    final resultados = provider.resultados;

    if (provider.cargando) {
      return const Pagina(titulo: _titulo, cuerpo: CircularProgressIndicator());
    }

    if (resultados.isEmpty) {
      final error = provider.error;
      return Pagina(
        titulo: _titulo,
        // Un error nunca se muestra como "no hay anuncios": seria falso.
        cuerpo: error != null
            ? EstadoVacio(
                icono: Icons.wifi_off_outlined,
                titulo: error,
                esError: true,
                accion: filtros == null ? null : 'Reintentar',
                alAccion:
                    filtros == null ? null : () => provider.buscar(filtros),
              )
            : const EstadoVacio(
                icono: Icons.search_off,
                titulo: 'No encontramos anuncios\ncon esos filtros.',
                detalle: 'Probá ampliando el precio o los minutos.',
              ),
      );
    }

    return Pagina(
      titulo: _titulo,
      hijos: [
        // GRID: la lista en 8 columnas y "Tu búsqueda" en 4, como en Figma. En
        // movil el resumen baja debajo de la lista.
        Grilla12(
          separacionFilas: Espacio.lg,
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ordenados por cercanía a la UAGRM',
                    style: AppText.caption(context).copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                  for (var i = 0; i < resultados.length; i++) ...[
                    SizedBox(height: i == 0 ? Espacio.lg : Espacio.md),
                    TarjetaAnuncio(
                      anuncio: resultados[i],
                      alTocar: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AnuncioScreen(anuncioId: resultados[i].id),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (filtros != null)
              CeldaGrilla(
                columnas: const Columnas(tablet: 4),
                child: ResumenBusqueda(
                  filtros: filtros,
                  cantidad: resultados.length,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
