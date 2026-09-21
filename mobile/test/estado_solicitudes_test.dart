import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/mis_solicitudes_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/solicitud_estado_screen.dart';
import 'package:alquilamatch/features/inquilina/providers/mis_solicitudes_provider.dart';
import 'package:alquilamatch/features/inquilina/providers/solicitud_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/anuncios_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/mis_anuncios_screen.dart';
import 'package:alquilamatch/features/propietario/providers/mis_anuncios_provider.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_historial.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Estado de solicitudes, del lado de la inquilina: la lista de lo que mandó
/// y el estado de cada una (Figma, flujo de la inquilina: Principal 07-11,
/// Happy Path 09 y Validaciones 09-11).

const _anuncio = Anuncio(
  id: 1,
  titulo: 'Habitación con baño privado',
  tipoEspacio: TipoEspacio.habitacion,
  precioFinal: '1000.00',
  aceptaMascotas: true,
  minutosCaminando: 9,
  estado: EstadoAnuncio.disponible,
);

SolicitudVisita _solicitud(
  int id,
  EstadoSolicitud estado, {
  int dia = 12,
  String? contacto,
}) =>
    SolicitudVisita(
      id: id,
      anuncio: _anuncio,
      estado: estado,
      creadaEn: DateTime(2026, 9, dia),
      contacto: contacto,
    );

/// Sin conexión: el ApiClient tira la excepción sin código.
final _sinConexion = ApiException('No se pudo conectar con el servidor.');

class _Repo extends Fake implements SolicitudesRepository {
  _Repo([this.lista = const []]);

  List<SolicitudVisita> lista;
  ApiException? falla;

  /// Lo que devuelve al actualizar una solicitud: lo que decidió el dueño.
  SolicitudVisita? actualizada;

  @override
  Future<List<SolicitudVisita>> misSolicitudes() async {
    if (falla != null) throw falla!;
    return lista;
  }

  @override
  Future<SolicitudVisita> solicitud(int id) async {
    if (falla != null) throw falla!;
    return actualizada ?? lista.firstWhere((s) => s.id == id);
  }
}

void _telefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _lista(WidgetTester tester, _Repo repo) async {
  _telefono(tester);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SolicitudesRepository>.value(value: repo),
        ChangeNotifierProvider(create: (_) => MisSolicitudesProvider(repo)),
      ],
      child: MaterialApp(theme: AppTheme.claro, home: const MisSolicitudesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _estado(WidgetTester tester, _Repo repo, SolicitudVisita s) async {
  _telefono(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro,
      home: ChangeNotifierProvider(
        create: (_) => SolicitudProvider(repo)..setSolicitud(s),
        child: const SolicitudEstadoScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Estado de solicitudes', () {
    testWidgets('las más nuevas primero, cada una con su etiqueta', (tester) async {
      await _lista(
        tester,
        _Repo([
          _solicitud(4, EstadoSolicitud.pendiente, dia: 12),
          _solicitud(3, EstadoSolicitud.aprobada, dia: 10),
          _solicitud(2, EstadoSolicitud.rechazada, dia: 8),
          _solicitud(1, EstadoSolicitud.cerrada, dia: 3),
        ]),
      );

      expect(find.byType(TarjetaHistorial), findsNWidgets(4));
      for (final etiqueta in ['Pendiente', 'Aprobada', 'Rechazada', 'Cerrada']) {
        expect(find.text(etiqueta), findsOneWidget);
      }
      final fechas = tester
          .widgetList<TarjetaHistorial>(find.byType(TarjetaHistorial))
          .map((t) => t.enviada.day)
          .toList();
      expect(fechas, [12, 10, 8, 3]);
      expect(find.text('Enviada: 12/9'), findsOneWidget);
    });

    testWidgets('sin solicitudes: lo dice en vez de mostrar una lista vacía',
        (tester) async {
      await _lista(tester, _Repo());
      expect(find.text('Aún no enviaste solicitudes'), findsOneWidget);
    });

    testWidgets('si no carga: el título, qué hacer y Reintentar; nunca "vacía"',
        (tester) async {
      final repo = _Repo([_solicitud(1, EstadoSolicitud.pendiente)])..falla = _sinConexion;
      await _lista(tester, repo);

      expect(find.text('No pudimos cargar tus solicitudes'), findsOneWidget);
      expect(find.text(ApiException.sinRespuesta), findsOneWidget);
      expect(find.textContaining('servidor'), findsNothing,
          reason: 'el texto de la API es para quien programa');
      expect(find.text('Aún no enviaste solicitudes'), findsNothing);

      repo.falla = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.byType(TarjetaHistorial), findsOneWidget);
    });

    testWidgets('si el servidor responde con un motivo, se dice ese motivo',
        (tester) async {
      final repo = _Repo()..falla = ApiException('No tenés permiso para hacer esto.', codigo: 403);
      await _lista(tester, repo);
      expect(find.text('No tenés permiso para hacer esto.'), findsOneWidget);
    });

    testWidgets('tocar una solicitud abre su estado', (tester) async {
      await _lista(tester, _Repo([_solicitud(2, EstadoSolicitud.rechazada)]));

      await tester.tap(find.byType(TarjetaHistorial));
      await tester.pumpAndSettle();

      expect(find.byType(SolicitudEstadoScreen), findsOneWidget);
      expect(
        find.text('El propietario rechazó la solicitud. Podés buscar otros anuncios.'),
        findsOneWidget,
      );
    });
  });

  group('El estado de una solicitud', () {
    testWidgets('rechazada: lo dice, y no hay nada que actualizar', (tester) async {
      await _estado(tester, _Repo(), _solicitud(2, EstadoSolicitud.rechazada));

      expect(find.text('Solicitud rechazada'), findsWidgets);
      expect(find.text('ACTUALIZAR ESTADO'), findsNothing);
      expect(find.text('VOLVER A LOS RESULTADOS'), findsOneWidget);
    });

    testWidgets('actualizar y ya la aprobaron: aparece el contacto', (tester) async {
      final repo = _Repo()
        ..actualizada = _solicitud(4, EstadoSolicitud.aprobada, contacto: 'Marta · 70011122');
      await _estado(tester, repo, _solicitud(4, EstadoSolicitud.pendiente));

      await tester.tap(find.text('ACTUALIZAR ESTADO'));
      await tester.pumpAndSettle();

      expect(find.text('ABRIR WHATSAPP'), findsOneWidget);
    });

    testWidgets('actualizar sin conexión: el aviso en el pie, y se puede reintentar',
        (tester) async {
      final repo = _Repo()..falla = _sinConexion;
      await _estado(tester, repo, _solicitud(4, EstadoSolicitud.pendiente));

      await tester.tap(find.text('ACTUALIZAR ESTADO'));
      await tester.pumpAndSettle();

      expect(find.text(SolicitudProvider.noSeActualizo), findsOneWidget);
      expect(find.text('ACTUALIZAR ESTADO'), findsOneWidget);
    });

    testWidgets('si el teléfono no abre WhatsApp, lo dice en el pie', (tester) async {
      // El teléfono contesta "no pude abrir el enlace": es lo que pasa sin
      // WhatsApp ni navegador que lo abra.
      const canal = MethodChannel('plugins.flutter.io/url_launcher');
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(canal, (_) async => false);
      addTearDown(() => mensajero.setMockMethodCallHandler(canal, null));

      await _estado(
        tester,
        _Repo(),
        _solicitud(4, EstadoSolicitud.aprobada, contacto: 'Marta · 70011122'),
      );

      await tester.tap(find.text('ABRIR WHATSAPP'));
      await tester.pumpAndSettle();

      expect(find.text(SolicitudEstadoScreen.noSeAbrioWhatsApp), findsOneWidget);
    });
  });

  testWidgets('Mis anuncios que no cargan dicen qué hacer, como en Figma',
      (tester) async {
    _telefono(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: ChangeNotifierProvider(
          create: (_) => MisAnunciosProvider(_AnunciosSinConexion()),
          child: const MisAnunciosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus anuncios'), findsOneWidget);
    expect(find.text(ApiException.sinRespuesta), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

class _AnunciosSinConexion extends Fake implements AnunciosRepository {
  @override
  Future<List<Anuncio>> mios() async => throw _sinConexion;
}
