import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/inquilina/data/solicitud.dart';
import 'bloque.dart';
import 'boton_principal.dart';
import 'boton_secundario.dart';
import 'etiqueta_estado.dart';
import 'fila_condicion.dart';

/// Una solicitud recibida en la bandeja de la propietaria. En Figma es la
/// pieza "Tarjeta Solicitud", con los estados Activo, Rechazada y Aprobada.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El estado se reconoce antes de leer. La pendiente no lleva etiqueta pero
/// trae las dos acciones; la aprobada y la rechazada no tienen acciones y
/// llevan borde y etiqueta de su color. **Una solicitud ya respondida no se
/// vuelve a responder desde la tarjeta.**
///
/// Esta armada solo con piezas compartidas: Bloque, FilaCondicion,
/// EtiquetaEstado y los dos botones. Si cambia el boton, cambia aca tambien.
class TarjetaSolicitud extends StatelessWidget {
  const TarjetaSolicitud({
    super.key,
    required this.numero,
    required this.tituloAnuncio,
    required this.inquilino,
    required this.fecha,
    required this.estado,
    this.alTocar,
    this.alAprobar,
    this.alRechazar,
  });

  final int numero;
  final String tituloAnuncio;

  /// Quien pidio la visita. Vacio se muestra como "Inquilino interesado".
  final String inquilino;

  final DateTime fecha;
  final EstadoSolicitud estado;

  /// Abrir el detalle de la solicitud.
  final VoidCallback? alTocar;

  /// Quien usa la tarjeta decide que hace Aprobar. En la bandeja abre el
  /// detalle: antes de liberar el WhatsApp hay que ver a quien y con que
  /// condiciones.
  final VoidCallback? alAprobar;

  /// `null` deshabilita la accion, por ejemplo mientras se esta enviando.
  final VoidCallback? alRechazar;

  @override
  Widget build(BuildContext context) {
    final tenue = AppColors.text.withValues(alpha: 0.6);
    final gris = AppColors.text.withValues(alpha: 0.5);
    final pendiente = estado == EstadoSolicitud.pendiente;

    return Bloque(
      alTocar: alTocar,
      colorBorde: switch (estado) {
        EstadoSolicitud.aprobada => AppColors.success,
        EstadoSolicitud.rechazada => AppColors.error,
        EstadoSolicitud.pendiente => null,
      },
      // AUTO LAYOUT: sin alto fijo. La pendiente es mas alta porque trae las
      // acciones.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FLEXBOX: el numero toma el espacio libre (flex: 1) y empuja la
          // etiqueta contra el borde derecho, el efecto de space-between.
          Row(
            children: [
              // CONSTRAINTS: si no entran los dos, cede el numero y se corta.
              // La etiqueta no se achica nunca: dice en que quedo.
              Expanded(
                child: Text(
                  'Solicitud #$numero',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(context).copyWith(color: tenue),
                ),
              ),
              if (!pendiente) ...[
                const SizedBox(width: Espacio.sm),
                EtiquetaEstado.solicitud(estado),
              ],
            ],
          ),
          const SizedBox(height: Espacio.md),
          FilaCondicion(
            icono: Icons.home_outlined,
            colorIcono: AppColors.primary,
            tamanoIcono: 24,
            maxLineas: 1,
            texto: tituloAnuncio,
            estilo: AppText.button(context)
                .copyWith(color: AppColors.text, letterSpacing: 0),
          ),
          const SizedBox(height: Espacio.sm),
          FilaCondicion(
            icono: Icons.person_outline,
            colorIcono: gris,
            tamanoIcono: 24,
            maxLineas: 1,
            texto: inquilino.isEmpty ? 'Inquilino interesado' : inquilino,
            estilo: AppText.body(context).copyWith(color: AppColors.text),
          ),
          const SizedBox(height: Espacio.sm),
          FilaCondicion(
            icono: Icons.calendar_today_outlined,
            colorIcono: gris,
            tamanoIcono: 24,
            maxLineas: 1,
            texto: '${fecha.day}/${fecha.month}/${fecha.year}',
            estilo: AppText.caption(context).copyWith(color: tenue),
          ),
          if (pendiente) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Espacio.md),
              child: Divider(height: 1),
            ),
            // FLEXBOX: las dos acciones reparten el ancho por partes iguales,
            // como dos hijos con flex: 1.
            Row(
              children: [
                Expanded(
                  child: BotonSecundario(
                    etiqueta: 'Rechazar',
                    destructiva: true,
                    compacto: true,
                    alTocar: alRechazar,
                  ),
                ),
                const SizedBox(width: Espacio.md),
                Expanded(
                  child: BotonPrincipal(
                    etiqueta: 'Aprobar',
                    compacto: true,
                    alTocar: alAprobar,
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
