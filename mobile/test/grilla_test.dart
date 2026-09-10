import 'package:alquilamatch/shared/layout/grilla.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la grilla de 12 columnas (Clase 8, idea 04: Grid).
///
/// Fijan la regla con numeros: en movil los bloques van 12/12 uno debajo del
/// otro, en escritorio 8 + 4 en la misma fila, y nunca se achican para entrar.

const _principal = Key('principal');
const _resumen = Key('resumen');

/// Una grilla con contenido principal y resumen, como la de la clase.
Widget _grilla(double ancho) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: ancho,
      child: const Grilla12(
        celdas: [
          CeldaGrilla(
            columnas: Columnas(tablet: 6, escritorio: 8),
            child: SizedBox(key: _principal, height: 100),
          ),
          CeldaGrilla(
            columnas: Columnas(tablet: 6, escritorio: 4),
            child: SizedBox(key: _resumen, height: 60),
          ),
        ],
      ),
    ),
  ),
);

/// La ventana de la prueba es ancha para que entre el ancho de escritorio.
Future<void> _montar(WidgetTester tester, double ancho) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_grilla(ancho));
}

void main() {
  test('el ancho del contenido decide la pantalla', () {
    expect(Grilla.pantallaPara(312), Pantalla.movil);
    expect(Grilla.pantallaPara(720), Pantalla.tablet);
    expect(Grilla.pantallaPara(1200), Pantalla.escritorio);
  });

  test('una fila de 8 + 4 nunca pasa el ancho, ni por medio pixel', () {
    for (final ancho in [312.0, 720.0, 976.0, 1200.0]) {
      final fila = Grilla.anchoDe(8, ancho) + 16 + Grilla.anchoDe(4, ancho);
      expect(fila, lessThanOrEqualTo(ancho), reason: 'en $ancho');
    }
    expect(Grilla.anchoDe(12, 1200), 1200);
  });

  testWidgets('movil: los dos bloques a 12 columnas, uno debajo del otro', (
    tester,
  ) async {
    await _montar(tester, 312);

    expect(tester.getSize(find.byKey(_principal)).width, 312);
    expect(tester.getSize(find.byKey(_resumen)).width, 312);
    expect(
      tester.getTopLeft(find.byKey(_resumen)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byKey(_principal)).dy),
    );
  });

  testWidgets('tablet: 6 + 6 en la misma fila', (tester) async {
    await _montar(tester, 720);

    final principal = tester.getRect(find.byKey(_principal));
    final resumen = tester.getRect(find.byKey(_resumen));
    expect(principal.top, resumen.top);
    expect(principal.width, resumen.width);
    expect(resumen.left, greaterThan(principal.right));
  });

  testWidgets('escritorio: principal en 8 columnas y resumen en 4', (
    tester,
  ) async {
    await _montar(tester, 1200);

    final principal = tester.getRect(find.byKey(_principal));
    final resumen = tester.getRect(find.byKey(_resumen));
    expect(principal.top, resumen.top);
    expect(principal.width, Grilla.anchoDe(8, 1200));
    expect(resumen.width, Grilla.anchoDe(4, 1200));
    // El medianil de 16 separa las dos columnas.
    expect(resumen.left - principal.right, 16);
  });
}
