import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'aviso.dart';

/// El pie fijo de una pantalla: lo que queda anclado abajo, fuera del scroll.
/// En Figma es la pieza "Pie de acciones".
///
/// REGLA DE LA PIEZA
/// -----------------
/// **Todo pie se arma con esta pieza; ninguna pantalla arma su propia Column
/// para el pie.** Las ranuras van siempre en el mismo orden, de arriba hacia
/// abajo, con 8 entre las que se muestran:
///
/// 1. [aviso]: el resultado o la validacion, a todo el ancho. Un aviso nunca
///    flota ni se alinea a la derecha: si la pantalla tiene pie, va aca y no
///    en un toast.
/// 2. [notaArriba]: una linea de contexto, como "Coordiná la visita por
///    WhatsApp antes de ir".
/// 3. [botonSecundarioArriba]: un `BotonSecundario`, como CANCELAR.
/// 4. [botonPrincipal]: el `BotonPrincipal`. Puede faltar cuando el pie solo
///    cuenta un resultado y ofrece la salida.
/// 5. [botonSecundarioAbajo]: un `BotonSecundario`, la salida o la accion
///    destructiva.
/// 6. [motivo]: por que no se puede seguir, en rojo.
/// 7. [notaWhatsApp]: el candado con "Tu WhatsApp no aparece en el anuncio".
///
/// Las notas se leen: van en Text 70 %, el gris de 4,6:1 sobre blanco, tambien
/// la del WhatsApp, que antes iba en 50 % (2,8:1) y no se leia.
///
/// Las ranuras vacias no ocupan lugar: un pie con solo el boton mide lo que
/// el boton. El borde de arriba, el relleno y el ancho maximo no son de esta
/// pieza: los pone `Pagina` al recibirla en `pie`.
///
/// AUTO LAYOUT: columna que estira a lo ancho y mide lo que sus hijos.
class PieAcciones extends StatelessWidget {
  const PieAcciones({
    super.key,
    this.aviso,
    this.notaArriba,
    this.botonSecundarioArriba,
    this.botonPrincipal,
    this.botonSecundarioAbajo,
    this.motivo,
    this.notaWhatsApp = false,
  });

  /// Que paso o que falta, a todo el ancho y arriba de todo.
  final Aviso? aviso;

  /// Una linea de contexto, centrada y en gris, arriba de los botones.
  final String? notaArriba;

  /// Un `BotonSecundario` arriba de la accion principal.
  final Widget? botonSecundarioArriba;

  /// El `BotonPrincipal`. `null` cuando el pie solo muestra un resultado.
  final Widget? botonPrincipal;

  /// Un `BotonSecundario` debajo de la accion principal.
  final Widget? botonSecundarioAbajo;

  /// Por que no se puede seguir, centrado y en rojo, debajo de los botones.
  final String? motivo;

  /// Recuerda que el WhatsApp no se publica. Solo en Publicar.
  final bool notaWhatsApp;

  /// El texto de la nota del WhatsApp, para no repetirlo en las pruebas.
  static const String textoNotaWhatsApp =
      'Tu WhatsApp no aparece en el anuncio';

  @override
  Widget build(BuildContext context) {
    final caption = AppText.caption(context);

    // Solo las ranuras con contenido, en el orden de la pieza (`?x` deja
    // afuera las que son null).
    final ranuras = <Widget>[
      ?aviso,
      if (notaArriba != null)
        Text(
          notaArriba!,
          textAlign: TextAlign.center,
          style: caption.copyWith(color: AppColors.text70),
        ),
      ?botonSecundarioArriba,
      ?botonPrincipal,
      ?botonSecundarioAbajo,
      if (motivo != null)
        Text(
          motivo!,
          textAlign: TextAlign.center,
          style: caption.copyWith(color: AppColors.error),
        ),
      if (notaWhatsApp)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 16, color: AppColors.text70),
            const SizedBox(width: Espacio.sm),
            Flexible(
              child: Text(
                textoNotaWhatsApp,
                textAlign: TextAlign.center,
                style: caption.copyWith(color: AppColors.text70),
              ),
            ),
          ],
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ranuras.length; i++) ...[
          if (i > 0) const SizedBox(height: Espacio.sm),
          ranuras[i],
        ],
      ],
    );
  }
}
