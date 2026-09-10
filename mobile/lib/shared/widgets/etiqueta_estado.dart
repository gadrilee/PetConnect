import 'package:flutter/material.dart';

import '../../features/inquilina/data/solicitud.dart';
import '../../features/propietario/data/anuncio.dart';
import 'pastilla.dart';

/// Los estados que se muestran con etiqueta.
enum TipoEstado { pendiente, aprobada, rechazada, disponible, alquilado }

/// El estado de una solicitud o de un anuncio, dicho con color y palabra.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El mismo estado se ve igual en todas las pantallas: la aprobada siempre
/// verde, la rechazada siempre roja. Antes habia tres versiones distintas, una
/// por pantalla. Es una [Pastilla], asi que el ancho lo pone la palabra.
class EtiquetaEstado extends StatelessWidget {
  const EtiquetaEstado({super.key, required this.estado});

  /// Atajo para una solicitud de visita.
  EtiquetaEstado.solicitud(EstadoSolicitud estado, {super.key})
      : estado = switch (estado) {
          EstadoSolicitud.pendiente => TipoEstado.pendiente,
          EstadoSolicitud.aprobada => TipoEstado.aprobada,
          EstadoSolicitud.rechazada => TipoEstado.rechazada,
        };

  /// Atajo para un anuncio.
  const EtiquetaEstado.anuncio(EstadoAnuncio estado, {super.key})
      : estado = estado == EstadoAnuncio.disponible
            ? TipoEstado.disponible
            : TipoEstado.alquilado;

  final TipoEstado estado;

  @override
  Widget build(BuildContext context) {
    final (texto, tono) = switch (estado) {
      TipoEstado.pendiente => ('Pendiente', TonoPastilla.neutro),
      TipoEstado.aprobada => ('Aprobada', TonoPastilla.exito),
      TipoEstado.rechazada => ('Rechazada', TonoPastilla.error),
      TipoEstado.disponible => ('Disponible', TonoPastilla.primario),
      TipoEstado.alquilado => ('Ya alquilado', TonoPastilla.neutro),
    };
    return Pastilla(texto, tono: tono);
  }
}
