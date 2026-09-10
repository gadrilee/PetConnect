import 'package:flutter/widgets.dart';

import '../../core/theme.dart';

/// En que tipo de pantalla se esta dibujando, segun el ancho del contenido.
enum Pantalla { movil, tablet, escritorio }

/// GRID — la fila de 12 columnas de la Clase 8.
///
/// REGLA
/// -----
/// El ancho disponible se reparte en 12 columnas con un medianil de 16. Cada
/// bloque dice cuantas columnas ocupa en cada pantalla: en movil todo va a
/// 12/12, uno debajo del otro; en escritorio el contenido principal toma 8 y
/// el resumen 4. **Responsive no es achicar: los bloques cambian de fila.**
class Grilla {
  const Grilla._();

  static const int columnas = 12;

  /// Por debajo de este ancho de contenido, la pantalla es movil.
  static const double hastaMovil = 600;

  /// Por debajo de este ancho de contenido, la pantalla es tablet.
  static const double hastaTablet = 960;

  /// Ancho maximo del contenido. En un monitor, una linea de 1400 px no se
  /// lee: el contenido se detiene aca y queda centrado.
  static const double anchoMaximo = 1200;

  static Pantalla pantallaPara(double ancho) {
    if (ancho < hastaMovil) return Pantalla.movil;
    if (ancho < hastaTablet) return Pantalla.tablet;
    return Pantalla.escritorio;
  }

  /// Ancho de un bloque de [columnasOcupadas] columnas dentro de [ancho].
  ///
  /// Se redondea hacia abajo a proposito: si la suma de una fila pasara el
  /// ancho por una fraccion de pixel, el ultimo bloque saltaria de fila.
  static double anchoDe(
    int columnasOcupadas,
    double ancho, {
    double medianil = Espacio.md,
  }) {
    final columna = (ancho - medianil * (columnas - 1)) / columnas;
    return (columna * columnasOcupadas + medianil * (columnasOcupadas - 1))
        .floorToDouble();
  }
}

/// Cuantas de las 12 columnas ocupa un bloque en cada pantalla.
///
/// Lo que no se indica hereda del tamano anterior: `Columnas(escritorio: 8)`
/// ocupa 12 en movil y en tablet, y 8 en escritorio.
class Columnas {
  const Columnas({this.movil = Grilla.columnas, int? tablet, int? escritorio})
      : tablet = tablet ?? movil,
        escritorio = escritorio ?? tablet ?? movil;

  final int movil;
  final int tablet;
  final int escritorio;

  int en(Pantalla pantalla) => switch (pantalla) {
        Pantalla.movil => movil,
        Pantalla.tablet => tablet,
        Pantalla.escritorio => escritorio,
      };
}

/// Un bloque de la grilla: cuanto ocupa y que muestra.
class CeldaGrilla {
  const CeldaGrilla({required this.columnas, required this.child});

  final Columnas columnas;
  final Widget child;
}

/// La fila de 12 columnas.
///
/// Por dentro usa las otras tres ideas de la clase:
/// - CONSTRAINTS: no decide su ancho, lo lee de las restricciones del padre
///   con un `LayoutBuilder`.
/// - FLEXBOX: los bloques van en un `Wrap`, el `flex-wrap: wrap` de Flutter.
///   Cada uno recibe su ancho calculado y el Wrap decide en que fila cae.
/// - AUTO LAYOUT: el medianil y la separacion entre filas son fijos; el alto
///   de cada fila lo pone su contenido.
class Grilla12 extends StatelessWidget {
  const Grilla12({
    super.key,
    required this.celdas,
    this.medianil = Espacio.md,
    this.separacionFilas = Espacio.md,
  });

  final List<CeldaGrilla> celdas;
  final double medianil;
  final double separacionFilas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        assert(
          restricciones.hasBoundedWidth,
          'Grilla12 necesita un ancho acotado para repartir las columnas.',
        );
        final ancho = restricciones.maxWidth;
        final pantalla = Grilla.pantallaPara(ancho);

        return SizedBox(
          width: ancho,
          child: Wrap(
            spacing: medianil,
            runSpacing: separacionFilas,
            children: [
              for (final celda in celdas)
                SizedBox(
                  width: Grilla.anchoDe(
                    celda.columnas.en(pantalla),
                    ancho,
                    medianil: medianil,
                  ),
                  child: celda.child,
                ),
            ],
          ),
        );
      },
    );
  }
}
