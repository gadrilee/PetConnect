import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'icono_circulo.dart';

/// La foto de quien entro a la app o, si no tiene, el icono de su rol.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Es siempre un circulo del mismo tamano, con foto o sin ella: la tarjeta y
/// Mi perfil no saltan cuando la foto llega, se va o no carga.
///
/// - Sin foto, o si la foto no carga: el IconoCirculo primario con el icono
///   del rol, como era antes de que existiera la foto.
/// - Con foto: la imagen recortada al circulo.
/// - Subiendo: la foto elegida con un velo y el indicador. Es la que va a
///   quedar, y todavia no quedo.
///
/// Mismo componente que "Avatar" en Figma (Sin foto | Con foto | Subiendo, en
/// 48 para la Tarjeta de perfil y 96 para Mi perfil).
class AvatarPerfil extends StatelessWidget {
  const AvatarPerfil({
    super.key,
    required this.icono,
    this.foto,
    this.bytesLocales,
    this.subiendo = false,
    this.diametro = 48,
    this.alTocar,
  });

  /// El icono del rol, para cuando no hay foto.
  final IconData icono;

  /// La direccion de la foto guardada. `null` o vacia es "sin foto".
  final String? foto;

  /// La foto recien elegida, todavia en el telefono. Se muestra en lugar de
  /// [foto] mientras sube y apenas termina, para no esperar a descargarla.
  final Uint8List? bytesLocales;

  /// Pone el velo y el indicador sobre la foto.
  final bool subiendo;

  final double diametro;

  /// Tocar la foto hace lo mismo que el boton que la acompana. No se anuncia
  /// aparte al lector de pantalla: ese boton ya es la accion.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final sinFoto = IconoCirculo(icono, diametro: diametro);
    final imagen = _imagen(sinFoto);

    Widget avatar = imagen == null
        ? sinFoto
        : SizedBox.square(
            dimension: diametro,
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imagen,
                  if (subiendo) ...[
                    ColoredBox(color: AppColors.text50),
                    Center(
                      child: SizedBox.square(
                        dimension: diametro / 3,
                        child: CircularProgressIndicator(
                          strokeWidth: diametro >= 96 ? 3 : 2,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );

    if (alTocar != null) {
      avatar = ExcludeSemantics(
        child: GestureDetector(onTap: alTocar, child: avatar),
      );
    }
    return avatar;
  }

  Widget? _imagen(Widget sinFoto) {
    final local = bytesLocales;
    if (local != null) {
      // Los bytes de la foto recien elegida, que se ven mientras sube. Antes
      // era Image.file, que necesita dart:io y en la web no existe.
      return Image.memory(
        local,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => sinFoto,
      );
    }

    final direccion = foto;
    if (direccion == null || direccion.isEmpty) return null;
    return Image.network(
      direccion,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => sinFoto,
      // Mientras baja, un circulo gris: no el icono del rol, que haria creer
      // por un instante que la foto se perdio.
      frameBuilder: (_, hijo, cuadro, alInstante) => alInstante || cuadro != null
          ? hijo
          : ColoredBox(color: AppColors.text10),
    );
  }
}
