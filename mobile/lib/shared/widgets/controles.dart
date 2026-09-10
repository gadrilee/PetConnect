import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Un boton de opcion unica, con forma de pastilla.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Elegida va rellena del color principal; sin elegir, solo con borde. Se usa
/// igual para el tipo de espacio en Buscar y en Publicar.
///
/// AUTO LAYOUT: el ancho lo pone la etiqueta y el alto es 40, asi
/// "Departamento" no se corta y "Casa" no queda con aire de sobra. Se ubican
/// en un Wrap: si no entran en una fila, pasan a la siguiente.
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
    return Semantics(
      button: true,
      selected: seleccionada,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Medida.radioSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Espacio.md,
            vertical: Espacio.sm + Espacio.xs,
          ),
          decoration: BoxDecoration(
            color: seleccionada ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Medida.radioSm),
            border: Border.all(
              color: seleccionada
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption(context).copyWith(
              color: seleccionada
                  ? AppColors.surface
                  : AppColors.text.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un interruptor de encendido y apagado, de 48x24.
///
/// Con [etiqueta] arma la fila completa: la etiqueta a la izquierda y el
/// interruptor anclado a la derecha. Antes habia dos piezas con el mismo
/// nombre, una con Material y otra propia, y cada pantalla usaba una distinta.
class Interruptor extends StatelessWidget {
  const Interruptor({
    super.key,
    required this.encendido,
    required this.alCambiar,
    this.etiqueta,
  });

  final bool encendido;
  final ValueChanged<bool> alCambiar;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final pista = Semantics(
      toggled: encendido,
      label: etiqueta,
      child: GestureDetector(
        onTap: () => alCambiar(!encendido),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 24,
          padding: const EdgeInsets.all(Espacio.xs),
          decoration: BoxDecoration(
            color: encendido
                ? AppColors.primary
                : AppColors.text.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Medida.radio),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            alignment:
                encendido ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: encendido
                    ? AppColors.surface
                    : AppColors.text.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );

    if (etiqueta == null) return pista;

    // FLEXBOX: la etiqueta toma el espacio libre y el interruptor queda
    // anclado a la derecha.
    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta!,
            style: AppText.body(context).copyWith(color: AppColors.text),
          ),
        ),
        const SizedBox(width: Espacio.md),
        pista,
      ],
    );
  }
}

/// Un deslizador de 16 de alto que ocupa todo el ancho.
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
