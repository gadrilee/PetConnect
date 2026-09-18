import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'bloque.dart';
import 'fila_condicion.dart';
import 'icono_circulo.dart';

/// Quien entro a la app: el encabezado del inicio de los dos roles.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Nombre y rol, siempre en el mismo lugar. Estaba copiada en el inicio de la
/// propietaria y en el de la inquilina; ahora es una sola.
///
/// Es la puerta a Mi perfil: toda la tarjeta se toca y termina en un chevron,
/// como las tarjetas de modulo. Cerrar sesion no va aca sino adentro de Mi
/// perfil, para que una salida que no se deshace no quede a un toque en la
/// pantalla que se ve al entrar. Mismo cambio que el componente de Figma.
///
/// El rol y la nota del WhatsApp van en Text 70 %, el gris que se lee.
class TarjetaPerfil extends StatelessWidget {
  const TarjetaPerfil({
    super.key,
    required this.nombre,
    required this.rol,
    required this.icono,
    required this.alTocar,
    this.whatsappOculto = false,
  });

  final String nombre;
  final String rol;
  final IconData icono;

  /// Abre Mi perfil.
  final VoidCallback alTocar;

  /// Recuerda que el WhatsApp no aparece en los anuncios. Sólo la propietaria
  /// tiene uno que proteger.
  final bool whatsappOculto;

  /// Lo que el lector de pantalla suma al nombre y el rol: a donde lleva.
  static const String etiquetaIr = 'Mi perfil';

  @override
  Widget build(BuildContext context) {
    final tenue = AppColors.text70;

    return Bloque(
      relleno: Espacio.lg,
      alTocar: alTocar,
      // FLEXBOX: avatar fijo, datos flexibles y el chevron anclado a la derecha.
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
          const SizedBox(width: Espacio.sm),
          // Mismo gris que el chevron de las tarjetas de modulo: es una
          // entrada, no una accion destructiva.
          Icon(
            Icons.chevron_right,
            color: AppColors.text60,
            semanticLabel: etiquetaIr,
          ),
        ],
      ),
    );
  }
}
