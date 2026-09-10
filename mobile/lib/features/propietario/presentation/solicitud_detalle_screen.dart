import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/encabezado.dart';
import '../../inquilina/data/solicitud.dart';
import '../data/anuncio.dart';
import '../providers/solicitudes_recibidas_provider.dart';

/// Flujo v0.4, pantallas 1, 2 y 3: la propietaria decide una solicitud.
///
/// Es una sola pantalla con tres finales. Arriba siempre va lo mismo —que
/// anuncio, que condiciones acepto esa persona y que pasa si aprueba—; con el
/// estado cambia solo el bloque de la decision. Asi la propietaria nunca pierde
/// de vista a quien le esta liberando el contacto.
class SolicitudDetalleScreen extends StatelessWidget {
  const SolicitudDetalleScreen({super.key, required this.id});

  final int id;

  Future<void> _responder(
    BuildContext context,
    Future<bool> Function(int id) accion,
    String siFalla,
  ) async {
    final ok = await accion(id);
    if (!ok && context.mounted) {
      final error = context.read<SolicitudesRecibidasProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? siFalla)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();
    final solicitud = provider.porId(id);

    if (solicitud == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const Encabezado(titulo: 'Solicitud'),
        body: Center(
          child: Text(
            'Esta solicitud ya no está disponible.',
            style: AppText.body(context).copyWith(color: AppColors.text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: Encabezado(titulo: 'Solicitud #${solicitud.id}'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espacio.lg),
        // CONSTRAINTS: en un monitor el contenido se detiene en 1200 y queda
        // centrado; en el telefono ocupa todo el ancho menos los margenes.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Grilla.anchoMaximo),
            // GRID: lo que se decide ocupa 8 columnas y la decision 4 en
            // escritorio; 6 y 6 en tablet; en movil las dos van a 12, una
            // debajo de la otra, en el mismo orden que el wireframe.
            child: Grilla12(
              celdas: [
                CeldaGrilla(
                  columnas: const Columnas(tablet: 6, escritorio: 8),
                  child: _Contexto(solicitud: solicitud),
                ),
                CeldaGrilla(
                  columnas: const Columnas(tablet: 6, escritorio: 4),
                  child: _Decision(
                    solicitud: solicitud,
                    procesando: provider.procesando(solicitud.id),
                    alAprobar: () => _responder(
                      context,
                      provider.aprobar,
                      'No se pudo aprobar la solicitud.',
                    ),
                    alRechazar: () => _responder(
                      context,
                      provider.rechazar,
                      'No se pudo rechazar la solicitud.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que la propietaria mira antes de decidir: el anuncio y lo que acepto
/// quien pide la visita.
class _Contexto extends StatelessWidget {
  const _Contexto({required this.solicitud});

  final SolicitudVisita solicitud;

  @override
  Widget build(BuildContext context) {
    final anuncio = solicitud.anuncio;
    final tenue = AppColors.text.withValues(alpha: 0.6);
    final precio = _precio(anuncio.precioFinal);

    // AUTO LAYOUT: una columna con separacion 16. Ninguna tarjeta tiene alto
    // fijo: si el titulo del anuncio ocupa dos lineas, la tarjeta crece y lo
    // de abajo baja solo.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Bloque(
          children: [
            Text(
              anuncio.titulo,
              style: AppText.button(context)
                  .copyWith(color: AppColors.text, letterSpacing: 0),
            ),
            const SizedBox(height: Espacio.sm),
            Text(
              'Tipo: ${anuncio.tipoEspacio.etiqueta} · $precio Bs/mes',
              style: AppText.caption(context).copyWith(color: tenue),
            ),
          ],
        ),
        const SizedBox(height: Espacio.md),
        _Bloque(
          children: [
            Text(
              'Condiciones que acepta',
              style: AppText.caption(context).copyWith(color: tenue),
            ),
            const SizedBox(height: Espacio.md),
            _Condicion('Precio: $precio Bs/mes'),
            const SizedBox(height: Espacio.sm),
            _Condicion(_servicios(anuncio)),
            const SizedBox(height: Espacio.sm),
            _Condicion(
              anuncio.aceptaMascotas ? 'Acepta mascotas' : 'Sin mascotas',
            ),
          ],
        ),
      ],
    );
  }
}

/// Una tarjeta con borde suave, del alto de su contenido.
class _Bloque extends StatelessWidget {
  const _Bloque({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Espacio.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Medida.radio),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

/// Una condicion que la persona acepto al pedir la visita.
class _Condicion extends StatelessWidget {
  const _Condicion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    // FLEXBOX: icono fijo y texto flexible, alineados al centro del eje
    // cruzado (align-items: center).
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: Espacio.sm),
        Expanded(
          child: Text(
            texto,
            style: AppText.body(context).copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

/// La decision. Es lo unico de la pantalla que cambia con el estado.
class _Decision extends StatelessWidget {
  const _Decision({
    required this.solicitud,
    required this.procesando,
    required this.alAprobar,
    required this.alRechazar,
  });

  final SolicitudVisita solicitud;
  final bool procesando;
  final VoidCallback alAprobar;
  final VoidCallback alRechazar;

  @override
  Widget build(BuildContext context) {
    final quien = solicitud.inquilino.isEmpty
        ? 'Inquilino interesado'
        : solicitud.inquilino;
    void volver() => Navigator.of(context).pop();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lo que pasa al aprobar se dice ANTES del boton, no despues.
        const Aviso(
          icono: Icons.lock_outline,
          mensaje: 'Esta persona va a ver tu WhatsApp. Sólo ella.',
        ),
        const SizedBox(height: Espacio.md),
        ...switch (solicitud.estado) {
          EstadoSolicitud.pendiente => [
              BotonPrincipal(
                etiqueta: 'Aprobar y liberar mi WhatsApp',
                etiquetaCargando: 'Enviando...',
                cargando: procesando,
                alTocar: procesando ? null : alAprobar,
              ),
              const SizedBox(height: Espacio.sm),
              BotonSecundario(
                etiqueta: 'Rechazar',
                destructiva: true,
                alTocar: procesando ? null : alRechazar,
              ),
            ],
          EstadoSolicitud.aprobada => [
              _Resultado(
                tipo: TipoAviso.exito,
                titulo: 'Contacto liberado a $quien',
                detalle: 'Ahora puede escribirte por WhatsApp.',
              ),
              const SizedBox(height: Espacio.sm),
              BotonSecundario(etiqueta: 'Volver a la bandeja', alTocar: volver),
            ],
          EstadoSolicitud.rechazada => [
              const _Resultado(
                tipo: TipoAviso.error,
                titulo: 'Solicitud rechazada y cerrada',
                detalle: 'No se abrirá conversación por WhatsApp. '
                    'El inquilino fue notificado.',
              ),
              const SizedBox(height: Espacio.sm),
              BotonSecundario(etiqueta: 'Volver a la bandeja', alTocar: volver),
            ],
        },
      ],
    );
  }
}

/// El resultado de una decision ya tomada: que paso y que significa.
///
/// No es el Aviso de una linea: trae titulo y detalle. AUTO LAYOUT: no tiene
/// alto fijo y crece con el texto.
class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.tipo,
    required this.titulo,
    required this.detalle,
  });

  final TipoAviso tipo;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final color = tipo == TipoAviso.exito ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(Espacio.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Medida.radio),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tipo == TipoAviso.exito
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: 24,
            color: color,
          ),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppText.button(context)
                      .copyWith(color: color, letterSpacing: 0),
                ),
                const SizedBox(height: Espacio.xs),
                Text(
                  detalle,
                  style: AppText.caption(context).copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "650.00" se lee "650"; "1000" se lee "1.000".
String _precio(String valor) {
  final entero = (double.tryParse(valor) ?? 0).round();
  return entero
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

/// Que cubre el precio, dicho como lo diria una persona.
String _servicios(Anuncio anuncio) {
  final s = anuncio.serviciosIncluidos;
  final incluidos = [
    if (s['agua'] == true) 'agua',
    if (s['luz'] == true) 'luz',
    if (s['internet'] == true) 'internet',
  ];
  if (incluidos.isEmpty) return 'Servicios aparte';
  if (incluidos.length == 1) return 'Incluye ${incluidos.first}';
  final ultimo = incluidos.last;
  // "agua y luz", pero "luz e internet": la y pasa a e delante de i.
  final y = ultimo.startsWith('i') ? 'e' : 'y';
  final resto = incluidos.sublist(0, incluidos.length - 1).join(', ');
  return 'Incluye $resto $y $ultimo';
}
