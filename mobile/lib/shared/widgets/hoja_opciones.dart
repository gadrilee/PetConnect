import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'boton_secundario.dart';
import 'titulo_seccion.dart';

/// Una opcion de la hoja: lo que devuelve si se toca, su icono y su texto.
class OpcionHoja<T> {
  const OpcionHoja({
    required this.valor,
    required this.icono,
    required this.etiqueta,
    this.destructiva = false,
  });

  final T valor;
  final IconData icono;
  final String etiqueta;

  /// Borra algo (Quitar foto): icono y texto en rojo.
  final bool destructiva;
}

/// Abre la hoja desde abajo y devuelve el valor de la opcion tocada, o `null`
/// si la persona se arrepiente: CANCELAR, tocar afuera, arrastrarla hacia
/// abajo o el boton de volver del telefono.
Future<T?> mostrarHojaOpciones<T>(
  BuildContext context, {
  required String titulo,
  required List<OpcionHoja<T>> opciones,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.text50,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Medida.radio)),
    ),
    builder: (_) => HojaOpciones<T>(titulo: titulo, opciones: opciones),
  );
}

/// Las opciones de una accion, en una hoja que sube desde abajo.
///
/// REGLA DE LA PIEZA
/// -----------------
/// La asa arriba, el titulo, una fila de 56 por opcion (el toque comodo) y
/// CANCELAR al final: la salida se ve, no hay que adivinar que se cierra
/// tocando afuera. Mismo componente que "Hoja de opciones" en Figma, con sus
/// filas "Opcion de hoja".
class HojaOpciones<T> extends StatelessWidget {
  const HojaOpciones({super.key, required this.titulo, required this.opciones});

  final String titulo;
  final List<OpcionHoja<T>> opciones;

  @override
  Widget build(BuildContext context) {
    final navegador = Navigator.of(context);

    // AUTO LAYOUT (Figma, Hoja de opciones): 16 arriba, 24 a los lados y
    // abajo, 16 entre la asa, el titulo, las opciones y CANCELAR.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.md,
          Espacio.lg,
          Espacio.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: _Asa()),
            const SizedBox(height: Espacio.md),
            TituloSeccion(titulo),
            const SizedBox(height: Espacio.md),
            for (final opcion in opciones)
              _FilaOpcion(
                opcion: opcion,
                alTocar: () => navegador.pop(opcion.valor),
              ),
            const SizedBox(height: Espacio.md),
            BotonSecundario(
              etiqueta: 'CANCELAR',
              alTocar: () => navegador.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// La marca de arriba: dice que la hoja se puede arrastrar para cerrarla.
class _Asa extends StatelessWidget {
  const _Asa();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.text40,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _FilaOpcion<T> extends StatelessWidget {
  const _FilaOpcion({required this.opcion, required this.alTocar});

  final OpcionHoja<T> opcion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final roja = opcion.destructiva;

    // FLEXBOX: icono fijo de 24, 16 y el texto ocupa el resto.
    return InkWell(
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espacio.md),
        child: Row(
          children: [
            Icon(
              opcion.icono,
              size: 24,
              color: roja ? AppColors.error : AppColors.text70,
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Text(
                opcion.etiqueta,
                style: AppText.body(context).copyWith(
                  color: roja ? AppColors.error : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
