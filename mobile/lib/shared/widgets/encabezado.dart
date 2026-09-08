import 'package:flutter/material.dart';
import '../../core/theme.dart';

class Encabezado extends StatelessWidget implements PreferredSizeWidget {
  const Encabezado({
    super.key,
    required this.titulo,
    this.conBotonVolver = true,
  });

  final String titulo;
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
