import 'package:flutter/material.dart';

/// Escala de espaciado con base 8.
///
/// **ACA SE EDITAN TODAS LAS DISTANCIAS DE LA APP.**
///
/// Ninguna pantalla escribe un numero de separacion a mano: todas usan estas
/// cuatro constantes. Cambiar un valor de aca cambia el ritmo de toda la app
/// de una sola vez, y evita que aparezcan 12, 14 o 20 sueltos que nadie sabe
/// de donde salieron.
///
/// La regla que decide cual usar no es estetica, es de significado. Es la
/// misma que se aplico al wireframe de Figma, asi que diseno y codigo miden
/// lo mismo:
///
/// | Valor | Cuando |
/// |-------|--------|
/// | `sm`  | cosas que se leen juntas: etiqueta y campo, dato y unidad |
/// | `md`  | contenido relacionado dentro de un mismo grupo |
/// | `lg`  | entre un grupo de informacion y otro |
/// | `xl`  | entre momentos distintos de la tarea |
class Espacio {
  const Espacio._();

  /// 4 — medio paso.
  ///
  /// **No es parte de la escala** y no se usa para separar dos elementos.
  /// Solo para relleno interno de una pieza chica (la pastilla de la fecha
  /// sobre la foto), donde 4 arriba y 4 abajo dan un alto total que si cae
  /// en la escala.
  static const double xs = 4;

  /// 8 — cosas que se leen juntas.
  static const double sm = 8;

  /// 16 — contenido relacionado.
  static const double md = 16;

  /// 24 — entre grupos.
  static const double lg = 24;

  /// 32 — entre secciones o momentos de la tarea.
  static const double xl = 32;
}

/// Alturas de las piezas con las que se interactua.
///
/// **ACA SE EDITAN LOS ALTOS DE BOTONES Y CAMPOS.**
///
/// Son multiplos de 8, igual que las distancias: si no lo fueran, todo lo que
/// se mida contra ellos quedaria fuera de la escala. El boton media 52 y por
/// eso arrancaba en y=724 — cualquier separacion hasta el daba un numero raro.
class Medida {
  const Medida._();

  /// 56 — la accion principal y las secundarias que la acompanan.
  ///
  /// Mas alto que un campo a proposito: es lo que hay que tocar, no algo que
  /// se rellena.
  static const double boton = 56;

  /// 48 — un campo de texto. El minimo comodo para tocar con el dedo.
  static const double campo = 48;
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
          minimumSize: const Size.fromHeight(Medida.boton),
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
