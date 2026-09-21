import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Un boton de opcion unica, con forma de pastilla.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Elegida va rellena del color principal; sin elegir, solo con borde. Se usa
/// igual para el tipo de espacio en Buscar y en Publicar, y la etiqueta va
/// siempre centrada en su pastilla.
///
/// AUTO LAYOUT: el alto es 48 —el de un campo de texto y el blanco minimo de
/// un toque; antes era 40 y el dedo erraba— y el ancho lo pone quien la
/// ubica, de dos modos:
/// - Suelta, en un Wrap (Buscar): mide lo que su etiqueta, asi "Departamento"
///   no se corta y "Casa" no queda con aire de sobra. Si no entran en una
///   fila, pasan a la siguiente.
/// - En una [FilaOpciones] (Publicar): las N reparten la fila por partes
///   iguales y la etiqueta queda centrada en el aire que le toca.
/// Ninguna pantalla estira o centra la pieza por su cuenta: usa uno de los
/// dos modos.
///
/// Si la etiqueta igual no entra, se achica en vez de cortarse con puntos
/// suspensivos: una palabra larga se lee chica, pero se lee. Es el arreglo
/// que trajo Gabriel en `c2e8f45`.
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
          // El alto minimo es el blanco del toque; la columna centra la
          // etiqueta en ese alto sin estirar el ancho de la pastilla.
          constraints: const BoxConstraints(minHeight: Medida.toque),
          padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
          decoration: BoxDecoration(
            color: seleccionada ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(Medida.radioSm),
            border: Border.all(
              color: seleccionada ? AppColors.primary : AppColors.text12,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  // Centrada: en una pastilla que la abraza no se nota; en una
                  // estirada por FilaOpciones, si.
                  textAlign: TextAlign.center,
                  style: AppText.caption(context).copyWith(
                    color: seleccionada ? AppColors.surface : AppColors.text70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una fila de [Opcion] que reparten el ancho por partes iguales.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Es el modo de Figma "02 Publicar": pocas opciones, en una sola fila, y
/// "Casa" mide lo mismo que "Departamento" en vez de encogerse a su palabra.
/// La fila va de punta a punta de lo que la contiene, con 8 entre una opcion
/// y otra. Con muchas opciones, o de largo muy distinto, va el Wrap suelto:
/// aca no hay segunda fila.
///
/// FLEXBOX: cada opcion en un Expanded con el mismo flex; el ancho que le
/// toca a cada una sale de repartir, no de su etiqueta.
class FilaOpciones extends StatelessWidget {
  const FilaOpciones({super.key, required this.opciones});

  final List<Opcion> opciones;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, opcion) in opciones.indexed) ...[
          if (i > 0) const SizedBox(width: Espacio.sm),
          Expanded(child: opcion),
        ],
      ],
    );
  }
}

/// Un interruptor de encendido y apagado, de 48x24.
///
/// Con [etiqueta] arma la fila completa: la etiqueta a la izquierda y el
/// interruptor anclado a la derecha, y **toda la fila responde al toque**, con
/// 48 de alto minimo: la pista sola, de 24, era un blanco chico. Suelto, la
/// pista va centrada en un area de toque de 48x48. Para el lector de pantalla
/// es un solo interruptor con su etiqueta y su estado.
///
/// El pulgar apagado va en Text 60 % sobre la pista de Text 10 %: con 50 % no
/// se distinguia de la pista. Antes habia dos piezas con el mismo nombre, una
/// con Material y otra propia, y cada pantalla usaba una distinta.
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
    // La pista dibuja el estado y nada mas: el toque y la semantica los pone
    // quien la envuelve, segun venga con etiqueta o suelta.
    final pista = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 24,
      padding: const EdgeInsets.all(Espacio.xs),
      decoration: BoxDecoration(
        color: encendido ? AppColors.primary : AppColors.text10,
        borderRadius: BorderRadius.circular(Medida.radio),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: encendido ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: encendido ? AppColors.surface : AppColors.text60,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    if (etiqueta == null) {
      return Semantics(
        toggled: encendido,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => alCambiar(!encendido),
          child: SizedBox(
            width: Medida.toque,
            height: Medida.toque,
            child: Center(child: pista),
          ),
        ),
      );
    }

    // FLEXBOX: la etiqueta toma el espacio libre y el interruptor queda
    // anclado a la derecha. MergeSemantics junta etiqueta, estado y toque en
    // un solo nodo.
    return MergeSemantics(
      child: Semantics(
        toggled: encendido,
        child: InkWell(
          onTap: () => alCambiar(!encendido),
          borderRadius: BorderRadius.circular(Medida.radioSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medida.toque),
            child: Row(
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
            ),
          ),
        ),
      ),
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
          inactiveTrackColor: AppColors.text10,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary10,
        ),
        child: Slider(value: valor, min: min, max: max, onChanged: alCambiar),
      ),
    );
  }
}
