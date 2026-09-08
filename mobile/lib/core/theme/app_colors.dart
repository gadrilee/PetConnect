import 'package:flutter/material.dart';

/// Variables globales de color de AlquilaMatch.
///
/// REGLA: Nunca usar `Color(0xFF...)` directamente en las pantallas. Siempre
/// usar estas constantes. Cambiar un color acá cambia toda la app.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B6B50);
  static const Color secondary = Color(0xFF52796F);
  static const Color text = Color(0xFF3A3A3A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E8B57);
  static const Color error = Color(0xFFD92929);
  static const Color warning = Color(0xFFC77700);
}
