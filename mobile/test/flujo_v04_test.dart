import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/solicitudes_recibidas_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/solicitud_detalle_screen.dart';
import 'package:alquilamatch/features/propietario/presentation/solicitudes_recibidas_screen.dart';
import 'package:alquilamatch/features/propietario/providers/solicitudes_recibidas_provider.dart';
import 'package:alquilamatch/shared/layout/grilla.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_solicitud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Pruebas del flujo v0.4: la propietaria recibe una solicitud, decide y ve
/// el resultado.
///
/// Corren contra un repositorio en memoria, sin backend, con el tema real y en
/// dos pantallas: telefono 360 x 800 y escritorio 1440 x 900.

const _telefono = Size(360, 800);
const _escritorio = Size(1440, 900);

const _aviso = 'Esta persona va a ver tu WhatsApp. Sólo ella.';
const _aprobar = 'Aprobar y liberar mi WhatsApp';

SolicitudVisita _solicitud(
  int id,
  EstadoSolicitud estado, {
  DateTime? creada,
}) => SolicitudVisita(
  id: id,
  anuncio: Anuncio(
    id: id,
    titulo: 'Habitación a aprox 40 min de la UAGRM',
    tipoEspacio: TipoEspacio.habitacion,
    precioFinal: '650.00',
    aceptaMascotas: false,
    minutosCaminando: 40,
    estado: EstadoAnuncio.disponible,
    serviciosIncluidos: const {'agua': true, 'luz': true, 'internet': false},
  ),
  estado: estado,
  creadaEn: creada ?? DateTime(2026, 9, 8),
  inquilino: 'andrea',
  condicionesAceptadas: true,
);

/// Guarda las solicitudes en memoria y responde como lo haria el backend.
class _RepoFalso implements SolicitudesRecibidasRepository {
  _RepoFalso(List<SolicitudVisita> iniciales, {this.falla})
    : _datos = {for (final s in iniciales) s.id: s};

  final Map<int, SolicitudVisita> _datos;
  final ApiException? falla;

  @override
  Future<List<SolicitudVisita>> obtenerTodas() async {
    if (falla != null) throw falla!;
    return _datos.values.toList();
  }

  @override
  Future<SolicitudVisita> aprobar(int id) async =>
      _datos[id] = _cambiar(id, EstadoSolicitud.aprobada);

  @override
  Future<SolicitudVisita> rechazar(int id) async =>
      _datos[id] = _cambiar(id, EstadoSolicitud.rechazada);

  SolicitudVisita _cambiar(int id, EstadoSolicitud estado) {
    final s = _datos[id]!;
    return SolicitudVisita(
      id: s.id,
      anuncio: s.anuncio,
      estado: estado,
      creadaEn: s.creadaEn,
      inquilino: s.inquilino,
      condicionesAceptadas: s.condicionesAceptadas,
    );
  }
}

void _pantalla(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _montarDetalle(
  WidgetTester tester, {
  Size tamano = _telefono,
}) async {
  _pantalla(tester, tamano);
  final provider = SolicitudesRecibidasProvider(
    _RepoFalso([_solicitud(3, EstadoSolicitud.pendiente)]),
  );
  await provider.cargar();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: ChangeNotifierProvider.value(
        value: provider,
        child: const SolicitudDetalleScreen(id: 3),
      ),
    ),
  );
}

Future<void> _montarBandeja(
  WidgetTester tester,
  _RepoFalso repo, {
  Size tamano = _telefono,
}) async {
  _pantalla(tester, tamano);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: ChangeNotifierProvider(
        create: (_) => SolicitudesRecibidasProvider(repo),
        child: const SolicitudesRecibidasScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<int> _ordenEnPantalla(WidgetTester tester) => tester
    .widgetList<TarjetaSolicitud>(find.byType(TarjetaSolicitud))
    .map((t) => t.numero)
    .toList();

void main() {
  group('Pantallas 1, 2 y 3: decidir una solicitud', () {
    testWidgets('muestra el anuncio, lo que acepto y que pasa al aprobar', (
      tester,
    ) async {
      await _montarDetalle(tester);

      expect(find.text('Solicitud #3'), findsOneWidget);
      expect(find.text('Habitación a aprox 40 min de la UAGRM'), findsOneWidget);
      expect(find.text('Tipo: Habitación · 650 Bs/mes'), findsOneWidget);
      expect(find.text('Precio: 650 Bs/mes'), findsOneWidget);
      expect(find.text('Incluye agua y luz'), findsOneWidget);
      expect(find.text('Sin mascotas'), findsOneWidget);
      expect(find.text(_aviso), findsOneWidget);
      expect(find.text(_aprobar), findsOneWidget);
      expect(find.text('Rechazar'), findsOneWidget);
    });

    testWidgets('aprobar libera el contacto y la decision pasa a resultado', (
      tester,
    ) async {
      await _montarDetalle(tester);

      await tester.tap(find.text(_aprobar));
      await tester.pumpAndSettle();

      expect(find.text('Contacto liberado a andrea'), findsOneWidget);
      expect(find.text('Ahora puede escribirte por WhatsApp.'), findsOneWidget);
      expect(find.text('Volver a la bandeja'), findsOneWidget);
      // Ya respondida, no se puede volver a responder.
      expect(find.text(_aprobar), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
    });

    testWidgets('rechazar la cierra sin abrir conversacion', (tester) async {
      await _montarDetalle(tester);

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();

      expect(find.text('Solicitud rechazada y cerrada'), findsOneWidget);
      expect(find.text('Volver a la bandeja'), findsOneWidget);
      expect(find.text(_aprobar), findsNothing);
    });
  });

  group('Grid y Constraints en el detalle', () {
    testWidgets('telefono: todo a 12 columnas, la decision debajo', (
      tester,
    ) async {
      await _montarDetalle(tester);

      expect(tester.getSize(find.byType(Grilla12)).width, 312);
      expect(
        tester.getTopLeft(find.text(_aviso)).dy,
        greaterThan(tester.getBottomLeft(find.text('Sin mascotas')).dy),
      );
    });

    testWidgets('escritorio: condiciones en 8 columnas y decision en 4', (
      tester,
    ) async {
      await _montarDetalle(tester, tamano: _escritorio);

      // El contenido se detiene en 1200 y queda centrado.
      expect(tester.getSize(find.byType(Grilla12)).width, Grilla.anchoMaximo);
      // La decision queda a la derecha de las condiciones, no debajo.
      expect(
        tester.getTopLeft(find.text(_aviso)).dx,
        greaterThan(tester.getTopRight(find.text('Sin mascotas')).dx),
      );
      expect(
        tester.getTopLeft(find.text(_aviso)).dy,
        lessThan(tester.getBottomLeft(find.text('Sin mascotas')).dy),
      );
    });
  });

  group('Pantallas 0 y 4: la bandeja', () {
    testWidgets('las pendientes van primero, y en cada grupo la mas nueva', (
      tester,
    ) async {
      await _montarBandeja(
        tester,
        _RepoFalso([
          _solicitud(1, EstadoSolicitud.aprobada, creada: DateTime(2026, 8, 27)),
          _solicitud(2, EstadoSolicitud.rechazada, creada: DateTime(2026, 9, 3)),
          _solicitud(3, EstadoSolicitud.pendiente, creada: DateTime(2026, 9, 8)),
          _solicitud(4, EstadoSolicitud.pendiente, creada: DateTime(2026, 9, 1)),
        ]),
      );

      expect(_ordenEnPantalla(tester), [3, 4, 2, 1]);
    });

    testWidgets('aprobar desde la tarjeta abre el detalle, no aprueba a ciegas', (
      tester,
    ) async {
      await _montarBandeja(
        tester,
        _RepoFalso([_solicitud(3, EstadoSolicitud.pendiente)]),
      );

      await tester.tap(find.text('Aprobar'));
      await tester.pumpAndSettle();

      expect(find.text(_aviso), findsOneWidget);
      expect(find.text(_aprobar), findsOneWidget);
    });

    testWidgets('rechazar desde la tarjeta la marca sin salir de la bandeja', (
      tester,
    ) async {
      await _montarBandeja(
        tester,
        _RepoFalso([_solicitud(3, EstadoSolicitud.pendiente)]),
      );

      await tester.tap(find.text('Rechazar'));
      await tester.pumpAndSettle();

      expect(find.text('Rechazada'), findsOneWidget);
      expect(find.text('Rechazar'), findsNothing);
      expect(find.text('Gestionar Solicitudes'), findsOneWidget);
    });

    testWidgets('sin solicitudes lo dice (pantalla 4)', (tester) async {
      await _montarBandeja(tester, _RepoFalso([]));

      expect(find.text('Aún no tenés solicitudes'), findsOneWidget);
      expect(find.byType(TarjetaSolicitud), findsNothing);
    });

    testWidgets('si no carga, no dice que no hay solicitudes', (tester) async {
      await _montarBandeja(
        tester,
        _RepoFalso(
          [],
          falla: ApiException('No se pudo conectar con el servidor.'),
        ),
      );

      expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Aún no tenés solicitudes'), findsNothing);
    });

    testWidgets('escritorio: tres tarjetas por fila, del mismo ancho', (
      tester,
    ) async {
      await _montarBandeja(
        tester,
        _RepoFalso([
          for (var i = 1; i <= 4; i++)
            _solicitud(
              i,
              EstadoSolicitud.aprobada,
              creada: DateTime(2026, 9, i),
            ),
        ]),
        tamano: _escritorio,
      );

      final tarjetas = find.byType(TarjetaSolicitud);
      final rects = [
        for (var i = 0; i < 4; i++) tester.getRect(tarjetas.at(i)),
      ];
      expect(rects[0].top, rects[1].top);
      expect(rects[1].top, rects[2].top);
      expect(rects[3].top, greaterThan(rects[0].bottom));
      expect(rects[0].width, rects[2].width);
    });
  });
}
