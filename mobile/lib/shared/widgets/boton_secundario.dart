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
    this.destructiva = false,
    this.compacto = false,
  });

  final String etiqueta;
  final VoidCallback? alTocar;
  final IconData? icono;

  /// La accion cierra o descarta algo, como Rechazar una solicitud. Cambia
  /// solo el color, borde y texto en rojo; la forma es la misma, para que se
  /// siga leyendo como secundaria al lado de la principal.
  final bool destructiva;

  /// Version de 48 de alto para las acciones dentro de una tarjeta.
  final bool compacto;

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
    final acento = widget.destructiva ? esquema.error : esquema.primary;

    final (Color borde, Color contenido) = switch (actual) {
      EstadoBotonSecundario.reposo => (
        widget.destructiva ? esquema.error : esquema.outline,
        acento,
      ),
      EstadoBotonSecundario.presionado => (acento, acento),
      EstadoBotonSecundario.deshabilitado => (
        esquema.onSurface.withValues(alpha: 0.12),
        esquema.onSurface.withValues(alpha: 0.38),
      ),
    };

    final habilitado =
        actual == EstadoBotonSecundario.reposo || actual == EstadoBotonSecundario.presionado;

    final estiloEtiqueta = texto.labelLarge?.copyWith(
      color: contenido,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
    );

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
          height: widget.compacto ? Medida.campo : Medida.boton,
          decoration: BoxDecoration(
            color: actual == EstadoBotonSecundario.presionado
                ? acento.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(color: borde),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: widget.icono == null
              ? Text(widget.etiqueta, style: estiloEtiqueta)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icono, size: 18, color: contenido),
                    const SizedBox(width: Espacio.sm),
                    Flexible(
                      child: Text(
                        widget.etiqueta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estiloEtiqueta,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
