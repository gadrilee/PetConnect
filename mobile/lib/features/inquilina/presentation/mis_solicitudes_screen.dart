import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/tarjeta_historial.dart';
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
        titulo: 'No pudimos cargar tus solicitudes',
        detalle: provider.error,
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
      titulo: 'Estado de solicitudes',
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
                child: TarjetaHistorial(
                  tituloAnuncio: solicitud.anuncio.titulo,
                  enviada: solicitud.creadaEn,
                  estado: solicitud.estado,
                  foto: solicitud.anuncio.fotoPrincipal,
                  alTocar: () => _verEstado(solicitud),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
