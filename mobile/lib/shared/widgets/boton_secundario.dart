import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Los estados de la acción secundaria.
enum EstadoBotonSecundario {
  reposo,
  presionado,
  deshabilitado,
}

/// La acción secundaria (ej. Cancelar, Volver).
///
/// REGLA DE LA PIEZA:
/// Mismo alto y radio que el Botón principal (56x12), pero sin relleno (Outlined).
class BotonSecundario extends StatefulWidget {
  const BotonSecundario({
    super.key,
    required this.etiqueta,
    required this.alTocar,
    this.icono,
  });

  final String etiqueta;
  final VoidCallback? alTocar;
  final IconData? icono;

  @override
  State<BotonSecundario> createState() => _BotonSecundarioState();
}

class _BotonSecundarioState extends State<BotonSecundario> {
  bool _presionado = false;

  EstadoBotonSecundario get estado {
    if (widget.alTocar == null) return EstadoBotonSecundario.deshabilitado;
    if (_presionado) return EstadoBotonSecundario.presionado;
    return EstadoBotonSecundario.reposo;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;
    final actual = estado;

    final (Color borde, Color contenido) = switch (actual) {
      EstadoBotonSecundario.reposo => (esquema.outline, esquema.primary),
      EstadoBotonSecundario.presionado => (
        esquema.primary,
        esquema.primary,
      ),
      EstadoBotonSecundario.deshabilitado => (
        esquema.onSurface.withValues(alpha: 0.12),
        esquema.onSurface.withValues(alpha: 0.38),
      ),
    };

    final habilitado =
        actual == EstadoBotonSecundario.reposo || actual == EstadoBotonSecundario.presionado;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: widget.etiqueta,
      child: GestureDetector(
        onTapDown: habilitado ? (_) => setState(() => _presionado = true) : null,
        onTapUp: habilitado ? (_) => setState(() => _presionado = false) : null,
        onTapCancel: habilitado ? () => setState(() => _presionado = false) : null,
        onTap: habilitado ? widget.alTocar : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: double.infinity,
          height: Medida.boton,
          decoration: BoxDecoration(
            color: actual == EstadoBotonSecundario.presionado
                ? esquema.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(color: borde),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: widget.icono == null
              ? Text(
                  widget.etiqueta,
                  style: texto.labelLarge?.copyWith(
                    color: contenido,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icono, size: 18, color: contenido),
                    const SizedBox(width: Espacio.sm),
                    Text(
                      widget.etiqueta,
                      style: texto.labelLarge?.copyWith(
                        color: contenido,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
