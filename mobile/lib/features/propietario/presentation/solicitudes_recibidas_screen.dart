import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/tarjeta_solicitud.dart';
import '../providers/solicitudes_recibidas_provider.dart';
import 'solicitud_detalle_screen.dart';

/// Flujo v0.4, pantallas 0 y 4: la bandeja de solicitudes recibidas.
///
/// Las pendientes van primero porque son las unicas que piden algo. Las ya
/// respondidas quedan debajo, con su color, como registro.
class SolicitudesRecibidasScreen extends StatefulWidget {
  const SolicitudesRecibidasScreen({super.key});

  @override
  State<SolicitudesRecibidasScreen> createState() =>
      _SolicitudesRecibidasScreenState();
}

class _SolicitudesRecibidasScreenState
    extends State<SolicitudesRecibidasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<SolicitudesRecibidasProvider>().cargar();
    });
  }

  /// Aprobar siempre pasa por el detalle: ahi se ve a quien se le libera el
  /// contacto y con que condiciones. Rechazar no libera nada, asi que se
  /// puede resolver desde la tarjeta.
  void _abrir(int id) {
    final provider = context.read<SolicitudesRecibidasProvider>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: SolicitudDetalleScreen(id: id),
        ),
      ),
    );
  }

  Future<void> _rechazar(int id) async {
    final provider = context.read<SolicitudesRecibidasProvider>();
    final ok = await provider.rechazar(id);
    if (!ok && mounted) {
      Aviso.mostrarToast(
        context,
        mensaje: provider.error ?? 'No se pudo rechazar la solicitud.',
        tipo: TipoAviso.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();
    final solicitudes = provider.solicitudes;

    Widget? cuerpo;
    if (provider.cargando && solicitudes.isEmpty) {
      cuerpo = const CircularProgressIndicator();
    } else if (provider.error != null && solicitudes.isEmpty) {
      // Antes este caso caia en "Aún no tenés solicitudes", que es falso: la
      // propietaria creia que nadie le habia escrito cuando el problema era la
      // conexion.
      cuerpo = EstadoVacio(
        icono: Icons.error_outline,
        titulo: provider.error!,
        esError: true,
        accion: 'Reintentar',
        alAccion: provider.cargar,
      );
    } else if (solicitudes.isEmpty) {
      // Pantalla 4: todavia no llego ninguna solicitud.
      cuerpo = const EstadoVacio(
        icono: Icons.mark_email_read_outlined,
        titulo: 'Aún no tenés solicitudes',
        detalle:
            'Cuando los inquilinos soliciten ver tus inmuebles, aparecerán aquí.',
      );
    }

    return Pagina(
      titulo: 'Gestionar Solicitudes',
      alRefrescar: provider.cargar,
      cuerpo: cuerpo,
      hijos: [
        // GRID: una tarjeta por fila en movil, dos en tablet y tres en
        // escritorio. Las tarjetas no se achican: cambian de fila.
        Grilla12(
          celdas: [
            for (final s in solicitudes)
              CeldaGrilla(
                columnas: const Columnas(tablet: 6, escritorio: 4),
                child: TarjetaSolicitud(
                  numero: s.id,
                  tituloAnuncio: s.anuncio.titulo,
                  inquilino: s.inquilino,
                  fecha: s.creadaEn,
                  estado: s.estado,
                  alTocar: () => _abrir(s.id),
                  alAprobar: () => _abrir(s.id),
                  alRechazar:
                      provider.procesando(s.id) ? null : () => _rechazar(s.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
