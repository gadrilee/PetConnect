import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_solicitud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la tarjeta de solicitud del flujo v0.4: los tres estados y la
/// regla que los une.
///
/// Usan el tema real y el ancho real del contenido en un telefono: 312.

Widget _envolver(Widget hijo) => MaterialApp(
  theme: AppTheme.claro,
  home: Scaffold(
    body: Center(child: SizedBox(width: 312, child: hijo)),
  ),
);

TarjetaSolicitud _tarjeta({
  EstadoSolicitud estado = EstadoSolicitud.pendiente,
  String titulo = 'Habitación a aprox 40 min de la UAGRM',
  String inquilino = 'andrea',
  VoidCallback? alTocar,
  VoidCallback? alAprobar,
  VoidCallback? alRechazar,
}) => TarjetaSolicitud(
  numero: 3,
  tituloAnuncio: titulo,
  inquilino: inquilino,
  fecha: DateTime(2026, 9, 8),
  estado: estado,
  alTocar: alTocar,
  alAprobar: alAprobar ?? () {},
  alRechazar: alRechazar ?? () {},
);

void main() {
  group('Los tres estados', () {
    testWidgets('pendiente: trae las dos acciones y ninguna etiqueta', (
      tester,
    ) async {
      var aprobar = 0;
      var rechazar = 0;
      await tester.pumpWidget(
        _envolver(
          _tarjeta(
            alAprobar: () => aprobar++,
            alRechazar: () => rechazar++,
          ),
        ),
      );

      expect(find.text('Solicitud #3'), findsOneWidget);
      expect(find.text('andrea'), findsOneWidget);
      expect(find.text('8/9/2026'), findsOneWidget);
      expect(find.text('Aprobada'), findsNothing);
      expect(find.text('Rechazada'), findsNothing);

      await tester.tap(find.text('Aprobar'));
      await tester.tap(find.text('Rechazar'));
      expect(aprobar, 1);
      expect(rechazar, 1);
    });

    for (final (estado, etiqueta) in [
      (EstadoSolicitud.aprobada, 'Aprobada'),
      (EstadoSolicitud.rechazada, 'Rechazada'),
    ]) {
      testWidgets('${estado.name}: etiqueta de su color y sin acciones', (
        tester,
      ) async {
        await tester.pumpWidget(_envolver(_tarjeta(estado: estado)));

        expect(find.text(etiqueta), findsOneWidget);
        // Una solicitud ya respondida no se vuelve a responder desde aca.
        expect(find.text('Aprobar'), findsNothing);
        expect(find.text('Rechazar'), findsNothing);
      });
    }
  });

  group('La regla de la pieza', () {
    testWidgets('sin nombre se lee "Inquilino interesado"', (tester) async {
      await tester.pumpWidget(_envolver(_tarjeta(inquilino: '')));

      expect(find.text('Inquilino interesado'), findsOneWidget);
    });

    testWidgets('un titulo larguisimo se corta y no agranda la tarjeta', (
      tester,
    ) async {
      Size medir() => tester.getSize(find.byType(TarjetaSolicitud));

      await tester.pumpWidget(_envolver(_tarjeta(titulo: 'Casa')));
      final corto = medir();

      await tester.pumpWidget(
        _envolver(
          _tarjeta(
            titulo: 'Habitación amplia con baño privado, cocina compartida y '
                'lavandería a aprox 40 min de la UAGRM',
          ),
        ),
      );
      expect(medir(), corto);

      final titulo = tester.widget<Text>(find.textContaining('Habitación amplia'));
      expect(titulo.maxLines, 1);
      expect(titulo.overflow, TextOverflow.ellipsis);
    });

    testWidgets('tocar la tarjeta abre el detalle', (tester) async {
      var abrir = 0;
      await tester.pumpWidget(
        _envolver(
          _tarjeta(estado: EstadoSolicitud.aprobada, alTocar: () => abrir++),
        ),
      );

      await tester.tap(find.text('Solicitud #3'));
      expect(abrir, 1);
    });
  });
}
