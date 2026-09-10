import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../features/inquilina/providers/buscar_provider.dart';
import 'bloque.dart';
import 'fila_condicion.dart';

/// Los filtros de la busqueda, dichos en palabras. En Figma es el panel
/// "Tu búsqueda", la columna de 4 en Buscar y en Resultados.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Nombra los cuatro filtros aunque no se hayan usado: "Sin límite de precio"
/// dice mas que un hueco. Asi la persona sabe que esta buscando sin volver
/// atras.
class ResumenBusqueda extends StatelessWidget {
  const ResumenBusqueda({super.key, required this.filtros, this.cantidad});

  final FiltrosBusqueda filtros;

  /// Cuantos anuncios se encontraron. `null` mientras no se busco.
  final int? cantidad;

  @override
  Widget build(BuildContext context) {
    final estilo = AppText.caption(context)
        .copyWith(color: AppColors.text.withValues(alpha: 0.7));
    final precio = filtros.precioMax;
    final minutos = filtros.minutosMax;
    final mascotas = filtros.aceptaMascotas == true;

    final lineas = <(IconData, String)>[
      (
        Icons.attach_money,
        precio == null
            ? 'Sin límite de precio'
            : 'Hasta ${_monto(precio)} Bs por mes',
      ),
      (
        Icons.home_outlined,
        filtros.tipoEspacio?.etiqueta ?? 'Cualquier tipo de espacio',
      ),
      (
        mascotas ? Icons.pets : Icons.pets_outlined,
        mascotas ? 'Acepta mascotas' : 'Con o sin mascotas',
      ),
      (
        Icons.directions_walk,
        minutos == null
            ? 'Sin límite de distancia'
            : 'Hasta $minutos min caminando',
      ),
    ];

    return Bloque(
      tono: TonoBloque.suave,
      hijos: [
        Text(
          'Tu búsqueda',
          style: AppText.button(context)
              .copyWith(color: AppColors.text, letterSpacing: 0),
        ),
        for (final (icono, texto) in lineas) ...[
          const SizedBox(height: Espacio.sm),
          FilaCondicion(icono: icono, texto: texto, estilo: estilo),
        ],
        if (cantidad != null) ...[
          const SizedBox(height: Espacio.md),
          Text(
            cantidad == 1
                ? '1 anuncio encontrado'
                : '$cantidad anuncios encontrados',
            style: AppText.caption(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// 800.0 se lee "800"; 800.5 se lee "800,5".
String _monto(double valor) => valor == valor.roundToDouble()
    ? valor.toInt().toString()
    : valor.toString().replaceAll('.', ',');
