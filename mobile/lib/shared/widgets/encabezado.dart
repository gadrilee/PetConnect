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
class Encabezado extends StatelessWidget implements PreferredSizeWidget {
  const Encabezado({
    super.key,
    required this.titulo,
    this.conBotonVolver = true,
  });

  final String titulo;

  /// `false` solo en Inicio: es la raiz de la app y no hay a donde volver.
  final bool conBotonVolver;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        titulo,
        style: AppText.heading(context).copyWith(color: AppColors.text),
      ),
      automaticallyImplyLeading: conBotonVolver,
      iconTheme: const IconThemeData(color: AppColors.text),
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: conBotonVolver ? 0 : Espacio.md,
    );
  }
}
