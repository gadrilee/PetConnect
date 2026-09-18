import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/inquilina/data/solicitud.dart';
import 'bloque.dart';
import 'etiqueta_estado.dart';
import 'fila_condicion.dart';
import 'foto_inmueble.dart';

/// Una solicitud que mando la inquilina, en Estado de solicitudes.
///
/// REGLA DE LA PIEZA
/// -----------------
/// La foto del anuncio, su titulo, cuando la envio y en que quedo, siempre en
/// ese orden: la etiqueta es lo que ella viene a mirar, asi que va sola en su
/// linea. Toda la tarjeta abre el detalle y termina en un chevron, como las
/// tarjetas de modulo. Mismo componente que "Tarjeta de historial" en Figma.
class TarjetaHistorial extends StatelessWidget {
  const TarjetaHistorial({
    super.key,
    required this.tituloAnuncio,
    required this.enviada,
    required this.estado,
    this.foto,
    this.alTocar,
  });

  final String tituloAnuncio;

  /// Cuando la mando.
  final DateTime enviada;

  final EstadoSolicitud estado;

  /// La primera foto del anuncio; `null` muestra el marcador.
  final String? foto;

  /// Abre el estado de la solicitud.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return Bloque(
      alTocar: alTocar,
      // FLEXBOX: la foto y la flecha miden lo suyo; los datos toman el resto.
      child: Row(
        children: [
          FotoInmueble(url: foto, ancho: 64, alto: 64),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloAnuncio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button(context).copyWith(color: AppColors.text),
                ),
                const SizedBox(height: Espacio.xs),
                FilaCondicion(
                  icono: Icons.calendar_today_outlined,
                  maxLineas: 1,
                  texto: 'Enviada: ${enviada.day}/${enviada.month}',
                  colorIcono: AppColors.text70,
                  estilo: AppText.caption(context).copyWith(color: AppColors.text70),
                ),
                const SizedBox(height: Espacio.sm),
                EtiquetaEstado.solicitud(estado),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.text50),
        ],
      ),
    );
  }
}
