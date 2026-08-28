import 'package:flutter/material.dart';

/// Escala de espaciado con base 8.
///
/// Sirve para no decidir cada distancia desde cero y para que las relaciones
/// entre elementos sean consistentes en toda la app. La base no es una carcel:
/// es una referencia que mantiene el ritmo.
///
/// La regla que decide cual usar no es estetica, es de significado:
///   - `xs` y `sm` acercan cosas que se leen juntas (etiqueta y campo,
///     dato y unidad, icono y texto).
///   - `md` separa contenido relacionado dentro de un mismo grupo.
///   - `lg` separa un grupo de informacion de otro.
///   - `xl` separa momentos distintos de la tarea.
class Espacio {
  const Espacio._();

  /// 4 — medio paso. Solo dentro de un mismo elemento.
  static const double xs = 4;

  /// 8 — separacion pequena entre cosas que se leen juntas.
  static const double sm = 8;

  /// 16 — contenido relacionado.
  static const double md = 16;

  /// 24 — entre grupos.
  static const double lg = 24;

  /// 32 — entre secciones o momentos de la tarea.
  static const double xl = 32;
}

/// Tema unico de la app. Ningun widget deberia usar colores o medidas a mano:
/// todo sale de aca, para que cambiar la identidad sea tocar un solo archivo.
class AppTheme {
  static const Color _semilla = Color(0xFF1B6B50);

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(seedColor: _semilla);

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: esquema.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: esquema.surface,
        foregroundColor: esquema.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: esquema.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
