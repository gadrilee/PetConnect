import 'package:flutter/material.dart';

/// Variables globales de tipografía de AlquilaMatch (Inter).
///
/// REGLA: Nunca definir pesos tipográficos sueltos. Usar estos estilos base.
class AppText {
  const AppText._();

  /// Figma: Heading (Inter Bold)
  static TextStyle heading(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontWeight: FontWeight.w700,
        );
  }

  /// Figma: Titulo de seccion (Inter Bold 18). El titulo de un bloque, de un
  /// estado vacio o del nombre en el perfil. Antes cada pantalla escribia
  /// `heading` con `fontSize: 18` a mano.
  static TextStyle titulo(BuildContext context) {
    return heading(context).copyWith(fontSize: 18);
  }

  /// Figma: Cifra destacada (Inter Bold 24), como el precio final.
  static TextStyle cifra(BuildContext context) {
    return heading(context).copyWith(fontSize: 24);
  }

  /// Figma: Body (Inter Regular)
  static TextStyle body(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w400,
        );
  }

  /// Figma: Button (Inter SemiBold)
  static TextStyle button(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        );
  }

  /// Figma: Caption (Inter Medium)
  static TextStyle caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w500,
        );
  }
}
