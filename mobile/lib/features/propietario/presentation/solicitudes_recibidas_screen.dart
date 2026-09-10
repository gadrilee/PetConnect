import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/encabezado.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo rechazar la solicitud.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();
    final solicitudes = provider.solicitudes;

    final Widget cuerpo;
    if (provider.cargando && solicitudes.isEmpty) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && solicitudes.isEmpty) {
      cuerpo = _NoCargo(mensaje: provider.error!, alReintentar: provider.cargar);
    } else if (solicitudes.isEmpty) {
      cuerpo = const _SinSolicitudes();
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: provider.cargar,
        child: ListView(
          padding: const EdgeInsets.all(Espacio.lg),
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Grilla.anchoMaximo),
                // GRID: una tarjeta por fila en movil, dos en tablet y tres
                // en escritorio. Las tarjetas no se achican: cambian de fila.
                child: Grilla12(
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
                          alRechazar: provider.procesando(s.id)
                              ? null
                              : () => _rechazar(s.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const Encabezado(titulo: 'Gestionar Solicitudes'),
      body: cuerpo,
    );
  }
}

/// Pantalla 4: todavia no llego ninguna solicitud.
class _SinSolicitudes extends StatelessWidget {
  const _SinSolicitudes();

  @override
  Widget build(BuildContext context) {
    // CONSTRAINTS: el mensaje queda centrado en los dos ejes y no pasa de 360
    // de ancho, para que en escritorio no se lea como una sola linea eterna.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(Espacio.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: AppColors.text.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Espacio.md),
              Text(
                'Aún no tenés solicitudes',
                textAlign: TextAlign.center,
                style: AppText.heading(context)
                    .copyWith(color: AppColors.text, fontSize: 18),
              ),
              const SizedBox(height: Espacio.sm),
              Text(
                'Cuando los inquilinos soliciten ver tus inmuebles, '
                'aparecerán aquí.',
                textAlign: TextAlign.center,
                style: AppText.body(context)
                    .copyWith(color: AppColors.text.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No se pudo cargar la bandeja.
///
/// Antes este caso caia en "Aún no tenés solicitudes", que es falso: la
/// propietaria creia que nadie le habia escrito cuando el problema era la
/// conexion.
class _NoCargo extends StatelessWidget {
  const _NoCargo({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final Future<void> Function() alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(Espacio.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: Espacio.md),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: AppText.body(context).copyWith(color: AppColors.text),
              ),
              const SizedBox(height: Espacio.lg),
              BotonSecundario(etiqueta: 'Reintentar', alTocar: alReintentar),
            ],
          ),
        ),
      ),
    );
  }
}
