import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/anuncio_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/resultados_screen.dart';
import 'package:alquilamatch/features/inquilina/providers/buscar_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:flutter/material.dart';
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
    return _anuncio;
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
}
