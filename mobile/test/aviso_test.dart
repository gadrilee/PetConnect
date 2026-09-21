import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/shared/layout/pagina.dart';
import 'package:alquilamatch/shared/widgets/aviso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas del aviso (la pieza "Feedback" en Figma): los cuatro tipos y la
/// regla que los une.

Widget _envolver(Widget hijo) => MaterialApp(
  home: Scaffold(
    // Ancho fijo: el aviso se estira al de la pantalla y medirlo no probaria
    // nada.
    body: Center(child: SizedBox(width: 320, child: hijo)),
  ),
);

const _mensaje =
    'No aparece en tus anuncios. Se libera sólo cuando aprobás una visita.';

BoxDecoration _decoracion(WidgetTester tester, String texto) {
  final caja = tester.widget<Container>(
    find
        .ancestor(of: find.text(texto), matching: find.byType(Container))
        .first,
  );
  return caja.decoration! as BoxDecoration;
}

void main() {
  group('Los cuatro tipos', () {
    // Cada tipo se reconoce por su color antes de leer el texto, y trae su
    // propio ícono si no se le pasa otro.
    final casos = <TipoAviso, (Color, IconData)>{
      TipoAviso.info: (AppColors.text, Icons.info_outline),
      TipoAviso.exito: (AppColors.success, Icons.check_circle_outline),
      TipoAviso.error: (AppColors.error, Icons.error_outline),
      TipoAviso.advertencia: (AppColors.warning, Icons.warning_amber_outlined),
    };

    for (final MapEntry(key: tipo, value: (color, icono)) in casos.entries) {
      testWidgets('${tipo.name}: lleva el color del tipo y su ícono', (
        tester,
      ) async {
        await tester.pumpWidget(
          _envolver(Aviso(mensaje: _mensaje, tipo: tipo)),
        );

        expect(find.text(_mensaje), findsOneWidget);
        expect(find.byIcon(icono), findsOneWidget);
        expect(
          (_decoracion(tester, _mensaje).border! as Border).top.color,
          color,
        );
        expect(tester.widget<Icon>(find.byIcon(icono)).color, color);
      });
    }
  });

  group('La regla de la pieza', () {
    testWidgets(
      'el tamaño no cambia entre tipos ni con el largo del mensaje',
      (tester) async {
        Size medir() => tester.getSize(find.byType(Aviso));

        await tester.pumpWidget(
          _envolver(const Aviso(mensaje: 'Corto.', tipo: TipoAviso.info)),
        );
        final corto = medir();
        expect(corto.height, 64);

        for (final tipo in TipoAviso.values) {
          await tester.pumpWidget(
            _envolver(
              Aviso(mensaje: '$_mensaje $_mensaje $_mensaje', tipo: tipo),
            ),
          );
          // Un mensaje larguísimo tampoco lo agranda: se corta en dos líneas.
          expect(medir(), corto, reason: 'cambió de tamaño en $tipo');
        }
      },
    );

    testWidgets('el mensaje se corta en dos líneas, no empuja la pantalla', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(Aviso(mensaje: '$_mensaje $_mensaje $_mensaje')),
      );

      final texto = tester.widget<Text>(find.textContaining('No aparece'));
      expect(texto.maxLines, 2);
      expect(texto.overflow, TextOverflow.ellipsis);
    });

    testWidgets('un ícono explícito gana al del tipo', (tester) async {
      // La promesa del WhatsApp es un aviso de tipo info con candado: el
      // ícono dice de qué se trata, el color dice qué tan grave es.
      await tester.pumpWidget(
        _envolver(const Aviso(icono: Icons.lock_outline, mensaje: _mensaje)),
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('el que lleva a algún lado avisa con la flecha, y el que no, no', (
      tester,
    ) async {
      await tester.pumpWidget(_envolver(const Aviso(mensaje: _mensaje)));
      expect(
        find.byIcon(Icons.open_in_new),
        findsNothing,
        reason: 'un aviso que sólo informa no promete que lleva a ningún lado',
      );

      var tocado = 0;
      await tester.pumpWidget(
        _envolver(Aviso(mensaje: _mensaje, alTocar: () => tocado++)),
      );

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      await tester.tap(find.byType(Aviso));
      expect(tocado, 1);
    });

    testWidgets('el que se toca mide lo mismo que el que no', (tester) async {
      // La flecha entra en el aviso, no lo agranda: es la regla de la pieza.
      await tester.pumpWidget(_envolver(const Aviso(mensaje: _mensaje)));
      final quieto = tester.getSize(find.byType(Aviso));

      await tester.pumpWidget(
        _envolver(Aviso(mensaje: _mensaje, alTocar: () {})),
      );
      expect(tester.getSize(find.byType(Aviso)), quieto);
      expect(quieto.height, 64);
    });

    testWidgets('el que se toca se anuncia como botón', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _envolver(Aviso(mensaje: _mensaje, alTocar: () {})),
      );

      expect(
        tester.getSemantics(find.text(_mensaje)),
        matchesSemantics(
          label: _mensaje,
          isButton: true,
          hasTapAction: true,
          // Los del InkWell, que tambien sirven: se llega con el teclado.
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('como toast, aparece y se va solo a los tres segundos', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Aviso.mostrarToast(
                  context,
                  mensaje: 'Cuenta creada con éxito',
                  tipo: TipoAviso.exito,
                ),
                child: const Text('crear'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('crear'));
      await tester.pump();
      expect(find.text('Cuenta creada con éxito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Cuenta creada con éxito'), findsNothing);
    });

    testWidgets('como toast, ocupa el margen de la página, centrado', (
      tester,
    ) async {
      // Un aviso nunca queda suelto ni alineado a la derecha: el toast se ve
      // igual que cualquier otro aviso, con el margen de 24 de la página y
      // sin pasar el ancho de un formulario.
      for (final (tamano, ancho) in [
        (const Size(360, 800), 360 - Espacio.lg * 2),
        (const Size(1440, 900), AnchoPagina.formulario.maximo),
      ]) {
        tester.view.physicalSize = tamano;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Aviso.mostrarToast(
                    context,
                    mensaje: 'Cuenta creada con éxito',
                    tipo: TipoAviso.exito,
                  ),
                  child: const Text('crear'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('crear'));
        await tester.pump();

        final caja = tester.getRect(find.byType(Aviso));
        expect(caja.width, ancho, reason: '$tamano');
        expect(caja.center.dx, tamano.width / 2, reason: '$tamano');
        expect(caja.bottom, tamano.height - Espacio.md, reason: '$tamano');

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
      }
    });
  });
}
