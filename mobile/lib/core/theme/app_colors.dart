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
///
/// REGLA DE LEGIBILIDAD (WCAG 2.2 AA, medida el 16/09/2026)
/// -----------------------------------------------------------
/// Un texto que se lee necesita 4,5:1 contra su fondo; un icono que orienta o
/// el borde de un control, 3:1. De ahi sale que tinte va en cada lugar:
///
/// - **Text 70 %** es el gris del texto secundario sobre blanco (4,6:1).
/// - **Text 80 %** es ese mismo texto cuando el fondo ya es un tinte: una
///   pastilla neutra, un bloque suave o uno destacado. Sobre gris el 70 % se
///   queda en 4,2:1 y no alcanza; el 80 % da 5,6:1.
/// - **Text 60 %** es solo para iconos que orientan y para el borde de un
///   campo en reposo (3,5:1). Nunca para un texto.
/// - **Text 50 %, 40 % y 38 %** no llegan ni a 3:1: quedan para lo decorativo
///   (el marcador de una foto) y para lo deshabilitado, que WCAG exime.
///
/// Los colores de estado (exito, error, advertencia) estan elegidos para que
/// su texto se lea sobre blanco (6:1) y sobre su propio tinte de 12 % (5:1).
/// `accesibilidad_test` recalcula estos pares: cambiar un valor aca sin mirar
/// la prueba no pasa.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1B6B50);
  static const Color secondary = Color(0xFF52796F);
  static const Color text = Color(0xFF3A3A3A);
  static const Color surface = Color(0xFFFFFFFF);

  /// Exito. 6,0:1 sobre blanco y 5,1:1 sobre [success12]. Antes era #2E8B57,
  /// que como texto daba 4,3:1 sobre blanco y 3,7:1 sobre su tinte.
  static const Color success = Color(0xFF237046);

  /// Error. 6,1:1 sobre blanco y 5,0:1 sobre [error12]. Antes era #D92929,
  /// que sobre su tinte de 12 % daba 4,05:1.
  static const Color error = Color(0xFFBF2020);

  /// Advertencia. 6,1:1 sobre blanco y 5,1:1 sobre [warning12]. Antes era
  /// #C77700, que como texto daba 3,5:1 sobre blanco.
  static const Color warning = Color(0xFF8F5500);

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

  /// 38 % — contenido deshabilitado: el texto de un boton apagado o de una
  /// opcion del menu que todavia no esta. Exento de contraste por inactivo.
  static final Color text38 = text.withValues(alpha: 0.38);

  /// 40 % — variable de Figma sin uso en la app hoy. Con 2,2:1 no alcanza
  /// ni para un icono que orienta; se conserva por el espejo con Figma.
  static final Color text40 = text.withValues(alpha: 0.4);

  /// 50 % — decorativo: el marcador gris de una foto que no cargo. Con
  /// 2,8:1 no alcanza para un icono que orienta ni para un texto.
  static final Color text50 = text.withValues(alpha: 0.5);

  /// 60 % — iconos que orientan (la flecha de un menu, el candado, el ojito,
  /// el icono de una fila de datos) y el borde de un campo en reposo: 3,5:1,
  /// lo que pide un elemento grafico. **Nunca un texto.**
  static final Color text60 = text.withValues(alpha: 0.6);

  /// 70 % — texto secundario sobre blanco: el detalle de un menu, el rol en
  /// el perfil, captions, notas y descripciones (4,6:1).
  static final Color text70 = text.withValues(alpha: 0.7);

  /// 80 % — texto secundario sobre un fondo tenido: una pastilla neutra, el
  /// resumen de la busqueda, la etiqueta del precio en resumen, una nota
  /// dentro de un bloque destacado. 6,2:1 sobre blanco y 5,6:1 sobre Text 6 %.
  static final Color text80 = text.withValues(alpha: 0.8);

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

  /// El principal un poco mas claro: "estoy trabajando, espera". Su texto
  /// blanco queda en 3,7:1: es un estado inactivo, exento de contraste.
  static final Color primaryCargando = primary.withValues(alpha: 0.75);
}
