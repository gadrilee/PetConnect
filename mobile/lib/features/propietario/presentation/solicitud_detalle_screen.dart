import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../../../shared/widgets/resumen_anuncio.dart';
import '../../inquilina/data/solicitud.dart';
import '../data/anuncio.dart';
import '../providers/solicitudes_recibidas_provider.dart';

/// Flujo v0.4, pantallas 1, 2 y 3: la propietaria decide una solicitud.
///
/// Es una sola pantalla con tres finales. Arriba siempre va lo mismo —que
/// anuncio, que condiciones acepto esa persona y que pasa si aprueba—; con el
/// estado cambia solo el pie: los botones de la decision, o el resultado y la
/// salida. Asi la propietaria nunca pierde de vista a quien le esta liberando
/// el contacto.
class SolicitudDetalleScreen extends StatelessWidget {
  const SolicitudDetalleScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SolicitudesRecibidasProvider>();
    final solicitud = provider.porId(id);

    if (solicitud == null) {
      return Pagina(
        titulo: 'Solicitud #$id',
        cuerpo: EstadoVacio(
          icono: Icons.search_off,
          titulo: 'Esta solicitud ya no está disponible.',
          detalle: 'Ya no aparece en tu bandeja.',
          accion: 'Volver a la bandeja',
          alAccion: () => Navigator.of(context).pop(),
        ),
      );
    }

    // CONSTRAINTS: la Pagina detiene el contenido en 1200 y lo centra; en el
    // telefono ocupa todo el ancho menos los margenes.
    return Pagina(
      titulo: 'Solicitud #${solicitud.id}',
      pie: _pie(context, provider, solicitud),
      hijos: [
        // GRID: lo que se decide ocupa 8 columnas y lo que pasa al aprobar 4
        // en escritorio; 6 y 6 en tablet; en movil las dos van a 12, una
        // debajo de la otra, en el mismo orden que el wireframe.
        Grilla12(
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 6, escritorio: 8),
              child: _Contexto(solicitud: solicitud),
            ),
            // Lo que pasa al aprobar se dice ANTES del boton, no despues. Una
            // rechazada o cerrada ya no va a ver nada: ahi la nota mentiria.
            if (solicitud.estaPendiente || solicitud.estaAprobada)
              const CeldaGrilla(
                columnas: Columnas(tablet: 6, escritorio: 4),
                child: Aviso(
                  icono: Icons.lock_outline,
                  mensaje: 'Esta persona va a ver tu WhatsApp. Sólo ella.',
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// El pie es lo unico de la pantalla que cambia con el estado: la decision
  /// mientras esta pendiente; despues, el resultado y la vuelta a la bandeja.
  /// Si aprobar o rechazar falla, el error va en el aviso del pie, no en un
  /// toast. Solo el de esta solicitud: que la bandeja no se haya podido
  /// refrescar no es el resultado de una decision que nadie tomo.
  PieAcciones _pie(
    BuildContext context,
    SolicitudesRecibidasProvider provider,
    SolicitudVisita solicitud,
  ) {
    final procesando = provider.procesando(solicitud.id);
    final errorDecision = provider.errorDecision(solicitud.id);
    final quien = solicitud.inquilino.isEmpty
        ? 'Inquilino interesado'
        : solicitud.inquilino;
    void volver() => Navigator.of(context).pop();

    return switch (solicitud.estado) {
      EstadoSolicitud.pendiente => PieAcciones(
          aviso: errorDecision == null
              ? null
              : Aviso(mensaje: errorDecision, tipo: TipoAviso.error),
          botonPrincipal: BotonPrincipal(
            etiqueta: 'Aprobar y liberar mi WhatsApp',
            etiquetaCargando: 'Enviando...',
            cargando: procesando,
            alTocar: procesando ? null : () => provider.aprobar(solicitud.id),
          ),
          botonSecundarioAbajo: BotonSecundario(
            etiqueta: 'Rechazar',
            destructiva: true,
            alTocar: procesando ? null : () => provider.rechazar(solicitud.id),
          ),
        ),
      // El resultado de una decision ya tomada: que paso y que significa.
      EstadoSolicitud.aprobada => PieAcciones(
          aviso: Aviso(
            tipo: TipoAviso.exito,
            titulo: 'Contacto liberado a $quien',
            mensaje: 'Ahora puede escribirte por WhatsApp.',
          ),
          botonSecundarioAbajo:
              BotonSecundario(etiqueta: 'Volver a la bandeja', alTocar: volver),
        ),
      EstadoSolicitud.rechazada => PieAcciones(
          aviso: const Aviso(
            tipo: TipoAviso.error,
            titulo: 'Solicitud rechazada y cerrada',
            mensaje: 'No se abrirá conversación por WhatsApp. '
                'El inquilino fue notificado.',
          ),
          botonSecundarioAbajo:
              BotonSecundario(etiqueta: 'Volver a la bandeja', alTocar: volver),
        ),
      // Se cerro sola al marcar el cuarto como alquilado (flujo v0.5).
      EstadoSolicitud.cerrada => PieAcciones(
          aviso: const Aviso(
            titulo: 'Solicitud cerrada',
            mensaje: 'Marcaste el cuarto como alquilado, así que se cerró sola '
                'y se le avisó a esta persona.',
          ),
          botonSecundarioAbajo:
              BotonSecundario(etiqueta: 'Volver a la bandeja', alTocar: volver),
        ),
    };
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
    final tenue = AppText.caption(context).copyWith(color: AppColors.text60);
    final precio = PrecioFinal.formatear(anuncio.precioFinal);

    Widget condicion(String texto) => FilaCondicion(
          icono: Icons.check_circle_outline,
          tamanoIcono: 20,
          colorIcono: AppColors.primary,
          texto: texto,
          estilo: AppText.body(context).copyWith(color: AppColors.text),
        );

    // AUTO LAYOUT: una columna con 24 entre bloques. Ningun bloque tiene alto
    // fijo: si el titulo del anuncio ocupa dos lineas, el bloque crece y lo de
    // abajo baja solo.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La misma pieza que usa Marcar como alquilado. Antes era este bloque
        // escrito a mano, sin la foto: para decidir una visita conviene ver
        // cuál de los cuartos es, no sólo leer un título que se parece a los
        // otros tres.
        ResumenAnuncio(anuncio: anuncio),
        const SizedBox(height: Espacio.lg),
        Bloque(
          hijos: [
            Text('Condiciones que acepta', style: tenue),
            const SizedBox(height: Espacio.md),
            condicion('Precio: $precio Bs/mes'),
            const SizedBox(height: Espacio.sm),
            condicion(_servicios(anuncio)),
            const SizedBox(height: Espacio.sm),
            condicion(
              anuncio.aceptaMascotas ? 'Acepta mascotas' : 'Sin mascotas',
            ),
          ],
        ),
      ],
    );
  }
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
