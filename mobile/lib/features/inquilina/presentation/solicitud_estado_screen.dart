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
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/tarjeta_anuncio.dart';
import '../data/solicitud.dart';
import '../providers/solicitud_provider.dart';

/// El estado de una solicitud enviada (Figma, flujo de la inquilina).
///
/// 06 Solicitud enviada: cuando está PENDIENTE, muestra ícono de espera y el
/// resumen del anuncio. El botón refresca el estado.
///
/// 08 Contacto liberado: cuando está APROBADA y [contacto] no es null,
/// muestra el WhatsApp del propietario con un botón para abrirlo.
///
/// 09 Solicitud rechazada y 10 Solicitud cerrada: el motivo, sin nada que
/// esperar. La pantalla detecta el estado automáticamente.
class SolicitudEstadoScreen extends StatefulWidget {
  const SolicitudEstadoScreen({super.key});

  /// Validaciones 11: el teléfono no pudo abrir el enlace de WhatsApp.
  static const String noSeAbrioWhatsApp = 'No se pudo abrir WhatsApp.';

  @override
  State<SolicitudEstadoScreen> createState() => _SolicitudEstadoScreenState();
}

class _SolicitudEstadoScreenState extends State<SolicitudEstadoScreen> {
  /// Si no se pudo abrir WhatsApp. Se muestra en el pie, no en un toast.
  String? _errorWhatsApp;

  /// Abre WhatsApp con el numero del propietario.
  ///
  /// El contacto viene como "Nombre · 70011122": se extrae solo el numero.
  Future<void> _abrirWhatsApp(String contacto) async {
    final partes = contacto.split('·');
    final numero = partes.last.trim().replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/591$numero');

    setState(() => _errorWhatsApp = null);
    bool abierto;
    try {
      abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // El telefono no tiene con que abrir el enlace: es el mismo "no se
      // pudo" que cuando launchUrl devuelve false, no un error sin atender.
      abierto = false;
    }
    if (!abierto && mounted) {
      setState(() => _errorWhatsApp = SolicitudEstadoScreen.noSeAbrioWhatsApp);
    }
  }

  /// El pie cambia con el estado de la solicitud, pero el lugar no: la
  /// persona no tiene que buscar el boton en dos sitios distintos segun como
  /// le fue.
  PieAcciones _pie(SolicitudVisita solicitud, SolicitudProvider provider) {
    // Que paso: si no se pudo abrir WhatsApp o si fallo la actualizacion.
    final mensaje = _errorWhatsApp ?? provider.error;
    final aviso =
        mensaje == null ? null : Aviso(tipo: TipoAviso.error, mensaje: mensaje);

    if (solicitud.estaAprobada && solicitud.contacto != null) {
      return PieAcciones(
        aviso: aviso,
        // La nota va ARRIBA del boton: se lee antes de tocar, no despues.
        notaArriba: 'Coordiná la visita por WhatsApp antes de ir.',
        botonPrincipal: BotonPrincipal(
          etiqueta: 'ABRIR WHATSAPP',
          alTocar: () => _abrirWhatsApp(solicitud.contacto!),
        ),
      );
    }

    return PieAcciones(
      aviso: aviso,
      botonSecundarioArriba: solicitud.estaPendiente
          ? BotonSecundario(
              icono: Icons.refresh,
              etiqueta: 'ACTUALIZAR ESTADO',
              alTocar: provider.cargando ? null : () => provider.refrescar(),
            )
          : null,
      botonPrincipal: BotonPrincipal(
        etiqueta: 'VOLVER A LOS RESULTADOS',
        alTocar: () => Navigator.of(context).popUntil((r) => r.isFirst),
        cargando: provider.cargando,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudProvider>();
    final solicitud = provider.solicitud;

    if (solicitud == null) {
      return const Pagina(
        titulo: 'Solicitud enviada',
        cuerpo: CircularProgressIndicator(),
      );
    }

    final aprobada = solicitud.estaAprobada && solicitud.contacto != null;
    final titulo = aprobada
        ? 'Contacto liberado'
        : solicitud.estaRechazada
            ? 'Solicitud rechazada'
            : solicitud.estaCerrada
                ? 'Solicitud cerrada'
                : 'Solicitud enviada';

    // CONSTRAINTS: es una confirmacion, asi que va en una sola columna del
    // ancho de un formulario, centrada.
    return Pagina(
      titulo: titulo,
      ancho: AnchoPagina.formulario,
      // La accion principal va fija abajo, como en el wireframe y como en el
      // resto del flujo. Dentro del scroll podia quedar fuera de pantalla.
      pie: _pie(solicitud, provider),
      hijos: [
        if (aprobada)
          _VistaAprobada(solicitud: solicitud)
        else
          _VistaPendiente(solicitud: solicitud),
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
    final tenue = AppColors.text70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El check va sobre el tinte suave del exito, como el reloj de la
        // vista pendiente sobre el suyo: el mismo heroe, distinto tono.
        const Center(
          child: IconoCirculo(
            Icons.check,
            diametro: 72,
            tono: TonoIcono.exito,
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
        const SizedBox(height: Espacio.md),

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
        // Entre bloques va 24, como en la vista pendiente.
        const SizedBox(height: Espacio.lg),

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
    // Cerrada no es rechazada: nadie dijo que no. El cuarto se alquilo
    // mientras esperaba, y eso es lo que tiene que leer (evidencia 5).
    final cerrada = solicitud.estaCerrada;

    final (icono, tono, titulo, detalle) = rechazada
        ? (
            Icons.cancel_outlined,
            TonoIcono.error,
            'Solicitud rechazada',
            'El propietario rechazó la solicitud. Podés buscar otros anuncios.',
          )
        : cerrada
            ? (
                Icons.home_work_outlined,
                TonoIcono.neutro,
                'El cuarto ya se alquiló',
                'Tu solicitud se cerró sola porque el propietario lo marcó como '
                    'alquilado. Podés buscar otros anuncios.',
              )
            : (
                Icons.hourglass_top_outlined,
                TonoIcono.neutro,
                'Solicitud enviada',
                'El propietario tiene que aceptar tu solicitud antes de recibir su contacto.',
              );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: IconoCirculo(icono, diametro: 72, tono: tono)),
        const SizedBox(height: Espacio.lg),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: AppText.cifra(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.sm),
        Text(
          detalle,
          textAlign: TextAlign.center,
          style: AppText.body(context).copyWith(color: AppColors.text70),
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
