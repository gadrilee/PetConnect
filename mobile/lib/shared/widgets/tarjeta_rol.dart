import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TarjetaRol extends StatelessWidget {
  const TarjetaRol({
    super.key,
    required this.etiqueta,
    required this.descripcion,
    required this.icono,
    required this.seleccionada,
    required this.alTocar,
  });

  final String etiqueta;
  final String descripcion;
  final IconData icono;
  final bool seleccionada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final colorBorde = seleccionada ? AppColors.primary : AppColors.text.withValues(alpha: 0.1);
    final colorFondo = seleccionada ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface;

    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(Medida.radio),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(Medida.radio),
          border: Border.all(color: colorBorde, width: seleccionada ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icono, color: seleccionada ? AppColors.primary : AppColors.text.withValues(alpha: 0.7), size: 32),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: AppText.button(context).copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
