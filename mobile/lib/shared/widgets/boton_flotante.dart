import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// La accion que queda flotando sobre una lista, como "Publicar" en Mis
/// anuncios.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Una por pantalla y solo sobre listas, donde la accion no tiene un pie fijo.
/// Lleva icono y palabra: un icono solo obliga a adivinar.
class BotonFlotante extends StatelessWidget {
  const BotonFlotante({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.alTocar,
  });

  final String etiqueta;
  final IconData icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: alTocar,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      icon: Icon(icono),
      label: Text(
        etiqueta,
        style: AppText.button(context).copyWith(color: AppColors.surface),
      ),
    );
  }
}
