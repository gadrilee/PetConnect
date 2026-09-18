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
///
/// El rol y la nota del WhatsApp van en Text 70 %, el gris que se lee; la
/// salida es un icono solo, asi que lleva su nombre ("Cerrar sesión") para el
/// lector de pantalla y un blanco de 48, aunque el icono mida 24.
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

  /// Lo que se anuncia al tocar la salida, para no repetirlo en las pruebas.
  static const String etiquetaSalir = 'Cerrar sesión';

  @override
  Widget build(BuildContext context) {
    final tenue = AppColors.text70;

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
            // El tooltip es el nombre del boton para el lector de pantalla y
            // lo que se ve al dejar el mouse encima.
            tooltip: etiquetaSalir,
            constraints: const BoxConstraints(
              minWidth: Medida.toque,
              minHeight: Medida.toque,
            ),
          ),
        ],
      ),
    );
  }
}
