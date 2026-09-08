import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/encabezado.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
import '../../../shared/widgets/tarjeta_gestion.dart';
import '../../inquilina/data/solicitud.dart';
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

  void _aprobar(int id) async {
    final ok = await context.read<SolicitudesRecibidasProvider>().aprobar(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aprobar la solicitud.')),
      );
    }
  }

  void _rechazar(int id) async {
    final ok = await context.read<SolicitudesRecibidasProvider>().rechazar(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo rechazar la solicitud.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const Encabezado(titulo: 'Gestionar Solicitudes'),
      body: provider.cargando && provider.solicitudes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.solicitudes.isEmpty
              ? const _SinSolicitudes()
              : RefreshIndicator(
                  onRefresh: provider.cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Espacio.lg),
                    itemCount: provider.solicitudes.length,
                    separatorBuilder: (_, i) => const SizedBox(height: Espacio.md),
                    itemBuilder: (ctx, i) {
                      final sol = provider.solicitudes[i];
                      return TarjetaGestion(
                        id: sol.id.toString(),
                        estado: switch (sol.estado) {
                          EstadoSolicitud.aprobada => TipoEstado.aprobada,
                          EstadoSolicitud.rechazada => TipoEstado.rechazada,
                          _ => TipoEstado.pendiente,
                        },
                        tituloAnuncio: sol.anuncio.titulo,
                        interesado: 'Inquilino interesado',
                        fecha: '${sol.creadaEn.day}/${sol.creadaEn.month}/${sol.creadaEn.year}',
                        estaPendiente: sol.estaPendiente,
                        alAprobar: () => _aprobar(sol.id),
                        alRechazar: () => _rechazar(sol.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _SinSolicitudes extends StatelessWidget {
  const _SinSolicitudes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espacio.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 64,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Espacio.md),
            Text(
              'Aún no tenés solicitudes',
              style: AppText.heading(context).copyWith(color: AppColors.text, fontSize: 18),
            ),
            const SizedBox(height: Espacio.sm),
            Text(
              'Cuando los inquilinos soliciten ver tus inmuebles, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: AppText.body(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
