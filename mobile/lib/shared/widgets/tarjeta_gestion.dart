import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'etiqueta_estado.dart';

class TarjetaGestion extends StatelessWidget {
  const TarjetaGestion({
    super.key,
    required this.id,
    required this.estado,
    required this.tituloAnuncio,
    required this.interesado,
    required this.fecha,
    required this.estaPendiente,
    required this.alAprobar,
    required this.alRechazar,
  });

  final String id;
  final TipoEstado estado; // Pendiente, Aprobada, Rechazada
  final String tituloAnuncio;
  final String interesado;
  final String fecha;
  final bool estaPendiente;
  final VoidCallback alAprobar;
  final VoidCallback alRechazar;

  @override
  Widget build(BuildContext context) {
    final colorBorde = switch (estado) {
      TipoEstado.aprobada => AppColors.success,
      TipoEstado.rechazada => AppColors.error,
      TipoEstado.pendiente => AppColors.text.withValues(alpha: 0.1),
    };

    return Container(
      padding: const EdgeInsets.all(Espacio.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Medida.radio),
        border: Border.all(color: colorBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: ID y Estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solicitud #$id',
                style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.6)),
              ),
              EtiquetaEstado(estado: estado),
            ],
          ),
          const SizedBox(height: Espacio.md),

          // Anuncio
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 24, color: AppColors.primary),
              const SizedBox(width: Espacio.sm),
              Expanded(
                child: Text(
                  tituloAnuncio,
                  style: AppText.button(context).copyWith(color: AppColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espacio.sm),
          
          // Inquilino
          Row(
            children: [
              Icon(Icons.person_outline, size: 24, color: AppColors.text.withValues(alpha: 0.5)),
              const SizedBox(width: Espacio.sm),
              Text(
                interesado,
                style: AppText.body(context).copyWith(color: AppColors.text),
              ),
            ],
          ),

          // Fecha
          const SizedBox(height: Espacio.sm),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 24, color: AppColors.text.withValues(alpha: 0.5)),
              const SizedBox(width: Espacio.sm),
              Text(
                fecha,
                style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.6)),
              ),
            ],
          ),

          // Botones (Solo si está pendiente)
          if (estaPendiente) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Espacio.md),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: alRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Medida.radioSm)),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: Espacio.md),
                Expanded(
                  child: FilledButton(
                    onPressed: alAprobar,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Medida.radioSm)),
                    ),
                    child: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
