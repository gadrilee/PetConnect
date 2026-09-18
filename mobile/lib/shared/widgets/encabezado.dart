import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// La barra de arriba de cada pantalla, con el titulo y la flecha de volver.
/// En Figma es la pieza "Encabezado".
///
/// REGLA DE LA PIEZA
/// -----------------
/// Mide 56, fondo blanco y sin sombra. El titulo va en sentence case
/// ("Gestionar solicitudes", no "Gestionar Solicitudes") y las pantallas de
/// detalle se titulan "Solicitud #N". **La flecha de volver aparece en todas
/// las pantallas salvo en Inicio (titulo "AlquilaMatch") y en el login**, que
/// no tiene encabezado.
///
/// La flecha es un icono solo, asi que se anuncia con su nombre, "Volver",
/// y mide 48 de blanco, como todo lo que se toca.
class Encabezado extends StatelessWidget implements PreferredSizeWidget {
  const Encabezado({
    super.key,
    required this.titulo,
    this.conBotonVolver = true,
  });

  final String titulo;

  /// `false` solo en Inicio: es la raiz de la app y no hay a donde volver.
  final bool conBotonVolver;

  /// Lo que se anuncia al tocar la flecha, para no repetirlo en las pruebas.
  static const String etiquetaVolver = 'Volver';

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    // La misma regla que AppBar para decidir si hay flecha: solo cuando hay
    // una pantalla a la que volver. La diferencia es el nombre, que aca es
    // "Volver" en vez del que trae Material.
    final puedeVolver =
        conBotonVolver && (ModalRoute.of(context)?.canPop ?? false);

    return AppBar(
      title: Text(
        titulo,
        style: AppText.heading(context).copyWith(color: AppColors.text),
      ),
      automaticallyImplyLeading: false,
      leading: puedeVolver
          ? IconButton(
              icon: const BackButtonIcon(),
              tooltip: etiquetaVolver,
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      iconTheme: const IconThemeData(color: AppColors.text),
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: puedeVolver ? 0 : Espacio.md,
    );
  }
}
