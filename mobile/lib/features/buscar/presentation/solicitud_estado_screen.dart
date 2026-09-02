import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../data/solicitud.dart';
import '../providers/solicitud_provider.dart';

/// Vista 05 / 06 — Estado de la solicitud enviada.
///
/// Vista 05 (Solicitud enviada): cuando está PENDIENTE, muestra ícono de
/// espera y el resumen del anuncio. El botón refresca el estado.
///
/// Vista 06 (Contacto liberado): cuando está APROBADA y [contacto] no es
/// null, muestra el WhatsApp del propietario con un botón para abrirlo.
/// La pantalla detecta el estado automáticamente.
class SolicitudEstadoScreen extends StatelessWidget {
  const SolicitudEstadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudProvider>();
    final solicitud = provider.solicitud;

    if (solicitud == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('✓ Listo'),
        automaticallyImplyLeading: false,
      ),
      body: solicitud.estaAprobada && solicitud.contacto != null
          ? _VistaAprobada(solicitud: solicitud)
          : _VistaPendiente(solicitud: solicitud, provider: provider),
      // La accion principal va fija abajo, como en el wireframe y como en el
      // resto del flujo. Dentro del scroll podia quedar fuera de pantalla.
      bottomNavigationBar: _Acciones(solicitud: solicitud, provider: provider),
    );
  }
}

/// Abre WhatsApp con el numero del propietario.
///
/// El contacto viene como "Nombre · 70011122": se extrae solo el numero.
Future<void> _abrirWhatsApp(BuildContext context, String contacto) async {
  final partes = contacto.split('·');
  final numero = partes.last.trim().replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('https://wa.me/591$numero');

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Lo que se puede hacer desde esta pantalla, fijo al pie.
///
/// Cambia con el estado de la solicitud, pero el lugar no: la persona no
/// tiene que buscar el boton en dos sitios distintos segun como le fue.
class _Acciones extends StatelessWidget {
  const _Acciones({required this.solicitud, required this.provider});

  final SolicitudVisita solicitud;
  final SolicitudProvider provider;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final aprobada = solicitud.estaAprobada && solicitud.contacto != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Espacio.lg,
        Espacio.sm,
        Espacio.lg,
        MediaQuery.of(context).padding.bottom + Espacio.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (aprobada) ...[
            // La nota va ARRIBA del boton, como en el wireframe: se lee antes
            // de tocar, no despues.
            Text(
              'Coordiná la visita por WhatsApp antes de ir.',
              textAlign: TextAlign.center,
              style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
            const SizedBox(height: Espacio.sm),
            BotonPrincipal(
              etiqueta: 'ABRIR WHATSAPP',
              alTocar: () => _abrirWhatsApp(context, solicitud.contacto!),
            ),
          ] else ...[
            if (solicitud.estaPendiente) ...[
              OutlinedButton.icon(
                onPressed: provider.cargando
                    ? null
                    : () => provider.refrescar(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualizar estado'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(Medida.boton),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: Espacio.sm),
            ],
            BotonPrincipal(
              etiqueta: 'VOLVER A LOS RESULTADOS',
              alTocar: () => Navigator.of(context).popUntil((r) => r.isFirst),
              cargando: provider.cargando,
            ),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Vista 06 — Aprobada

class _VistaAprobada extends StatelessWidget {
  const _VistaAprobada({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final contacto = solicitud.contacto!;
    final partes = contacto.split('·');
    final nombre = partes.first.trim();
    final numero = partes.length > 1 ? partes.last.trim() : '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espacio.lg,
        Espacio.xl,
        Espacio.lg,
        Espacio.lg,
      ),
      children: [
        // ---- Ícono aprobado ----
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: esquema.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 40, color: esquema.onPrimary),
          ),
        ),

        const SizedBox(height: Espacio.lg),

        Text(
          'Solicitud aprobada',
          textAlign: TextAlign.center,
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          'Ya podés coordinar la visita por WhatsApp.',
          textAlign: TextAlign.center,
          style: texto.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),

        const SizedBox(height: Espacio.xl),

        // En que quedo la solicitud. Estaba solo en la vista pendiente, asi
        // que al aprobarse desaparecia el unico rotulo que decia el estado.
        _EtiquetaEstado(solicitud: solicitud),

        const SizedBox(height: Espacio.lg),

        // ---- Contacto liberado ----
        Container(
          padding: const EdgeInsets.all(Espacio.md),
          decoration: BoxDecoration(
            color: esquema.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: esquema.primary.withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTACTO LIBERADO',
                style: texto.labelSmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: Espacio.sm),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: esquema.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: esquema.onPrimary,
                    ),
                  ),
                  const SizedBox(width: Espacio.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre.isNotEmpty ? nombre : contacto,
                          style: texto.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (numero.isNotEmpty)
                          Text(
                            numero,
                            style: texto.bodySmall?.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacio.sm),
              Text(
                'Solo vos podés ver este contacto.',
                style: texto.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Espacio.md),

        // ---- Resumen del anuncio ----
        _TarjetaAnuncio(solicitud: solicitud),
      ],
    );
  }
}

// ------------------------------------------------------------ Vista 05 — Pendiente

class _VistaPendiente extends StatelessWidget {
  const _VistaPendiente({required this.solicitud, required this.provider});

  final SolicitudVisita solicitud;
  final SolicitudProvider provider;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espacio.lg,
        Espacio.xl,
        Espacio.lg,
        Espacio.lg,
      ),
      children: [
        // ---- Ícono de espera ----
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: esquema.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: esquema.outline.withValues(alpha: 0.5)),
            ),
            child: Icon(
              solicitud.estaRechazada
                  ? Icons.cancel_outlined
                  : Icons.hourglass_top_outlined,
              size: 40,
              color: solicitud.estaRechazada
                  ? esquema.error
                  : esquema.onSurfaceVariant,
            ),
          ),
        ),

        const SizedBox(height: Espacio.lg),

        Text(
          solicitud.estaRechazada ? 'Solicitud rechazada' : 'Solicitud enviada',
          textAlign: TextAlign.center,
          style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          solicitud.estaRechazada
              ? 'El propietario rechazó la solicitud. Podés buscar otros anuncios.'
              : 'El propietario tiene que aceptar tu solicitud antes de recibir su contacto.',
          textAlign: TextAlign.center,
          style: texto.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),

        const SizedBox(height: Espacio.md),

        _EtiquetaEstado(solicitud: solicitud),

        const SizedBox(height: Espacio.lg),

        // ---- Resumen del anuncio ----
        _TarjetaAnuncio(solicitud: solicitud),

        const SizedBox(height: Espacio.lg),

        // ---- Contacto aún protegido ----
        if (solicitud.estaPendiente)
          Container(
            padding: const EdgeInsets.all(Espacio.md),
            decoration: BoxDecoration(
              color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: esquema.onSurfaceVariant,
                ),
                const SizedBox(width: Espacio.sm),
                Expanded(
                  child: Text(
                    'El contacto se libera recién cuando el propietario aprueba.',
                    style: texto.bodySmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// En que esta la solicitud.
///
/// Una sola pieza con un estado por variante, igual que en el wireframe: el
/// texto y el color **se derivan** del estado. Si se pasaran por parametro,
/// tarde o temprano habria una etiqueta verde que dice "Pendiente".
class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    final color = switch (solicitud.estado) {
      EstadoSolicitud.pendiente => Colors.orange,
      EstadoSolicitud.rechazada => esquema.error,
      _ => esquema.primary,
    };

    return Center(
      child: Chip(
        label: Text(
          solicitud.estado.etiqueta,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        side: BorderSide(color: color.withValues(alpha: 0.6)),
        backgroundColor: color.withValues(alpha: 0.08),
      ),
    );
  }
}

// --------------------------------------------------------- Widget compartido

class _TarjetaAnuncio extends StatelessWidget {
  const _TarjetaAnuncio({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final anuncio = solicitud.anuncio;

    return Container(
      padding: const EdgeInsets.all(Espacio.md),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto miniatura
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: anuncio.fotos.isNotEmpty
                ? Image.network(
                    anuncio.fotos.first.imagen,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, e) => _placeholder(esquema),
                  )
                : _placeholder(esquema),
          ),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anuncio.titulo.isNotEmpty)
                  Text(
                    anuncio.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texto.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: Espacio.sm),
                Text(
                  '${anuncio.precioFinal} Bs / mes',
                  style: texto.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${anuncio.minutosCaminando} min caminando a la UAGRM',
                  style: texto.bodySmall?.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme esquema) => Container(
    width: 64,
    height: 64,
    color: esquema.surfaceContainerHighest,
    child: Icon(Icons.home_outlined, color: esquema.onSurfaceVariant),
  );
}
