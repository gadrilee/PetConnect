import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/anuncio_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/buscar_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/resultados_screen.dart';
import 'package:alquilamatch/features/inquilina/providers/buscar_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/shared/widgets/controles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Buscar sin encontrar nada y el anuncio que no carga (Figma, flujo de la
/// inquilina: Principal 04 Sin resultados y Validaciones 07).

const _anuncio = Anuncio(
  id: 1,
  titulo: 'Habitación con baño privado',
  tipoEspacio: TipoEspacio.habitacion,
  precioFinal: '1000.00',
  aceptaMascotas: true,
  minutosCaminando: 9,
  estado: EstadoAnuncio.disponible,
);

class _Repo extends Fake implements SolicitudesRepository {
  List<Anuncio> encontrados = const [];
  ApiException? falla;

  /// Que devuelve el detalle. Se cambia para probar el anuncio que sabe donde
  /// queda y el que no.
  Anuncio detalleDevuelto = _anuncio;

  @override
  Future<List<Anuncio>> buscar({
    double? precioMax,
    TipoEspacio? tipoEspacio,
    bool? aceptaMascotas,
    int? minutosMax,
  }) async {
    if (falla != null) throw falla!;
    return encontrados;
  }

  @override
  Future<Anuncio> detalle(int id) async {
    if (falla != null) throw falla!;
    return detalleDevuelto;
  }
}

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Sin resultados: la búsqueda salió bien y lo dice', (tester) async {
    _telefono(tester);
    final provider = BuscarProvider(_Repo());
    await provider.buscar(const FiltrosBusqueda(precioMax: 300));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: ChangeNotifierProvider.value(value: provider, child: const ResultadosScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No encontramos anuncios\ncon esos filtros.'), findsOneWidget);
    expect(find.text('Probá ampliando el precio o los minutos.'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing,
        reason: 'no falló nada: no hay que reintentar, hay que cambiar filtros');
  });

  testWidgets('El anuncio que no carga: qué pasó, qué hacer y Reintentar',
      (tester) async {
    _telefono(tester);
    final repo = _Repo()..falla = ApiException('No se pudo conectar con el servidor.');
    await tester.pumpWidget(
      Provider<SolicitudesRepository>.value(
        value: repo,
        child: MaterialApp(
          theme: AppTheme.claro,
          home: const AnuncioScreen(anuncioId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar el anuncio'), findsOneWidget);
    expect(find.text(ApiException.sinRespuesta), findsOneWidget);
    expect(find.textContaining('servidor'), findsNothing);

    repo.falla = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Habitación con baño privado'), findsOneWidget);
  });

  group('La ubicación lleva al mapa', () {
    /// El anuncio con la zona y el punto donde queda, como lo manda el
    /// detalle de la API.
    const conUbicacion = Anuncio(
      id: 1,
      titulo: 'Habitación con baño privado',
      tipoEspacio: TipoEspacio.habitacion,
      precioFinal: '1000.00',
      aceptaMascotas: true,
      minutosCaminando: 9,
      estado: EstadoAnuncio.disponible,
      direccionReferencia: 'Panamericano',
      lat: -17.77712,
      lng: -63.19035,
    );

    /// Lo que el aparato contesta cuando la app le pide abrir un enlace, y la
    /// lista de lo que le pidio.
    List<MethodCall> escucharAlAparato(WidgetTester tester, {bool abre = true}) {
      const canal = MethodChannel('plugins.flutter.io/url_launcher');
      final llamadas = <MethodCall>[];
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(canal, (llamada) async {
        llamadas.add(llamada);
        return abre;
      });
      addTearDown(() => mensajero.setMockMethodCallHandler(canal, null));
      return llamadas;
    }

    Future<void> montar(WidgetTester tester, _Repo repo) async {
      _telefono(tester);
      await tester.pumpWidget(
        Provider<SolicitudesRepository>.value(
          value: repo,
          child: MaterialApp(
            theme: AppTheme.claro,
            home: const AnuncioScreen(anuncioId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tocar la zona abre Google Maps en donde queda', (tester) async {
      final llamadas = escucharAlAparato(tester);
      await montar(tester, _Repo()..detalleDevuelto = conUbicacion);

      expect(find.text('Panamericano · Ver en el mapa'), findsOneWidget);
      await tester.tap(find.text('Panamericano · Ver en el mapa'));
      await tester.pumpAndSettle();

      expect(llamadas.single.arguments['url'],
          'https://www.google.com/maps/search/?api=1&query=-17.77712,-63.19035');
    });

    testWidgets('sin el punto no promete un mapa: dice lo que decía antes',
        (tester) async {
      // Los resultados de la busqueda no traen lat/lng. Si el detalle tampoco
      // los manda, el aviso informa y ya: no hay flecha ni toque que no lleve
      // a ningun lado.
      await montar(tester, _Repo());

      expect(find.textContaining('visible al aprobar la solicitud'),
          findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('si el aparato no abre el mapa, lo dice en el pie', (tester) async {
      escucharAlAparato(tester, abre: false);
      await montar(tester, _Repo()..detalleDevuelto = conUbicacion);

      await tester.tap(find.text('Panamericano · Ver en el mapa'));
      await tester.pumpAndSettle();

      expect(find.text(AnuncioScreen.noSeAbrioElMapa), findsOneWidget);
      // El anuncio sigue ahi: no se pudo abrir el mapa, no se cayo la app.
      expect(find.text('SOLICITAR VISITA'), findsOneWidget);
    });
  });

  testWidgets('Tipo de espacio: las tres opciones miden lo mismo', (tester) async {
    _telefono(tester);
    await tester.pumpWidget(
      Provider<SolicitudesRepository>.value(
        value: _Repo(),
        child: MaterialApp(theme: AppTheme.claro, home: const BuscarScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // La fila reparte el ancho: "Casa" mide lo mismo que "Departamento" en vez
    // de encogerse a su palabra, como en Figma y como en Publicar.
    expect(find.byType(FilaOpciones), findsOneWidget);
    final casa = tester.getSize(find.widgetWithText(Opcion, 'Casa'));
    final depto = tester.getSize(find.widgetWithText(Opcion, 'Departamento'));
    final habitacion = tester.getSize(find.widgetWithText(Opcion, 'Habitación'));
    expect(casa.width, closeTo(depto.width, 0.01));
    expect(habitacion.width, closeTo(depto.width, 0.01));
  });
}
