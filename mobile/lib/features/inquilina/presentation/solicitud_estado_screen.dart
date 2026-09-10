import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
import '../../../shared/widgets/icono_circulo.dart';
import '../../../shared/widgets/tarjeta_anuncio.dart';
import '../data/solicitud.dart';
import '../providers/solicitud_provider.dart';

/// Vista 06 / 07 — Estado de la solicitud enviada.
///
/// Vista 06 (Solicitud enviada): cuando está PENDIENTE, muestra ícono de
/// espera y el resumen del anuncio. El botón refresca el estado.
///
/// Vista 07 (Contacto liberado): cuando está APROBADA y [contacto] no es
/// null, muestra el WhatsApp del propietario con un botón para abrirlo.
/// La pantalla detecta el estado automáticamente.
class SolicitudEstadoScreen extends StatelessWidget {
  const SolicitudEstadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudProvider>();
    final solicitud = provider.solicitud;

    if (solicitud == null) {
      return const Pagina(cuerpo: CircularProgressIndicator());
    }

    final aprobada = solicitud.estaAprobada && solicitud.contacto != null;

    // CONSTRAINTS: es una confirmacion, asi que va en una sola columna del
    // ancho de un formulario, centrada.
    return Pagina(
      titulo: '✓ Listo',
      conBotonVolver: false,
      ancho: AnchoPagina.formulario,
      // La accion principal va fija abajo, como en el wireframe y como en el
      // resto del flujo. Dentro del scroll podia quedar fuera de pantalla.
      pie: _Acciones(solicitud: solicitud, provider: provider),
      hijos: [
        const SizedBox(height: Espacio.sm),
        if (aprobada)
          _VistaAprobada(solicitud: solicitud)
        else
          _VistaPendiente(solicitud: solicitud),
      ],
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
      Aviso.mostrarToast(
        context,
        mensaje: 'No se pudo abrir WhatsApp.',
        tipo: TipoAviso.error,
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
    final aprobada = solicitud.estaAprobada && solicitud.contacto != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aprobada) ...[
          // La nota va ARRIBA del boton, como en el wireframe: se lee antes
          // de tocar, no despues.
          Text(
            'Coordiná la visita por WhatsApp antes de ir.',
            textAlign: TextAlign.center,
            style: AppText.caption(context)
                .copyWith(color: AppColors.text.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: Espacio.sm),
          BotonPrincipal(
            etiqueta: 'ABRIR WHATSAPP',
            alTocar: () => _abrirWhatsApp(context, solicitud.contacto!),
          ),
        ] else ...[
          if (solicitud.estaPendiente) ...[
            BotonSecundario(
              icono: Icons.refresh,
              etiqueta: 'ACTUALIZAR ESTADO',
              alTocar: provider.cargando ? null : () => provider.refrescar(),
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
    );
  }
}

// ------------------------------------------------------------ Vista 07 — Aprobada

class _VistaAprobada extends StatelessWidget {
  const _VistaAprobada({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final contacto = solicitud.contacto!;
    final partes = contacto.split('·');
    final nombre = partes.first.trim();
    final numero = partes.length > 1 ? partes.last.trim() : '';
    final tenue = AppColors.text.withValues(alpha: 0.7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: IconoCirculo(
            Icons.check,
            diametro: 72,
            tono: TonoIcono.exito,
            relleno: true,
          ),
        ),
        const SizedBox(height: Espacio.lg),
        Text(
          'Solicitud aprobada',
          textAlign: TextAlign.center,
          style: AppText.cifra(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          'Ya podés coordinar la visita por WhatsApp.',
          textAlign: TextAlign.center,
          style: AppText.body(context).copyWith(color: tenue),
        ),
        const SizedBox(height: Espacio.xl),

        // En que quedo la solicitud. Estaba solo en la vista pendiente, asi
        // que al aprobarse desaparecia el unico rotulo que decia el estado.
        Center(child: EtiquetaEstado.solicitud(solicitud.estado)),
        const SizedBox(height: Espacio.lg),

        // ---- Contacto liberado ----
        Bloque(
          tono: TonoBloque.destacado,
          hijos: [
            Text(
              'CONTACTO LIBERADO',
              style: AppText.caption(context).copyWith(
                color: AppColors.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Espacio.sm),
            // FLEXBOX: el icono mide lo suyo y los datos toman el resto.
            Row(
              children: [
                const IconoCirculo(
                  Icons.chat_bubble_outline,
                  diametro: 32,
                  relleno: true,
                ),
                const SizedBox(width: Espacio.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre.isNotEmpty ? nombre : contacto,
                        style: AppText.button(context)
                            .copyWith(color: AppColors.text),
                      ),
                      if (numero.isNotEmpty)
                        Text(
                          numero,
                          style:
                              AppText.caption(context).copyWith(color: tenue),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espacio.sm),
            Text(
              'Solo vos podés ver este contacto.',
              style: AppText.caption(context).copyWith(color: tenue),
            ),
          ],
        ),
        const SizedBox(height: Espacio.md),

        // ---- Resumen del anuncio ----
        TarjetaAnuncio(
          anuncio: solicitud.anuncio,
          tamano: TamanoTarjeta.compacta,
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Vista 06 — Pendiente

class _VistaPendiente extends StatelessWidget {
  const _VistaPendiente({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final rechazada = solicitud.estaRechazada;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: IconoCirculo(
            rechazada ? Icons.cancel_outlined : Icons.hourglass_top_outlined,
            diametro: 72,
            tono: rechazada ? TonoIcono.error : TonoIcono.neutro,
          ),
        ),
        const SizedBox(height: Espacio.lg),
        Text(
          rechazada ? 'Solicitud rechazada' : 'Solicitud enviada',
          textAlign: TextAlign.center,
          style: AppText.cifra(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          rechazada
              ? 'El propietario rechazó la solicitud. Podés buscar otros anuncios.'
              : 'El propietario tiene que aceptar tu solicitud antes de recibir su contacto.',
          textAlign: TextAlign.center,
          style: AppText.body(context)
              .copyWith(color: AppColors.text.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: Espacio.md),
        Center(child: EtiquetaEstado.solicitud(solicitud.estado)),
        const SizedBox(height: Espacio.lg),

        // ---- Resumen del anuncio ----
        TarjetaAnuncio(
          anuncio: solicitud.anuncio,
          tamano: TamanoTarjeta.compacta,
        ),

        // ---- Contacto aún protegido ----
        if (solicitud.estaPendiente) ...[
          const SizedBox(height: Espacio.lg),
          const Aviso(
            icono: Icons.lock_outline,
            mensaje:
                'El contacto se libera recién cuando el propietario aprueba.',
          ),
        ],
      ],
    );
  }
}
