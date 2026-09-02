import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la segunda pieza de la Clase 6: los cuatro estados del campo de
/// texto y la regla que los une.

Widget _envolver(Widget hijo) => MaterialApp(
      home: Scaffold(
        // Ancho fijo: si no, el campo se estira al de la pantalla y medirlo
        // no probaria nada.
        body: Center(child: SizedBox(width: 320, child: hijo)),
      ),
    );

/// El estado no se pasa por parámetro: se deriva. Se lee desde el State.
EstadoCampo _estadoDe(WidgetTester tester) {
  final state = tester.state(find.byType(CampoTexto));
  return (state as dynamic).estado as EstadoCampo;
}

void main() {
  late TextEditingController ctrl;

  setUp(() => ctrl = TextEditingController());
  tearDown(() => ctrl.dispose());

  group('Los cuatro estados', () {
    testWidgets('reposo: vacío, muestra la pista y ningún error',
        (tester) async {
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        pista: 'Ej. 800',
      )));

      expect(_estadoDe(tester), EstadoCampo.reposo);
      expect(find.text('Ej. 800'), findsOneWidget);
      // La etiqueta se ve aunque el campo esté vacío: una pista que
      // desaparece al escribir deja sin saber qué dato se estaba cargando.
      expect(find.text('Precio máximo por mes'), findsOneWidget);
    });

    testWidgets('foco: al tocarlo pasa a foco y vuelve al salir',
        (tester) async {
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
      )));

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_estadoDe(tester), EstadoCampo.foco);

      // Sacarle el foco: vuelve a reposo porque sigue vacío.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_estadoDe(tester), EstadoCampo.reposo);
    });

    testWidgets('relleno: con texto y sin foco', (tester) async {
      ctrl.text = '800';
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
      )));

      expect(_estadoDe(tester), EstadoCampo.relleno);
      expect(find.text('800'), findsOneWidget);
    });

    testWidgets('error: explica qué corregir, junto al campo', (tester) async {
      ctrl.text = 'abc';
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        mensajeError: 'Escribí un monto válido, como 800.',
      )));

      expect(_estadoDe(tester), EstadoCampo.error);
      // El motivo va pegado al campo que lo provoca, no al final de la
      // pantalla: es acá donde se corrige.
      expect(find.text('Escribí un monto válido, como 800.'), findsOneWidget);
    });
  });

  group('La regla de la pieza', () {
    testWidgets('la caja no cambia de tamaño entre estados', (tester) async {
      Size medirCaja() => tester.getSize(find.byType(AnimatedContainer));

      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        pista: 'Ej. 800',
      )));
      final enReposo = medirCaja();

      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 200));
      final conFoco = medirCaja();

      ctrl.text = 'abc';
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        mensajeError: 'Escribí un monto válido, como 800.',
      )));
      await tester.pump(const Duration(milliseconds: 200));
      final conError = medirCaja();

      // Si la caja cambiara de alto, la pantalla saltaría al escribir.
      // Lo único que crece es el bloque, y sólo hacia abajo.
      expect(conFoco, enReposo);
      expect(conError, enReposo);
      expect(enReposo.height, 48);
    });

    testWidgets('error tiene prioridad sobre foco', (tester) async {
      ctrl.text = 'abc';
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        mensajeError: 'Escribí un monto válido.',
      )));

      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Si hay algo que corregir, eso es lo que importa comunicar.
      expect(_estadoDe(tester), EstadoCampo.error);
    });

    testWidgets('el mensaje no aparece si el valor es válido', (tester) async {
      ctrl.text = '800';
      await tester.pumpWidget(_envolver(CampoTexto(
        etiqueta: 'Precio máximo por mes',
        controlador: ctrl,
        mensajeError: null,
      )));

      expect(_estadoDe(tester), EstadoCampo.relleno);
      expect(find.textContaining('monto válido'), findsNothing);
    });
  });
}
