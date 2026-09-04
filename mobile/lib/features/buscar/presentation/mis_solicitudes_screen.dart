import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Solicitudes'),
        leading: const BackButton(),
      ),
      body: provider.cargando && provider.solicitudes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.solicitudes.isEmpty
          ? const _SinHistorial()
          : RefreshIndicator(
              onRefresh: provider.cargar,
              child: ListView.separated(
                padding: const EdgeInsets.all(Espacio.lg),
                itemCount: provider.solicitudes.length,
                separatorBuilder: (_, i) => const SizedBox(height: Espacio.md),
                itemBuilder: (ctx, i) {
                  final solicitud = provider.solicitudes[i];
                  return _TarjetaHistorial(
                    solicitud: solicitud,
                    alTocar: () => _verEstado(solicitud),
                  );
                },
              ),
            ),
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.solicitud, required this.alTocar});

  final SolicitudVisita solicitud;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    final fotoUrl = solicitud.anuncio.fotos.isNotEmpty
        ? solicitud.anuncio.fotos.first.imagen
        : '';

    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(Espacio.md),
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: esquema.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto en miniatura
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: fotoUrl.isEmpty
                  ? Container(
                      width: 60,
                      height: 60,
                      color: esquema.surfaceContainerHighest,
                      child: Icon(
                        Icons.home_outlined,
                        color: esquema.onSurfaceVariant,
                      ),
                    )
                  : Image.network(
                      fotoUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, e) => Container(
                        width: 60,
                        height: 60,
                        color: esquema.surfaceContainerHighest,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 24,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    solicitud.anuncio.titulo,
                    style: texto.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Espacio.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: esquema.onSurfaceVariant,
                      ),
                      const SizedBox(width: Espacio.xs),
                      Text(
                        'Enviada: ${solicitud.creadaEn.day}/${solicitud.creadaEn.month}',
                        style: texto.bodySmall?.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espacio.sm),
                  EtiquetaEstado(
                    estado: switch (solicitud.estado) {
                      EstadoSolicitud.aprobada => TipoEstado.aprobada,
                      EstadoSolicitud.rechazada => TipoEstado.rechazada,
                      EstadoSolicitud.pendiente => TipoEstado.pendiente,
                    },
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SinHistorial extends StatelessWidget {
  const _SinHistorial();

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
              Icons.inbox_outlined,
              size: 64,
              color: esquema.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Espacio.md),
            Text(
              'Aún no enviaste solicitudes',
              style: texto.titleMedium?.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Espacio.sm),
            Text(
              'Cuando busques un anuncio y solicites una visita, podrás ver su estado aquí.',
              textAlign: TextAlign.center,
              style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
