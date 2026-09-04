import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../buscar/data/solicitud.dart';
import '../providers/solicitudes_recibidas_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Solicitudes'),
        leading: const BackButton(),
      ),
      body: provider.cargando && provider.solicitudes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.solicitudes.isEmpty
              ? const _SinSolicitudes()
              : RefreshIndicator(
                  onRefresh: provider.cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: provider.solicitudes.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) =>
                        _TarjetaSolicitud(solicitud: provider.solicitudes[i]),
                  ),
                ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  const _TarjetaSolicitud({required this.solicitud});

  final SolicitudVisita solicitud;

  void _aprobar(BuildContext context) async {
    final ok = await context
        .read<SolicitudesRecibidasProvider>()
        .aprobar(solicitud.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aprobar la solicitud.')),
      );
    }
  }

  void _rechazar(BuildContext context) async {
    final ok = await context
        .read<SolicitudesRecibidasProvider>()
        .rechazar(solicitud.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo rechazar la solicitud.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    final colorBorde = switch (solicitud.estado) {
      EstadoSolicitud.aprobada => esquema.primary,
      EstadoSolicitud.rechazada => esquema.error,
      _ => esquema.outline.withValues(alpha: 0.4),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: ID y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solicitud #${solicitud.id}',
                style: texto.labelSmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
              Chip(
                label: Text(
                  solicitud.estado.etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: switch (solicitud.estado) {
                      EstadoSolicitud.aprobada => esquema.onPrimaryContainer,
                      EstadoSolicitud.rechazada => esquema.onErrorContainer,
                      _ => esquema.onSurfaceVariant,
                    },
                  ),
                ),
                backgroundColor: switch (solicitud.estado) {
                  EstadoSolicitud.aprobada => esquema.primaryContainer,
                  EstadoSolicitud.rechazada => esquema.errorContainer,
                  _ => esquema.surfaceContainerHighest,
                },
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Anuncio
          Row(
            children: [
              Icon(Icons.home_outlined, size: 24, color: esquema.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  solicitud.anuncio.titulo,
                  style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Inquilino
          Row(
            children: [
              Icon(Icons.person_outline, size: 24, color: esquema.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Inquilino interesado',
                style: texto.bodyMedium?.copyWith(color: esquema.onSurface),
              ),
            ],
          ),

          // Fecha
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 24, color: esquema.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Recibida el ${solicitud.creadaEn.day}/${solicitud.creadaEn.month}/${solicitud.creadaEn.year}',
                style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
            ],
          ),

          // Botones (Solo si está pendiente)
          if (solicitud.estaPendiente) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rechazar(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: esquema.error,
                      side: BorderSide(color: esquema.error.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _aprobar(context),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SinSolicitudes extends StatelessWidget {
  const _SinSolicitudes();

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
              Icons.mark_email_read_outlined,
              size: 64,
              color: esquema.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tenés solicitudes',
              style: texto.titleMedium?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando los inquilinos soliciten ver tus inmuebles, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
