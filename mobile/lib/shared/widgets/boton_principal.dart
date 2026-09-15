import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los estados de la accion principal.
///
/// No son decoracion: cada uno responde una pregunta distinta de quien mira
/// la pantalla.
enum EstadoBoton {
  /// Se puede tocar. "Esto es lo que sigue."
  reposo,

  /// El dedo esta encima. "Tu toque se registro."
  presionado,

  /// Hay una operacion en curso. "Estoy trabajando, espera."
  cargando,

  /// No se puede tocar todavia. "Falta algo antes de seguir."
  deshabilitado,
}

/// La accion principal de una pantalla.
///
/// REGLA DE LA PIEZA
/// -----------------
/// La accion principal se reconoce igual en todas las pantallas: mismo alto,
/// mismo radio, mismo tipo de etiqueta y una sola por pantalla. **Lo unico que
/// cambia entre pantallas es el texto; lo unico que cambia entre estados es el
/// color y el contenido interno.** El tamano nunca cambia, para que la pantalla
/// no salte cuando el estado cambia.
///
/// Por eso el ancho es fijo al del contenedor y el alto es constante en los
/// cuatro estados, incluido el de carga. Y el boton es solo el boton: por que
/// no se puede seguir lo dice el pie, en `PieAcciones.motivo`, nunca un texto
/// colgado debajo del boton.
class BotonPrincipal extends StatefulWidget {
  const BotonPrincipal({
    super.key,
    required this.etiqueta,
    required this.alTocar,
    this.cargando = false,
    this.etiquetaCargando,
    this.pistaDeshabilitado,
    this.compacto = false,
  });

  /// El texto en reposo. En mayusculas por convencion de la accion principal.
  final String etiqueta;

  /// Que hacer al tocar. **`null` deshabilita el boton**, que es como se
  /// expresa "falta algo antes de seguir".
  final VoidCallback? alTocar;

  /// Hay una operacion en curso.
  final bool cargando;

  /// Texto mientras carga. Si se omite, se conserva la etiqueta original.
  ///
  /// Decirle a la persona que esta pasando es mejor que solo girar un disco:
  /// "BUSCANDO..." informa, un spinner solo entretiene.
  final String? etiquetaCargando;

  /// Lo que anuncia el lector de pantalla cuando el boton esta apagado.
  ///
  /// No se ve. Lo visible —"Corregí los 3 campos marcados en rojo..."— va en
  /// `PieAcciones.motivo`, que es la unica ranura para eso. Aca queda solo la
  /// pista para quien no ve la pantalla, que sin ella toca el boton en vano.
  final String? pistaDeshabilitado;

  /// Version de 48 de alto para las acciones dentro de una tarjeta. Es el
  /// mismo boton con los mismos estados; solo cambia el alto.
  final bool compacto;

  @override
  State<BotonPrincipal> createState() => _BotonPrincipalState();
}

class _BotonPrincipalState extends State<BotonPrincipal> {
  bool _presionado = false;

  /// El estado se **deriva**, no se pasa por parametro.
  ///
  /// Si quien usa el boton pudiera fijar el estado a mano, tarde o temprano
  /// habria un boton en "reposo" que no responde, o uno "cargando" que ya
  /// termino. Derivarlo hace imposible esa contradiccion.
  EstadoBoton get estado {
    if (widget.cargando) return EstadoBoton.cargando;
    if (widget.alTocar == null) return EstadoBoton.deshabilitado;
    if (_presionado) return EstadoBoton.presionado;
    return EstadoBoton.reposo;
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final actual = estado;

    // El color es lo unico que distingue los estados. La forma se conserva.
    // Cada color es una constante de AppColors: la pieza no calcula tintes.
    final (Color fondo, Color contenido) = switch (actual) {
      EstadoBoton.reposo => (AppColors.primary, AppColors.surface),
      EstadoBoton.presionado => (AppColors.primaryPresionado, AppColors.surface),
      EstadoBoton.cargando => (AppColors.primaryCargando, AppColors.surface),
      EstadoBoton.deshabilitado => (AppColors.text12, AppColors.text38),
    };

    final habilitado =
        actual == EstadoBoton.reposo || actual == EstadoBoton.presionado;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: widget.etiqueta,
      // Sin esto, un lector de pantalla anuncia el boton igual estando
      // deshabilitado o cargando, y la persona lo toca en vano.
      hint: switch (actual) {
        EstadoBoton.cargando => 'Buscando, esperá un momento',
        EstadoBoton.deshabilitado =>
          widget.pistaDeshabilitado ?? 'No disponible',
        _ => null,
      },
      child: GestureDetector(
        onTapDown:
            habilitado ? (_) => setState(() => _presionado = true) : null,
        onTapUp: habilitado ? (_) => setState(() => _presionado = false) : null,
        onTapCancel:
            habilitado ? () => setState(() => _presionado = false) : null,
        onTap: habilitado ? widget.alTocar : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: double.infinity,
          // Constante en los cuatro estados.
          height: widget.compacto ? Medida.campo : Medida.boton,
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(Medida.radio),
          ),
          alignment: Alignment.center,
          child: actual == EstadoBoton.cargando
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: contenido,
                      ),
                    ),
                    const SizedBox(width: Espacio.sm),
                    Text(
                      widget.etiquetaCargando ?? widget.etiqueta,
                      style: texto.labelLarge?.copyWith(
                        color: contenido,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                )
              : Text(
                  widget.etiqueta,
                  style: texto.labelLarge?.copyWith(
                    color: contenido,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
