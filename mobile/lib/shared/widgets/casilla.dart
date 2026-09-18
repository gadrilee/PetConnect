import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Una casilla con su etiqueta, como "Acepto estas condiciones". En Figma es
/// la pieza "Casilla".
///
/// REGLA DE LA PIEZA
/// -----------------
/// La caja mide 24x24 y la etiqueta va a la derecha, con 8 entre las dos.
/// **Toda la fila responde al toque**, no solo la caja: en un telefono la caja
/// sola es un blanco chico. Marcada va rellena del color principal.
///
/// La fila mide por lo menos 48 de alto, el blanco minimo de un toque, con la
/// caja centrada; antes media 40. Para el lector de pantalla es UNA casilla
/// con su etiqueta y su estado ("Agua, casilla, marcada"), no una caja muda
/// mas un texto suelto.
class Casilla extends StatelessWidget {
  const Casilla({
    super.key,
    required this.etiqueta,
    required this.marcado,
    required this.alCambiar,
  });

  final String etiqueta;
  final bool marcado;
  final ValueChanged<bool?> alCambiar;

  @override
  Widget build(BuildContext context) {
    // MergeSemantics junta la fila en un solo nodo: la etiqueta la da el
    // texto, el estado lo da Semantics(checked) y el toque lo da el InkWell.
    // La caja de Material se excluye para no anunciarla dos veces.
    return MergeSemantics(
      child: Semantics(
        checked: marcado,
        child: InkWell(
          onTap: () => alCambiar(!marcado),
          borderRadius: BorderRadius.circular(Medida.radioSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medida.toque),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: marcado,
                      onChanged: alCambiar,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Medida.radioSm / 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Espacio.sm),
                Expanded(
                  child: Text(
                    etiqueta,
                    style: AppText.body(context).copyWith(color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
