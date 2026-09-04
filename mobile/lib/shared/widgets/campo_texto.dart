import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

/// Los estados de un campo de texto.
///
/// Cada uno responde una pregunta distinta de quien esta llenando el
/// formulario.
enum EstadoCampo {
  /// Vacio y en espera. "Se puede escribir aca."
  reposo,

  /// Tiene el foco. "Estas escribiendo aca."
  foco,

  /// Ya tiene un valor. "Esto es lo que pusiste."
  relleno,

  /// Lo escrito no sirve. "Esto hay que corregirlo, y por esto."
  error,
}

/// Un campo de texto con etiqueta arriba y motivo de error abajo.
///
/// REGLA DE LA PIEZA
/// -----------------
/// La caja mide siempre lo mismo (48 de alto) y la etiqueta va siempre arriba.
/// **Entre estados cambian el borde y el contenido, nunca el tamano de la
/// caja.** Lo unico que crece es el bloque completo cuando aparece el mensaje
/// de error, que se agrega debajo.
///
/// El motivo del error va pegado al campo que lo provoca, no al boton del
/// final de la pantalla: es aca donde se corrige.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.pista,
    this.mensajeError,
    this.icono,
    this.sufijo,
    this.ocultarTexto = false,
    this.tipoTeclado,
    this.formateadores,
    this.accionTeclado,
    this.alEnviar,
  });

  /// El nombre del dato. Siempre visible, tambien cuando el campo tiene texto.
  ///
  /// Una pista que desaparece al escribir deja a la persona sin saber que
  /// dato estaba cargando.
  final String etiqueta;

  final TextEditingController controlador;

  /// Ejemplo de lo que se espera. Solo se ve con el campo vacio.
  final String? pista;

  /// Que esta mal con lo escrito. **`null` significa que el valor es valido**,
  /// que es como se expresa el estado de error sin pasarlo por parametro.
  final String? mensajeError;

  final IconData? icono;

  /// Widget en la derecha (ej. botón del ojito de la contraseña).
  final Widget? sufijo;

  /// Si es `true` oculta el texto (contraseñas).
  final bool ocultarTexto;

  final TextInputType? tipoTeclado;
  final List<TextInputFormatter>? formateadores;
  final TextInputAction? accionTeclado;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    // El estado depende del foco y de lo escrito, asi que hay que reaccionar
    // a los dos y no solo al construir.
    _foco.addListener(_actualizar);
    widget.controlador.addListener(_actualizar);
  }

  @override
  void dispose() {
    _foco.removeListener(_actualizar);
    widget.controlador.removeListener(_actualizar);
    _foco.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  /// El estado se **deriva**, no se pasa por parametro.
  ///
  /// Si se pudiera fijar a mano habria campos "en error" sin nada que
  /// corregir, o campos "vacios" con texto adentro. Derivarlo lo hace
  /// imposible.
  EstadoCampo get estado {
    if (widget.mensajeError != null) return EstadoCampo.error;
    if (_foco.hasFocus) return EstadoCampo.foco;
    if (widget.controlador.text.isNotEmpty) return EstadoCampo.relleno;
    return EstadoCampo.reposo;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final actual = estado;

    // Lo unico que distingue los estados es el borde. La forma se conserva.
    // Estado relleno → borde verde suave: confirma que el dato fue recibido.
    // Estado foco → borde verde completo: "estás escribiendo aquí".
    // Estado error → borde rojo: "esto hay que corregirlo".
    final (Color borde, double grosor) = switch (actual) {
      EstadoCampo.reposo => (esquema.outline.withValues(alpha: 0.4), 1.0),
      EstadoCampo.relleno => (esquema.primary.withValues(alpha: 0.6), 1.5),
      EstadoCampo.foco => (esquema.primary, 2.0),
      EstadoCampo.error => (esquema.error, 2.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.etiqueta,
          style: texto.labelMedium?.copyWith(
            color: actual == EstadoCampo.error
                ? esquema.error
                : esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Espacio.sm),
        Semantics(
          textField: true,
          label: widget.etiqueta,
          // Sin esto un lector de pantalla anuncia el campo igual estando en
          // error, y la persona no se entera de que hay algo que corregir.
          hint: widget.mensajeError,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: Medida.campo, // constante en los cuatro estados
            decoration: BoxDecoration(
              color: esquema.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borde, width: grosor),
            ),
            child: Row(
              children: [
                if (widget.icono != null) ...[
                  const SizedBox(width: Espacio.md),
                  Icon(
                    widget.icono,
                    size: 20,
                    color: actual == EstadoCampo.error
                        ? esquema.error
                        : actual == EstadoCampo.foco || actual == EstadoCampo.relleno
                            ? esquema.primary
                            : esquema.onSurfaceVariant,
                  ),
                  const SizedBox(width: Espacio.sm),
                ] else ...[
                  const SizedBox(width: Espacio.md),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controlador,
                    focusNode: _foco,
                    keyboardType: widget.tipoTeclado,
                    inputFormatters: widget.formateadores,
                    obscureText: widget.ocultarTexto,
                    textInputAction: widget.accionTeclado,
                    onSubmitted: widget.alEnviar,
                    style: texto.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.pista,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.sufijo != null) ...[
                  widget.sufijo!,
                  const SizedBox(width: Espacio.sm),
                ] else ...[
                  const SizedBox(width: Espacio.md),
                ],
              ],
            ),
          ),
        ),

        // El mensaje solo aparece cuando hace falta: explicar un error que no
        // existe seria ruido.
        if (actual == EstadoCampo.error) ...[
          const SizedBox(height: Espacio.sm),
          Text(
            widget.mensajeError!,
            style: texto.bodySmall?.copyWith(color: esquema.error),
          ),
        ],
      ],
    );
  }
}
