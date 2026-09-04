import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/anuncios/data/anuncio.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_anuncio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas de la tarjeta de anuncio compartida.
///
/// La que mas importa es la ultima: fija que **los dos tamanos digan que cubre
/// el precio**. Ese dato falto en una de las dos copias durante semanas, y es
/// exactamente el defecto que encontro la prueba con usuaria.

Anuncio _anuncio({
  bool agua = true,
  bool luz = true,
  bool internet = true,
  String titulo = 'Habitación cerca de la UAGRM',
}) => Anuncio(
  id: 1,
  titulo: titulo,
  precioFinal: '1000',
  minutosCaminando: 9,
  aceptaMascotas: true,
  tipoEspacio: TipoEspacio.habitacion,
  restricciones: '',
  direccionReferencia: '',
  estado: EstadoAnuncio.disponible,
  serviciosIncluidos: {'agua': agua, 'luz': luz, 'internet': internet},
  fotos: const [],
);

/// Se usa el tema REAL de la app y el ancho real del contenido (312 = 360 de
/// pantalla menos los dos margenes de 24).
///
/// Con el tema por defecto de Material los textos salen mas grandes que en la
/// app, asi que la tarjeta desbordaba en la prueba y en ningun telefono. Una
/// prueba que corre bajo una configuracion que no existe no prueba nada.
Widget _envolver(Widget hijo) => MaterialApp(
  theme: AppTheme.claro,
  home: Scaffold(
    body: Center(child: SizedBox(width: 312, child: hijo)),
  ),
);

void main() {
  group('Los dos tamaños', () {
    testWidgets('completa: alcanza para descartar sin abrir el anuncio', (
      tester,
    ) async {
      await tester.pumpWidget(_envolver(TarjetaAnuncio(anuncio: _anuncio())));

      expect(find.text('1000 Bs / mes'), findsOneWidget);
      expect(find.text('todo incluido'), findsOneWidget);
      expect(find.text('9 min caminando a la UAGRM'), findsOneWidget);
    });

    testWidgets('compacta: el precio y lo que cubre van en una línea', (
      tester,
    ) async {
      await tester.pumpWidget(
        _envolver(
          TarjetaAnuncio(anuncio: _anuncio(), tamano: TamanoTarjeta.compacta),
        ),
      );

      expect(find.text('1000 Bs / mes · todo incluido'), findsOneWidget);
    });

    testWidgets('la flecha solo aparece si se puede entrar', (tester) async {
      await tester.pumpWidget(_envolver(TarjetaAnuncio(anuncio: _anuncio())));
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.pumpWidget(
        _envolver(TarjetaAnuncio(anuncio: _anuncio(), alTocar: () {})),
      );
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('se toca y responde', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        _envolver(TarjetaAnuncio(anuncio: _anuncio(), alTocar: () => toques++)),
      );

      await tester.tap(find.byType(TarjetaAnuncio));
      expect(toques, 1);
    });
  });

  group('La regla de la pieza', () {
    testWidgets('no desborda en un teléfono real', (tester) async {
      // El tamano de un telefono de gama baja, que es el que van a usar. La
      // tarjeta llego a tener un alto FIJO y desbordaba 14 px aca: en debug
      // salen las rayas amarillas, en release el texto queda cortado. Con una
      // superficie de prueba mas ancha el defecto no se ve.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final tamano in TamanoTarjeta.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.claro,
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TarjetaAnuncio(
                    anuncio: _anuncio(
                      titulo: 'Departamento céntrico de 1 dormitorio',
                      luz: false,
                    ),
                    tamano: tamano,
                    alTocar: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'el tamaño $tamano desborda en 360 de ancho',
        );
      }
    });

    testWidgets('ningún tamaño muestra el precio sin decir qué cubre', (
      tester,
    ) async {
      // El defecto real: la copia de la solicitud mostraba "1.000 Bs / mes" a
      // secas. Un monto sin decir que incluye no significa nada — es lo que
      // obligo a la usuaria a preguntar "¿cuanto es con luz?".
      for (final tamano in TamanoTarjeta.values) {
        await tester.pumpWidget(
          _envolver(
            TarjetaAnuncio(anuncio: _anuncio(luz: false), tamano: tamano),
          ),
        );

        final textos = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' | ');

        expect(
          textos.contains('luz no'),
          isTrue,
          reason:
              'el tamaño $tamano no dice que la luz NO está incluida:\n'
              '$textos',
        );
      }
    });

    testWidgets('lo que NO está incluido se nombra, no se omite', (
      tester,
    ) async {
      // Omitirlo impide distinguir "no entra en el precio" de "no lo dijeron".
      await tester.pumpWidget(
        _envolver(
          TarjetaAnuncio(
            anuncio: _anuncio(agua: true, luz: false, internet: false),
          ),
        ),
      );

      expect(find.text('incluye agua · luz y internet no'), findsOneWidget);
    });
  });
}
