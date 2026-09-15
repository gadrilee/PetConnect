import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_rol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la tarjeta de rol del flujo v0.3: los tres estados y la regla
/// que los une.

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(
    // Ancho fijo: si no, la tarjeta se estira al de la pantalla y medirla
    // no probaria nada.
    body: Center(child: SizedBox(width: 320, child: hijo)),
  ),
);

TarjetaRol _tarjeta({bool seleccionada = false, VoidCallback? alTocar}) =>
    TarjetaRol(
      etiqueta: 'Busco dónde alquilar',
      descripcion: 'Filtrás por precio final, mascotas y ubicación.',
      icono: Icons.search,
      seleccionada: seleccionada,
      alTocar: alTocar ?? () {},
    );

/// El estado no se pasa por parámetro: se deriva. Se lee desde el State.
EstadoTarjetaRol _estadoDe(WidgetTester tester) {
  final state = tester.state(find.byType(TarjetaRol));
  return (state as dynamic).estado as EstadoTarjetaRol;
}

BoxDecoration _decoracion(WidgetTester tester) {
  final caja = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  return caja.decoration! as BoxDecoration;
}

void main() {
  group('Los tres estados', () {
    testWidgets(
      'reposo: muestra qué hace la persona y qué gana, y se puede tocar',
      (tester) async {
        var toques = 0;
        await tester.pumpWidget(_envolver(_tarjeta(alTocar: () => toques++)));

        expect(_estadoDe(tester), EstadoTarjetaRol.reposo);
        // Dice qué hace la persona, no cómo se llama el rol.
        expect(find.text('Busco dónde alquilar'), findsOneWidget);
        expect(
          find.text('Filtrás por precio final, mascotas y ubicación.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.search), findsOneWidget);

        await tester.tap(find.byType(TarjetaRol));
        expect(toques, 1);
      },
    );

    testWidgets(
      'presionada: mientras el dedo está encima, y vuelve al soltar',
      (tester) async {
        await tester.pumpWidget(_envolver(_tarjeta()));

        final gesto = await tester.startGesture(
          tester.getCenter(find.byType(TarjetaRol)),
        );
        await tester.pump();
        expect(_estadoDe(tester), EstadoTarjetaRol.presionada);

        await gesto.up();
        await tester.pumpAndSettle();
        expect(_estadoDe(tester), EstadoTarjetaRol.reposo);
      },
    );

    testWidgets('seleccionada: se marca con el fondo, no sólo con el borde', (
      tester,
    ) async {
      await tester.pumpWidget(_envolver(_tarjeta(seleccionada: true)));
      await tester.pumpAndSettle();

      expect(_estadoDe(tester), EstadoTarjetaRol.seleccionada);
      final deco = _decoracion(tester);
      // Tiene que reconocerse de un vistazo cuál quedó elegida.
      expect(deco.color, isNot(AppColors.surface));
      expect((deco.border! as Border).top.color, AppColors.primary);
    });
  });

  group('La regla de la pieza', () {
    testWidgets('el tamaño no cambia entre estados', (tester) async {
      Size medir() => tester.getSize(find.byType(AnimatedContainer));

      await tester.pumpWidget(_envolver(_tarjeta()));
      final enReposo = medir();

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(TarjetaRol)),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final presionada = medir();
      await gesto.up();
      await tester.pumpAndSettle();

      await tester.pumpWidget(_envolver(_tarjeta(seleccionada: true)));
      await tester.pump(const Duration(milliseconds: 200));
      final seleccionada = medir();

      // Si el tamaño cambiara, la pantalla saltaría al elegir.
      expect(enReposo.height, 84);
      expect(presionada, enReposo);
      expect(seleccionada, enReposo);
    });

    testWidgets('seleccionada tiene prioridad sobre presionada', (
      tester,
    ) async {
      await tester.pumpWidget(_envolver(_tarjeta(seleccionada: true)));

      final gesto = await tester.startGesture(
        tester.getCenter(find.byType(TarjetaRol)),
      );
      await tester.pump();
      // Volver a tocar la elegida no la "apaga" mientras dura el toque.
      expect(_estadoDe(tester), EstadoTarjetaRol.seleccionada);

      await gesto.up();
      await tester.pumpAndSettle();
    });

    testWidgets('el título y el detalle se ven en todos los estados', (
      tester,
    ) async {
      for (final seleccionada in [false, true]) {
        await tester.pumpWidget(
          _envolver(_tarjeta(seleccionada: seleccionada)),
        );
        expect(find.text('Busco dónde alquilar'), findsOneWidget);
        expect(
          find.text('Filtrás por precio final, mascotas y ubicación.'),
          findsOneWidget,
        );
      }
    });
  });
}
