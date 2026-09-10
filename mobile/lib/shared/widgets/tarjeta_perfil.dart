import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'bloque.dart';
import 'fila_condicion.dart';
import 'icono_circulo.dart';

/// Quien entro a la app: el encabezado del inicio de los dos roles.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Nombre, rol y la salida, siempre en el mismo lugar. Estaba copiada en el
/// inicio de la propietaria y en el de la inquilina; ahora es una sola.
class TarjetaPerfil extends StatelessWidget {
  const TarjetaPerfil({
    super.key,
    required this.nombre,
    required this.rol,
    required this.icono,
    required this.alCerrarSesion,
    this.whatsappOculto = false,
  });

  final String nombre;
  final String rol;
  final IconData icono;
  final VoidCallback alCerrarSesion;

  /// Recuerda que el WhatsApp no aparece en los anuncios. Sólo la propietaria
  /// tiene uno que proteger.
  final bool whatsappOculto;

  @override
  Widget build(BuildContext context) {
    final tenue = AppColors.text.withValues(alpha: 0.6);

    return Bloque(
      relleno: Espacio.lg,
      // FLEXBOX: avatar fijo, datos flexibles y la salida anclada a la derecha.
      child: Row(
        children: [
          IconoCirculo(icono),
          const SizedBox(width: Espacio.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.titulo(context).copyWith(color: AppColors.text),
                ),
                Text(
                  rol,
                  style: AppText.caption(context).copyWith(color: tenue),
                ),
                if (whatsappOculto) ...[
                  const SizedBox(height: Espacio.xs),
                  FilaCondicion(
                    icono: Icons.lock_outline,
                    texto: 'Tu WhatsApp está oculto',
                    estilo: AppText.caption(context).copyWith(color: tenue),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: alCerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }
}
