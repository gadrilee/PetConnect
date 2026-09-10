import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'boton_secundario.dart';

/// Lo que se muestra cuando no hay nada que listar, o cuando no se pudo
/// cargar.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Siempre dice que pasa y, si se puede hacer algo, ofrece la accion. Una
/// pantalla vacia sin explicacion parece rota. **Un error nunca se muestra
/// como vacio**: decir "no tenes solicitudes" cuando fallo la conexion hace
/// creer algo falso.
///
/// CONSTRAINTS: centrado y con tope de ancho, para que en un monitor no se lea
/// como una sola linea eterna.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.alAccion,
    this.esError = false,
  });

  final IconData icono;
  final String titulo;
  final String? detalle;

  /// Texto del boton, por ejemplo "Reintentar". Sin texto no hay boton.
  final String? accion;
  final VoidCallback? alAccion;

  final bool esError;

  /// Tope de ancho del mensaje.
  static const double anchoMaximo = 360;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximo),
        child: Padding(
          padding: const EdgeInsets.all(Espacio.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icono,
                size: 64,
                color: esError
                    ? AppColors.error
                    : AppColors.text.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Espacio.md),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: AppText.titulo(context).copyWith(color: AppColors.text),
              ),
              if (detalle != null) ...[
                const SizedBox(height: Espacio.sm),
                Text(
                  detalle!,
                  textAlign: TextAlign.center,
                  style: AppText.body(context)
                      .copyWith(color: AppColors.text.withValues(alpha: 0.6)),
                ),
              ],
              if (accion != null) ...[
                const SizedBox(height: Espacio.lg),
                BotonSecundario(etiqueta: accion!, alTocar: alAccion),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
