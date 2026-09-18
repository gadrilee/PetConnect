import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/solicitud_estado_screen.dart';
import 'package:alquilamatch/features/inquilina/providers/solicitud_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/anuncios_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/confirmar_alquilado_screen.dart';
import 'package:alquilamatch/features/propietario/presentation/mis_anuncios_screen.dart';
import 'package:alquilamatch/features/propietario/providers/mis_anuncios_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pruebas del flujo v0.5: la propietaria marca el cuarto como alquilado.
///
/// Sin solicitudes pendientes es un toque. Con pendientes, antes se dice que
/// se van a cerrar. Del otro lado, la inquilina ve su solicitud cerrada en vez
/// de quedarse esperando.

const _marcar = 'Marcar Ya alquilado';

Anuncio _anuncio(int id, {int pendientes = 0, bool alquilado = false}) => Anuncio(
  id: id,
  titulo: 'Habitación a aprox 10 min de la UAGRM',
  tipoEspacio: TipoEspacio.habitacion,
  precioFinal: '2000.00',
  aceptaMascotas: true,
  minutosCaminando: 11,
  estado: alquilado ? EstadoAnuncio.alquilado : EstadoAnuncio.disponible,
  solicitudesPendientes: pendientes,
);

/// Guarda los anuncios en memoria y responde como el backend: marcar
/// alquilado cierra las pendientes y dice cuantas.
class _Repo extends Fake implements AnunciosRepository {
  _Repo(List<Anuncio> iniciales) : _datos = {for (final a in iniciales) a.id: a};

  final Map<int, Anuncio> _datos;
  ApiException? falla;

  Anuncio _con(Anuncio a, EstadoAnuncio estado) => Anuncio(
    id: a.id,
    titulo: a.titulo,
    tipoEspacio: a.tipoEspacio,
    precioFinal: a.precioFinal,
    aceptaMascotas: a.aceptaMascotas,
    minutosCaminando: a.minutosCaminando,
    estado: estado,
  );

  @override
  Future<List<Anuncio>> mios() async => _datos.values.toList();

  @override
  Future<({Anuncio anuncio, int cerradas})> marcarAlquilado(int id) async {
    if (falla != null) throw falla!;
    final antes = _datos[id]!;
    _datos[id] = _con(antes, EstadoAnuncio.alquilado);
    return (anuncio: _datos[id]!, cerradas: antes.solicitudesPendientes);
  }

  @override
  Future<Anuncio> marcarDisponible(int id) async {
    if (falla != null) throw falla!;
    return _datos[id] = _con(_datos[id]!, EstadoAnuncio.disponible);
  }
}

Future<_Repo> _montar(WidgetTester tester, List<Anuncio> anuncios) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = _Repo(anuncios);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: ChangeNotifierProvider(
        create: (_) => MisAnunciosProvider(repo),
        child: const MisAnunciosScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('Marcar Ya alquilado', () {
    testWidgets('sin pendientes: es un toque, sin confirmación', (tester) async {
      await _montar(tester, [_anuncio(1)]);

      await tester.tap(find.text(_marcar));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmarAlquiladoScreen), findsNothing);
      expect(find.text('Ya alquilado'), findsOneWidget);
      expect(find.text('Salió de la búsqueda.'), findsOneWidget);
    });

    testWidgets('con pendientes: primero dice que se van a cerrar', (tester) async {
      await _montar(tester, [_anuncio(1, pendientes: 2)]);

      await tester.tap(find.text(_marcar));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmarAlquiladoScreen), findsOneWidget);
      expect(find.text('Se cierran las 2 solicitudes que tenías pendientes.'),
          findsOneWidget);
      expect(find.text('Sale de la búsqueda: nadie más lo va a encontrar.'),
          findsOneWidget);
    });

    testWidgets('cancelar no cambia nada', (tester) async {
      await _montar(tester, [_anuncio(1, pendientes: 2)]);
      await tester.tap(find.text(_marcar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmarAlquiladoScreen), findsNothing);
      expect(find.text('Disponible'), findsOneWidget);
    });

    testWidgets('confirmar lo marca y cuenta cuántas solicitudes cerró',
        (tester) async {
      await _montar(tester, [_anuncio(1, pendientes: 2)]);
      await tester.tap(find.text(_marcar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MARCAR YA ALQUILADO'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmarAlquiladoScreen), findsNothing);
      expect(find.text('Ya alquilado'), findsOneWidget);
      expect(
        find.text('Salió de la búsqueda. Cerramos 2 solicitudes y les avisamos.'),
        findsOneWidget,
      );
    });

    testWidgets('si falla, se queda en la confirmación con el error en el pie',
        (tester) async {
      final repo = await _montar(tester, [_anuncio(1, pendientes: 1)]);
      await tester.tap(find.text(_marcar));
      await tester.pumpAndSettle();

      repo.falla = ApiException('No se pudo conectar con el servidor.');
      await tester.tap(find.text('MARCAR YA ALQUILADO'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmarAlquiladoScreen), findsOneWidget);
      expect(
        find.text('No se pudo marcar como alquilado. Revisá tu conexión y probá de nuevo.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Volver a publicar: vuelve a la búsqueda en un toque', (tester) async {
    await _montar(tester, [_anuncio(1, alquilado: true)]);

    await tester.tap(find.text('Volver a publicar'));
    await tester.pumpAndSettle();

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Volvió a la búsqueda. Ya pueden encontrarlo de nuevo.'),
        findsOneWidget);
  });

  testWidgets('La inquilina ve su solicitud cerrada, no una espera eterna',
      (tester) async {
    final provider = SolicitudProvider(_SolicitudesSinUso())
      ..setSolicitud(
        SolicitudVisita(
          id: 7,
          anuncio: _anuncio(1, alquilado: true),
          estado: EstadoSolicitud.cerrada,
          creadaEn: DateTime(2026, 9, 18),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const SolicitudEstadoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('El cuarto ya se alquiló'), findsOneWidget);
    expect(find.text('Cerrada'), findsOneWidget);
    // Nada de "el propietario tiene que aceptar": nadie va a responder.
    expect(find.textContaining('tiene que aceptar'), findsNothing);
    expect(find.text('ACTUALIZAR ESTADO'), findsNothing);
  });
}

class _SolicitudesSinUso extends Fake implements SolicitudesRepository {}
