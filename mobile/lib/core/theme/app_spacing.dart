/// Variables globales de espaciado y medidas (Base 8).
///
/// **ACÁ SE EDITAN TODAS LAS DISTANCIAS DE LA APP.**
class Espacio {
  const Espacio._();

  /// 4 — medio paso. (Figma: XS)
  static const double xs = 4;

  /// 8 — cosas que se leen juntas. (Figma: S)
  static const double sm = 8;

  /// 16 — contenido relacionado. (Figma: M)
  static const double md = 16;

  /// 24 — entre grupos. (Figma: L)
  static const double lg = 24;

  /// 32 — entre secciones o momentos de la tarea. (Figma: XL)
  static const double xl = 32;

  /// 48 — distancias mayores. (Figma: XXL)
  static const double xxl = 48;
}

/// Alturas y radios de las piezas con las que se interactúa.
class Medida {
  const Medida._();

  /// 56 — la acción principal.
  static const double boton = 56;

  /// 48 — un campo de texto.
  static const double campo = 48;

  /// 12 — radio de borde estándar (Figma).
  static const double radio = 12;

  /// 8 — radio de borde pequeño (Figma).
  static const double radioSm = 8;
}
