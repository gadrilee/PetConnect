import 'package:flutter/material.dart';

/// Variables globales de color de AlquilaMatch.
///
/// REGLA: Nunca usar `Color(0xFF...)` directamente en las pantallas. Siempre
/// usar estas constantes. Cambiar un color acá cambia toda la app.
///
/// REGLA DE LOS TINTES: **nunca usar `withValues(alpha)` fuera de este
/// archivo**. Cada transparencia que usa la app es una variable de Figma
/// (Color/Text 5 %, Color/Primary 10 %, ...) y acá tiene su constante. Si una
/// pieza necesita un tinte que no existe, se agrega acá, una sola vez; una
/// prueba impide volver a calcularlo a mano en una pieza o en una pantalla.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B6B50);
  static const Color secondary = Color(0xFF52796F);
  static const Color text = Color(0xFF3A3A3A);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E8B57);
  static const Color error = Color(0xFFD92929);
  static const Color warning = Color(0xFFC77700);

  // ---------------------------------------------------------------------------
  // Tintes del texto (Figma: Color/Text N %).
  // ---------------------------------------------------------------------------

  /// 5 % — fondo de un aviso info, de un bloque suave y del marcador de foto.
  static final Color text05 = text.withValues(alpha: 0.05);

  /// 6 % — fondo de una pastilla neutra.
  static final Color text06 = text.withValues(alpha: 0.06);

  /// 10 % — borde de una tarjeta y pista apagada de un interruptor.
  static final Color text10 = text.withValues(alpha: 0.1);

  /// 12 % — borde del pie de la pagina y fondo de un boton deshabilitado.
  static final Color text12 = text.withValues(alpha: 0.12);

  /// 38 % — contenido deshabilitado y borde de un campo en reposo.
  static final Color text38 = text.withValues(alpha: 0.38);

  /// 40 % — un icono que solo orienta, como la flecha de un menu.
  static final Color text40 = text.withValues(alpha: 0.4);

  /// 50 % — iconos grises: el marcador de foto, el ojito, un dato secundario.
  static final Color text50 = text.withValues(alpha: 0.5);

  /// 60 % — texto secundario: el detalle de un menu o el rol en el perfil.
  static final Color text60 = text.withValues(alpha: 0.6);

  /// 70 % — texto de apoyo que se lee entero: captions, notas, descripciones.
  static final Color text70 = text.withValues(alpha: 0.7);

  // ---------------------------------------------------------------------------
  // Tintes del color principal (Figma: Color/Primary N %).
  // ---------------------------------------------------------------------------

  /// 5 % — fondo de la tarjeta de rol elegida.
  static final Color primary05 = primary.withValues(alpha: 0.05);

  /// 10 % — fondo de un bloque destacado o de un icono en circulo.
  static final Color primary10 = primary.withValues(alpha: 0.1);

  /// 12 % — fondo de una pastilla primaria y borde de un bloque destacado.
  static final Color primary12 = primary.withValues(alpha: 0.12);

  // ---------------------------------------------------------------------------
  // Tintes de los estados (Figma: Color/Success, Error y Warning N %).
  // ---------------------------------------------------------------------------

  /// Fondo de un aviso de exito o de un icono en circulo de exito.
  static final Color success10 = success.withValues(alpha: 0.1);

  /// Fondo de una pastilla de exito.
  static final Color success12 = success.withValues(alpha: 0.12);

  /// Fondo de un aviso de error y del boton destructivo presionado.
  static final Color error08 = error.withValues(alpha: 0.08);

  /// Fondo de un icono en circulo de error.
  static final Color error10 = error.withValues(alpha: 0.1);

  /// Fondo de una pastilla de error.
  static final Color error12 = error.withValues(alpha: 0.12);

  /// Fondo de un aviso de advertencia y de una pastilla de advertencia.
  static final Color warning12 = warning.withValues(alpha: 0.12);

  // ---------------------------------------------------------------------------
  // Estados del boton principal. No son tintes de Figma: son el color del
  // boton mientras se lo toca o mientras trabaja, definidos una sola vez.
  // ---------------------------------------------------------------------------

  /// El principal un poco mas oscuro: "tu toque se registro".
  static final Color primaryPresionado =
      Color.alphaBlend(Colors.black.withValues(alpha: 0.18), primary);

  /// El principal un poco mas claro: "estoy trabajando, espera".
  static final Color primaryCargando = primary.withValues(alpha: 0.75);
}
