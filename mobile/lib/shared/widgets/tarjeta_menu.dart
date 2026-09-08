import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TarjetaMenu extends StatelessWidget {
  const TarjetaMenu({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.icono,
    this.alTocar,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final enabled = alTocar != null;
    final colorIcono = enabled ? AppColors.primary : AppColors.text.withValues(alpha: 0.38);
    final colorTitulo = enabled ? AppColors.text : AppColors.text.withValues(alpha: 0.38);

    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(Medida.radio),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Medida.radio),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: enabled ? AppColors.primary.withValues(alpha: 0.1) : AppColors.text.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: colorIcono, size: 24),
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: AppText.button(context).copyWith(color: colorTitulo),
                  ),
                  const SizedBox(height: Espacio.xs),
                  Text(
                    detalle,
                    style: AppText.caption(context).copyWith(
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: Espacio.md),
              Icon(Icons.chevron_right, color: AppColors.text.withValues(alpha: 0.4)),
            ] else ...[
              const SizedBox(width: Espacio.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Espacio.sm, vertical: Espacio.xs),
                decoration: BoxDecoration(
                  color: AppColors.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Medida.radioSm),
                ),
                child: Text('Pendiente', style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.5))),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
