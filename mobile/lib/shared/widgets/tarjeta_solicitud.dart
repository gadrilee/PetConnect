import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/inquilina/data/solicitud.dart';

/// Una solicitud recibida en la bandeja de la propietaria. En Figma es la
/// pieza "Tarjeta Solicitud", con los estados Activo, Rechazada y Aprobada.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El estado se reconoce antes de leer. La pendiente no lleva etiqueta pero
/// trae las dos acciones; la aprobada y la rechazada no tienen acciones y
/// llevan borde y etiqueta de su color. **Una solicitud ya respondida no se
/// vuelve a responder desde la tarjeta.**
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
    final borde = switch (estado) {
      EstadoSolicitud.aprobada => AppColors.success,
      EstadoSolicitud.rechazada => AppColors.error,
      EstadoSolicitud.pendiente => AppColors.text.withValues(alpha: 0.1),
    };
    final tenue = AppColors.text.withValues(alpha: 0.6);
    final gris = AppColors.text.withValues(alpha: 0.5);

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medida.radio),
        side: BorderSide(color: borde),
      ),
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          // AUTO LAYOUT: relleno 16 y separacion fija entre filas, sin alto
          // fijo. La tarjeta mide lo que su contenido: la pendiente es mas
          // alta porque trae las acciones.
          padding: const EdgeInsets.all(Espacio.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FLEXBOX: el numero toma el espacio libre (flex: 1) y empuja la
              // etiqueta contra el borde derecho, el efecto de space-between.
              Row(
                children: [
                  // CONSTRAINTS: si no entran los dos, cede el numero y se
                  // corta. La etiqueta no se achica nunca: es lo que dice en
                  // que quedo la solicitud.
                  Expanded(
                    child: Text(
                      'Solicitud #$numero',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(context).copyWith(color: tenue),
                    ),
                  ),
                  if (estado != EstadoSolicitud.pendiente) ...[
                    const SizedBox(width: Espacio.sm),
                    _Etiqueta(estado: estado),
                  ],
                ],
              ),
              const SizedBox(height: Espacio.md),
              _Fila(
                icono: Icons.home_outlined,
                colorIcono: AppColors.primary,
                texto: tituloAnuncio,
                estilo: AppText.button(context)
                    .copyWith(color: AppColors.text, letterSpacing: 0),
              ),
              const SizedBox(height: Espacio.sm),
              _Fila(
                icono: Icons.person_outline,
                colorIcono: gris,
                texto: inquilino.isEmpty ? 'Inquilino interesado' : inquilino,
                estilo: AppText.body(context).copyWith(color: AppColors.text),
              ),
              const SizedBox(height: Espacio.sm),
              _Fila(
                icono: Icons.calendar_today_outlined,
                colorIcono: gris,
                texto: '${fecha.day}/${fecha.month}/${fecha.year}',
                estilo: AppText.caption(context).copyWith(color: tenue),
              ),
              if (estado == EstadoSolicitud.pendiente) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Espacio.md),
                  child: Divider(height: 1),
                ),
                // FLEXBOX: las dos acciones reparten el ancho por partes
                // iguales, como dos hijos con flex: 1.
                Row(
                  children: [
                    Expanded(
                      child: _Accion(
                        etiqueta: 'Rechazar',
                        alTocar: alRechazar,
                        destructiva: true,
                      ),
                    ),
                    const SizedBox(width: Espacio.md),
                    Expanded(
                      child: _Accion(etiqueta: 'Aprobar', alTocar: alAprobar),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Un dato de la tarjeta: icono y texto.
class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.colorIcono,
    required this.texto,
    required this.estilo,
  });

  final IconData icono;
  final Color colorIcono;
  final String texto;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 24, color: colorIcono),
        const SizedBox(width: Espacio.sm),
        // CONSTRAINTS: el texto toma el ancho que sobra y, si no entra, se
        // corta con puntos suspensivos. Un titulo largo no agranda la tarjeta.
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo,
          ),
        ),
      ],
    );
  }
}

/// La etiqueta de una solicitud ya respondida.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.estado});

  final EstadoSolicitud estado;

  @override
  Widget build(BuildContext context) {
    final color =
        estado == EstadoSolicitud.aprobada ? AppColors.success : AppColors.error;

    // AUTO LAYOUT: el ancho lo pone la palabra, no un numero fijo.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.md,
        vertical: Espacio.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Medida.radio * 2),
      ),
      child: Text(
        estado.etiqueta,
        style: AppText.caption(context).copyWith(color: color),
      ),
    );
  }
}

/// Una de las dos acciones de la tarjeta pendiente.
class _Accion extends StatelessWidget {
  const _Accion({
    required this.etiqueta,
    required this.alTocar,
    this.destructiva = false,
  });

  final String etiqueta;
  final VoidCallback? alTocar;
  final bool destructiva;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medida.radioSm),
    );
    const alto = Size.fromHeight(48);

    if (destructiva) {
      return OutlinedButton(
        onPressed: alTocar,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
          minimumSize: alto,
          shape: forma,
        ),
        child: Text(etiqueta),
      );
    }
    return FilledButton(
      onPressed: alTocar,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        minimumSize: alto,
        shape: forma,
      ),
      child: Text(etiqueta),
    );
  }
}
