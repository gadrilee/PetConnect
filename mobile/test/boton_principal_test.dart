import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la pieza de la Clase 6: los cuatro estados de la acción
/// principal y la regla que los une.

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(body: Center(child: hijo)),
);

/// El estado no se pasa por parámetro: se deriva. Se lee desde el State.
EstadoBoton _estadoDe(WidgetTester tester) {
  final state = tester.state(find.byType(BotonPrincipal));
  return (state as dynamic).estado as EstadoBoton;
}

void main() {
  group('Los cuatro estados', () {
    testWidgets('reposo: se puede tocar y muestra su etiqueta', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(BotonPrincipal(etiqueta: 'BUSCAR', alTocar: () => toques++)),
      );

      expect(_estadoDe(tester), EstadoBoton.reposo);
      expect(find.text('BUSCAR'), findsOneWidget);

      await tester.tap(find.byType(BotonPrincipal));
      expect(toques, 1);
    });

    testWidgets('presionado: mientras el dedo está encima', (tester) async {
      await tester.pumpWidget(
        _envolver(BotonPrincipal(etiqueta: 'BUSCAR', alTocar: () {})),
      );

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(BotonPrincipal)),
      );
      await tester.pump();
      expect(_estadoDe(tester), EstadoBoton.presionado);

      await gesto.up();
      await tester.pumpAndSettle();
      expect(_estadoDe(tester), EstadoBoton.reposo);
    });

    testWidgets('cargando: avisa qué está pasando y no acepta toques', (
      tester,
    ) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          BotonPrincipal(
            etiqueta: 'BUSCAR',
            etiquetaCargando: 'BUSCANDO...',
            cargando: true,
            alTocar: () => toques++,
          ),
        ),
      );

      expect(_estadoDe(tester), EstadoBoton.cargando);
      expect(find.text('BUSCANDO...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(BotonPrincipal));
      expect(toques, 0, reason: 'no debe dispararse dos veces la búsqueda');
    });

    testWidgets('deshabilitado: no acepta toques y le dice al lector de '
        'pantalla por qué', (tester) async {
      // El arbol de semantica solo existe mientras alguien lo pide; se suelta
      // antes de terminar, o la prueba falla por la manija viva.
      final semantica = tester.ensureSemantics();
      var toques = 0;
      await tester.pumpWidget(
        _envolver(
          const BotonPrincipal(
            etiqueta: 'BUSCAR',
            alTocar: null,
            pistaDeshabilitado: 'Escribí un monto válido.',
          ),
        ),
      );

      expect(_estadoDe(tester), EstadoBoton.deshabilitado);
      // La pista no se ve: lo visible lo dice el pie, en PieAcciones.motivo.
      // Quien no ve la pantalla la escucha, en vez de tocar en vano.
      expect(find.text('Escribí un monto válido.'), findsNothing);
      expect(
        tester.getSemantics(find.byType(BotonPrincipal)).hint,
        'Escribí un monto válido.',
      );

      await tester.tap(find.byType(BotonPrincipal), warnIfMissed: false);
      expect(toques, 0);
      semantica.dispose();
    });
  });

  group('La regla de la pieza', () {
    testWidgets('el tamaño no cambia entre estados', (tester) async {
      Size medir() => tester.getSize(find.byType(AnimatedContainer));

      await tester.pumpWidget(
        _envolver(BotonPrincipal(etiqueta: 'BUSCAR', alTocar: () {})),
      );
      final enReposo = medir();

      await tester.pumpWidget(
        _envolver(
          BotonPrincipal(
            etiqueta: 'BUSCAR',
            etiquetaCargando: 'BUSCANDO...',
            cargando: true,
            alTocar: () {},
          ),
        ),
      );
      // No se usa pumpAndSettle: el spinner gira indefinidamente y nunca
      // se estabilizaria. Alcanza con dejar correr la transicion de color.
      await tester.pump(const Duration(milliseconds: 200));
      final cargando = medir();

      await tester.pumpWidget(
        _envolver(const BotonPrincipal(etiqueta: 'BUSCAR', alTocar: null)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final deshabilitado = medir();

      // Si el tamaño cambiara, la pantalla saltaría al cambiar de estado.
      expect(cargando, enReposo);
      expect(deshabilitado, enReposo);
    });

    testWidgets('cargando tiene prioridad sobre deshabilitado', (tester) async {
      await tester.pumpWidget(
        _envolver(
          const BotonPrincipal(
            etiqueta: 'BUSCAR',
            alTocar: null,
            cargando: true,
          ),
        ),
      );

      // Si ya está buscando, lo que importa comunicar es eso.
      expect(_estadoDe(tester), EstadoBoton.cargando);
    });

    testWidgets('la pista no se anuncia si el botón se puede tocar', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(
          BotonPrincipal(
            etiqueta: 'BUSCAR',
            alTocar: () {},
            pistaDeshabilitado: 'Escribí un monto válido.',
          ),
        ),
      );

      expect(tester.getSemantics(find.byType(BotonPrincipal)).hint, isEmpty);
      semantica.dispose();
    });
  });
}
