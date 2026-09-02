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
/// cuatro estados, incluido el de carga.
class BotonPrincipal extends StatefulWidget {
  const BotonPrincipal({
    super.key,
    required this.etiqueta,
    required this.alTocar,
    this.cargando = false,
    this.etiquetaCargando,
    this.motivoDeshabilitado,
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

  /// Por que no se puede tocar. Se muestra debajo del boton.
  ///
  /// Un boton apagado sin explicacion deja a la persona adivinando. Este texto
  /// es el que convierte "no anda" en "ya se que me falta".
  final String? motivoDeshabilitado;

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
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final actual = estado;

    // El color es lo unico que distingue los estados. La forma se conserva.
    final (Color fondo, Color contenido) = switch (actual) {
      EstadoBoton.reposo => (esquema.primary, esquema.onPrimary),
      EstadoBoton.presionado => (
          Color.alphaBlend(Colors.black.withValues(alpha: 0.18), esquema.primary),
          esquema.onPrimary,
        ),
      EstadoBoton.cargando => (
          esquema.primary.withValues(alpha: 0.75),
          esquema.onPrimary,
        ),
      EstadoBoton.deshabilitado => (
          esquema.onSurface.withValues(alpha: 0.12),
          esquema.onSurface.withValues(alpha: 0.38),
        ),
    };

    final habilitado = actual == EstadoBoton.reposo || actual == EstadoBoton.presionado;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: habilitado,
          label: widget.etiqueta,
          // Sin esto, un lector de pantalla anuncia el boton igual estando
          // deshabilitado o cargando, y la persona lo toca en vano.
          hint: switch (actual) {
            EstadoBoton.cargando => 'Buscando, esperá un momento',
            EstadoBoton.deshabilitado => widget.motivoDeshabilitado ?? 'No disponible',
            _ => null,
          },
          child: GestureDetector(
            onTapDown: habilitado ? (_) => setState(() => _presionado = true) : null,
            onTapUp: habilitado ? (_) => setState(() => _presionado = false) : null,
            onTapCancel: habilitado ? () => setState(() => _presionado = false) : null,
            onTap: habilitado ? widget.alTocar : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: double.infinity,
              height: 52, // constante en los cuatro estados
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(12),
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
                              strokeWidth: 2, color: contenido),
                        ),
                        const SizedBox(width: Espacio.sm),
                        Text(
                          widget.etiquetaCargando ?? widget.etiqueta,
                          style: texto.labelLarge
                              ?.copyWith(color: contenido, letterSpacing: 1),
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
        ),

        // El motivo sólo aparece cuando hace falta: si el botón se puede tocar,
        // explicar por qué no se puede sería ruido.
        if (actual == EstadoBoton.deshabilitado && widget.motivoDeshabilitado != null) ...[
          const SizedBox(height: Espacio.sm),
          Text(
            widget.motivoDeshabilitado!,
            textAlign: TextAlign.center,
            style: texto.bodySmall?.copyWith(color: esquema.error),
          ),
        ],
      ],
    );
  }
}
