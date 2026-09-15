import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los estados de la tarjeta de rol.
///
/// Cada uno responde una pregunta distinta de la persona que esta eligiendo
/// de que lado del alquiler esta.
enum EstadoTarjetaRol {
  /// Disponible, todavia sin elegir. "Esta es una de las dos opciones."
  reposo,

  /// El dedo esta encima. "Tu toque se registro."
  presionada,

  /// Es la elegida. "De este lado quedaste."
  seleccionada,
}

/// Una de las dos opciones de la pantalla Elegir rol.
///
/// REGLA DE LA PIEZA
/// -----------------
/// El titulo dice que hace la persona ("Busco donde alquilar"), no como se
/// llama el rol. El detalle explica que gana eligiendolo. **Entre estados
/// cambian el fondo y el borde, nunca el tamano**: la tarjeta mide siempre 84
/// de alto, para que la pantalla no salte al elegir. La seleccionada se marca
/// con el fondo, no solo con el borde, para reconocer de un vistazo cual quedo
/// elegida.
///
/// Es la bifurcacion del producto: el rol decide toda la app. Por eso la
/// opcion se muestra con lo que gana la persona, no con el nombre del rol.
class TarjetaRol extends StatefulWidget {
  const TarjetaRol({
    super.key,
    required this.etiqueta,
    required this.descripcion,
    required this.icono,
    required this.seleccionada,
    required this.alTocar,
  });

  /// Que hace la persona con este rol. "Busco donde alquilar", no "Inquilino".
  final String etiqueta;

  /// Que gana eligiendolo. Una linea.
  final String descripcion;

  final IconData icono;

  /// Si es la elegida. La decide la pantalla, porque solo una de las dos
  /// puede estarlo; la tarjeta no puede saberlo sola.
  final bool seleccionada;

  final VoidCallback alTocar;

  @override
  State<TarjetaRol> createState() => _TarjetaRolState();
}

class _TarjetaRolState extends State<TarjetaRol> {
  bool _presionada = false;

  /// El estado se **deriva**, no se pasa por parametro.
  ///
  /// Seleccionada gana a presionada: volver a tocar la elegida no la "apaga"
  /// mientras dura el toque.
  EstadoTarjetaRol get estado {
    if (widget.seleccionada) return EstadoTarjetaRol.seleccionada;
    if (_presionada) return EstadoTarjetaRol.presionada;
    return EstadoTarjetaRol.reposo;
  }

  @override
  Widget build(BuildContext context) {
    final actual = estado;

    // Lo unico que distingue los estados es el fondo y el borde. La forma y
    // el tamano se conservan. Los colores son tintes de AppColors.
    final (Color fondo, Color borde, double grosor, Color colorIcono) =
        switch (actual) {
      EstadoTarjetaRol.reposo => (
          AppColors.surface,
          AppColors.text10,
          1.0,
          AppColors.text70,
        ),
      EstadoTarjetaRol.presionada => (
          AppColors.text05,
          AppColors.text38,
          1.0,
          AppColors.text70,
        ),
      EstadoTarjetaRol.seleccionada => (
          AppColors.primary05,
          AppColors.primary,
          2.0,
          AppColors.primary,
        ),
    };

    return Semantics(
      button: true,
      selected: widget.seleccionada,
      label: widget.etiqueta,
      child: InkWell(
        onTap: widget.alTocar,
        onHighlightChanged: (valor) => setState(() => _presionada = valor),
        borderRadius: BorderRadius.circular(Medida.radio),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: 84, // constante en los tres estados
          padding: const EdgeInsets.symmetric(horizontal: Espacio.md),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(Medida.radio),
            border: Border.all(color: borde, width: grosor),
          ),
          child: Row(
            children: [
              Icon(widget.icono, color: colorIcono, size: 32),
              const SizedBox(width: Espacio.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.etiqueta,
                      style: AppText.button(context)
                          .copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: Espacio.xs),
                    Text(
                      widget.descripcion,
                      style: AppText.caption(context)
                          .copyWith(color: AppColors.text70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
