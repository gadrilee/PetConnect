import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// La foto de un inmueble, con las esquinas redondeadas.
///
/// REGLA DE LA PIEZA
/// -----------------
/// Si no hay foto o no carga, muestra un marcador gris con una casa del mismo
/// tamano que la foto: la tarjeta no salta ni queda con un hueco. Antes el
/// marcador estaba escrito tres veces, en la tarjeta del anuncio, en el
/// historial y en la galeria, cada uno con su propio gris.
class FotoInmueble extends StatelessWidget {
  const FotoInmueble({
    super.key,
    required this.url,
    this.ancho,
    this.alto,
    this.radio = Medida.radioSm,
  });

  /// Direccion de la imagen. `null` o vacia muestra el marcador.
  final String? url;

  /// `null` toma lo que le de el padre.
  final double? ancho;
  final double? alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    // El icono del marcador acompana al lado mas corto de la foto.
    final lado = math.min(ancho ?? double.infinity, alto ?? double.infinity);
    final tamanoIcono =
        (lado.isFinite ? lado / 2.75 : 48.0).clamp(16.0, 64.0).toDouble();

    Widget marcador(IconData icono) => Container(
          width: ancho,
          height: alto,
          color: AppColors.text.withValues(alpha: 0.05),
          alignment: Alignment.center,
          child: Icon(
            icono,
            size: tamanoIcono,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
        );

    final direccion = url;
    final imagen = direccion == null || direccion.isEmpty
        ? marcador(Icons.home_outlined)
        : Image.network(
            direccion,
            width: ancho,
            height: alto,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => marcador(Icons.broken_image_outlined),
            loadingBuilder: (_, hijo, progreso) => progreso == null
                ? hijo
                : SizedBox(
                    width: ancho,
                    height: alto,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: imagen,
    );
  }
}
