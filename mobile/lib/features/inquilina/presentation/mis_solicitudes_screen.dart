import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/foto_inmueble.dart';
import '../data/solicitud.dart';
import '../data/solicitudes_repository.dart';
import '../providers/mis_solicitudes_provider.dart';
import '../providers/solicitud_provider.dart';
import 'solicitud_estado_screen.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<MisSolicitudesProvider>().cargar();
    });
  }

  /// Abre el estado de una solicitud y refresca la lista al volver.
  ///
  /// Usa el `context` del State, no uno recibido por parametro: `mounted`
  /// habla de este State, asi que solo garantiza que ese context siga vivo.
  /// Con un context ajeno la comprobacion no probaba nada.
  void _verEstado(SolicitudVisita solicitud) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (ctx) =>
                  SolicitudProvider(ctx.read<SolicitudesRepository>())
                    ..setSolicitud(solicitud),
              child: const SolicitudEstadoScreen(),
            ),
          ),
        )
        .then((_) {
          if (!mounted) return;
          context.read<MisSolicitudesProvider>().cargar();
        });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MisSolicitudesProvider>();
    final solicitudes = provider.solicitudes;

    Widget? cuerpo;
    if (provider.cargando && solicitudes.isEmpty) {
      cuerpo = const CircularProgressIndicator();
    } else if (provider.error != null && solicitudes.isEmpty) {
      // Un error nunca se muestra como vacio: decir "aún no enviaste" cuando
      // fallo la conexion hace creer algo falso.
      cuerpo = EstadoVacio(
        icono: Icons.error_outline,
        titulo: provider.error!,
        esError: true,
        accion: 'Reintentar',
        alAccion: provider.cargar,
      );
    } else if (solicitudes.isEmpty) {
      cuerpo = const EstadoVacio(
        icono: Icons.inbox_outlined,
        titulo: 'Aún no enviaste solicitudes',
        detalle:
            'Cuando busques un anuncio y solicites una visita, podrás ver su estado aquí.',
      );
    }

    return Pagina(
      titulo: 'Estado de Solicitudes',
      alRefrescar: provider.cargar,
      cuerpo: cuerpo,
      hijos: [
        // GRID: una solicitud por fila en movil, dos en tablet y tres en
        // escritorio. Las tarjetas no se achican: cambian de fila.
        Grilla12(
          celdas: [
            for (final solicitud in solicitudes)
              CeldaGrilla(
                columnas: const Columnas(tablet: 6, escritorio: 4),
                child: _TarjetaHistorial(
                  solicitud: solicitud,
                  alTocar: () => _verEstado(solicitud),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Una solicitud enviada: que anuncio, cuando y en que quedo.
class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.solicitud, required this.alTocar});

  final SolicitudVisita solicitud;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final fotos = solicitud.anuncio.fotos;

    return Bloque(
      alTocar: alTocar,
      // FLEXBOX: la foto y la flecha miden lo suyo; los datos toman el resto.
      child: Row(
        children: [
          FotoInmueble(
            url: fotos.isNotEmpty ? fotos.first.imagen : null,
            ancho: 64,
            alto: 64,
          ),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.anuncio.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppText.button(context).copyWith(color: AppColors.text),
                ),
                const SizedBox(height: Espacio.xs),
                FilaCondicion(
                  icono: Icons.calendar_today_outlined,
                  tamanoIcono: 14,
                  maxLineas: 1,
                  texto:
                      'Enviada: ${solicitud.creadaEn.day}/${solicitud.creadaEn.month}',
                  estilo: AppText.caption(context)
                      .copyWith(color: AppColors.text.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: Espacio.sm),
                EtiquetaEstado.solicitud(solicitud.estado),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
