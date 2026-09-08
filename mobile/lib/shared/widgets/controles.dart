import 'package:flutter/material.dart';

import '../../../core/theme.dart';

/// Un botón de opción única (radio button con estilo de pastilla).
///
/// Mide exactamente 96x40 con radio 8.
class Opcion extends StatelessWidget {
  const Opcion({
    super.key,
    required this.etiqueta,
    required this.seleccionada,
    required this.alTocar,
  });

  final String etiqueta;
  final bool seleccionada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(Medida.radioSm),
      child: Container(
        width: 96,
        height: 40,
        decoration: BoxDecoration(
          color: seleccionada ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(Medida.radioSm),
          border: seleccionada
              ? null
              : Border.all(color: AppColors.text.withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          etiqueta,
          style: AppText.caption(context).copyWith(
            color: seleccionada ? AppColors.surface : AppColors.text.withValues(alpha: 0.7),
            fontWeight: seleccionada ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Un interruptor personalizado que mide exactamente 48x24.
///
/// La perilla mide 16x16 y el aire alrededor es de 4px.
class Interruptor extends StatelessWidget {
  const Interruptor({
    super.key,
    required this.encendido,
    required this.alCambiar,
  });

  final bool encendido;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => alCambiar(!encendido),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 24,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: encendido ? AppColors.primary : AppColors.text.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: encendido ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: encendido ? AppColors.surface : AppColors.text.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Un deslizador personalizado que mide 312x16.
///
/// La pista mide 4 de alto y el pulgar 16x16.
class Deslizador extends StatelessWidget {
  const Deslizador({
    super.key,
    required this.valor,
    required this.min,
    required this.max,
    required this.alCambiar,
  });

  final double valor;
  final double min;
  final double max;
  final ValueChanged<double> alCambiar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 16,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.text.withValues(alpha: 0.1),
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withValues(alpha: 0.1),
        ),
        child: Slider(value: valor, min: min, max: max, onChanged: alCambiar),
      ),
    );
  }
}
