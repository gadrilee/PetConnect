import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/acceso/data/auth_repository.dart';
import 'package:alquilamatch/features/acceso/data/perfil.dart';
import 'package:alquilamatch/features/acceso/presentation/elegir_rol_screen.dart';
import 'package:alquilamatch/features/acceso/presentation/login_screen.dart';
import 'package:alquilamatch/features/acceso/presentation/registro_screen.dart';
import 'package:alquilamatch/features/acceso/providers/auth_provider.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/anuncio_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/buscar_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/inicio_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/mis_solicitudes_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/resultados_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/solicitar_visita_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/solicitud_estado_screen.dart';
import 'package:alquilamatch/features/inquilina/providers/buscar_provider.dart';
import 'package:alquilamatch/features/inquilina/providers/mis_solicitudes_provider.dart';
import 'package:alquilamatch/features/inquilina/providers/solicitud_provider.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/anuncios_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/inicio_screen.dart';
import 'package:alquilamatch/features/propietario/presentation/mis_anuncios_screen.dart';
import 'package:alquilamatch/features/propietario/presentation/publicar_screen.dart';
import 'package:alquilamatch/features/propietario/providers/mis_anuncios_provider.dart';
import 'package:alquilamatch/features/propietario/providers/publicar_provider.dart';
import 'package:alquilamatch/shared/layout/pagina.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:alquilamatch/shared/widgets/resumen_busqueda.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Todas las pantallas de todos los flujos, en telefono, tablet y escritorio.
///
/// Corren sin backend, con repositorios en memoria y el tema real. La regla es
/// la de la Clase 8: responsive no es achicar. Ninguna pantalla puede desbordar
/// en ningun tamano, y los bloques cambian de fila en vez de aplastarse.

const _tamanos = <String, Size>{
  'telefono': Size(360, 800),
  'tablet': Size(768, 1024),
  'escritorio': Size(1440, 900),
};

const _anuncio = Anuncio(
  id: 1,
  titulo: 'Departamento céntrico de un dormitorio con baño privado',
  tipoEspacio: TipoEspacio.departamento,
  precioFinal: '1250.00',
  aceptaMascotas: true,
  minutosCaminando: 12,
  estado: EstadoAnuncio.disponible,
  serviciosIncluidos: {'agua': true, 'luz': false, 'internet': true},
  restricciones: 'Sin fiestas después de las 22',
);

const _inquilina = Perfil(username: 'andrea', rol: Rol.inquilino);
const _propietaria = Perfil(
  username: 'marta',
  rol: Rol.propietario,
  whatsapp: '70011122',
);

SolicitudVisita _solicitud(EstadoSolicitud estado, {String? contacto}) =>
    SolicitudVisita(
      id: 7,
      anuncio: _anuncio,
      estado: estado,
      creadaEn: DateTime(2026, 9, 8),
      inquilino: 'andrea',
      condicionesAceptadas: true,
      contacto: contacto,
    );

class _Solicitudes extends Fake implements SolicitudesRepository {
  @override
  Future<List<Anuncio>> buscar({
    double? precioMax,
    TipoEspacio? tipoEspacio,
    bool? aceptaMascotas,
    int? minutosMax,
  }) async => [_anuncio, _anuncio];

  @override
  Future<Anuncio> detalle(int id) async => _anuncio;

  @override
  Future<List<SolicitudVisita>> misSolicitudes() async => [
    _solicitud(EstadoSolicitud.pendiente),
    _solicitud(EstadoSolicitud.aprobada),
  ];
}

class _Anuncios extends Fake implements AnunciosRepository {
  @override
  Future<List<Anuncio>> mios() async => const [
    _anuncio,
    Anuncio(
      id: 2,
      titulo: 'Casa con patio',
      tipoEspacio: TipoEspacio.casa,
      precioFinal: '3000',
      aceptaMascotas: false,
      minutosCaminando: 35,
      estado: EstadoAnuncio.alquilado,
    ),
  ];
}

class _Auth extends Fake implements AuthRepository {
  _Auth(this.perfil);

  final Perfil perfil;

  @override
  Future<Perfil> login({
    required String username,
    required String password,
  }) async => perfil;
}

class _Caso {
  const _Caso(this.nombre, this.pantalla, {this.perfil});

  final String nombre;
  final Future<Widget> Function() pantalla;

  /// Con quien se entra. `null` es sin sesion.
  final Perfil? perfil;
}

final _casos = <_Caso>[
  _Caso('Ingresar', () async => const LoginScreen()),
  _Caso('Elegir rol', () async => const ElegirRolScreen()),
  _Caso(
    'Crear cuenta',
    () async => const RegistroScreen(rol: Rol.propietario),
  ),
  _Caso(
    'Inicio de la inquilina',
    () async => const InicioInquilinaScreen(),
    perfil: _inquilina,
  ),
  _Caso(
    'Inicio de la propietaria',
    () async => const InicioPropietarioScreen(),
    perfil: _propietaria,
  ),
  _Caso('Buscar', () async => const BuscarScreen()),
  _Caso('Resultados', () async {
    final provider = BuscarProvider(_Solicitudes());
    await provider.buscar(
      const FiltrosBusqueda(precioMax: 1500, minutosMax: 20),
    );
    return ChangeNotifierProvider.value(
      value: provider,
      child: const ResultadosScreen(),
    );
  }),
  _Caso('Anuncio', () async => const AnuncioScreen(anuncioId: 1)),
  _Caso(
    'Solicitar visita',
    () async => ChangeNotifierProvider(
      create: (_) => SolicitudProvider(_Solicitudes()),
      child: const SolicitarVisitaScreen(anuncio: _anuncio),
    ),
  ),
  _Caso(
    'Solicitud enviada',
    () async => ChangeNotifierProvider(
      create: (_) => SolicitudProvider(_Solicitudes())
        ..setSolicitud(_solicitud(EstadoSolicitud.pendiente)),
      child: const SolicitudEstadoScreen(),
    ),
  ),
  _Caso(
    'Contacto liberado',
    () async => ChangeNotifierProvider(
      create: (_) => SolicitudProvider(_Solicitudes())
        ..setSolicitud(
          _solicitud(EstadoSolicitud.aprobada, contacto: 'Marta · 70011122'),
        ),
      child: const SolicitudEstadoScreen(),
    ),
  ),
  _Caso(
    'Estado de solicitudes',
    () async => ChangeNotifierProvider(
      create: (_) => MisSolicitudesProvider(_Solicitudes()),
      child: const MisSolicitudesScreen(),
    ),
  ),
  _Caso('Mis anuncios', () async => const MisAnunciosScreen()),
  _Caso(
    'Publicar',
    () async => ChangeNotifierProvider(
      create: (_) => PublicarProvider(_Anuncios()),
      child: const PublicarScreen(),
    ),
  ),
];

_Caso _caso(String nombre) => _casos.firstWhere((c) => c.nombre == nombre);

Future<void> _montar(WidgetTester tester, Size tamano, _Caso caso) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final auth = AuthProvider(_Auth(caso.perfil ?? _inquilina));
  if (caso.perfil != null) {
    await auth.login(username: caso.perfil!.username, password: 'prueba');
  }
  final anuncios = _Anuncios();
  final pantalla = await caso.pantalla();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<SolicitudesRepository>.value(value: _Solicitudes()),
        Provider<AnunciosRepository>.value(value: anuncios),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => MisAnunciosProvider(anuncios)),
      ],
      child: MaterialApp(theme: AppTheme.claro, home: pantalla),
    ),
  );
  await tester.pumpAndSettle();
}

List<Rect> _rectsDe(WidgetTester tester, Finder finder) => [
  for (var i = 0; i < finder.evaluate().length; i++)
    tester.getRect(finder.at(i)),
];

void main() {
  group('Cada pantalla se arma sobre Pagina y no desborda', () {
    for (final caso in _casos) {
      for (final MapEntry(key: nombre, value: tamano) in _tamanos.entries) {
        testWidgets('${caso.nombre} en $nombre', (tester) async {
          await _montar(tester, tamano, caso);

          expect(tester.takeException(), isNull);
          expect(find.byType(Pagina), findsOneWidget);
        });
      }
    }
  });

  group('GRID: los bloques cambian de fila, no se achican', () {
    testWidgets('Buscar: "Tu búsqueda" debajo en telefono, al lado en escritorio', (
      tester,
    ) async {
      await _montar(tester, _tamanos['telefono']!, _caso('Buscar'));
      var filtros = tester.getRect(find.byType(CampoTexto));
      var resumen = tester.getRect(find.byType(ResumenBusqueda));
      expect(resumen.top, greaterThan(filtros.bottom));
      expect(resumen.width, filtros.width);

      await _montar(tester, _tamanos['escritorio']!, _caso('Buscar'));
      filtros = tester.getRect(find.byType(CampoTexto));
      resumen = tester.getRect(find.byType(ResumenBusqueda));
      expect(resumen.left, greaterThan(filtros.right));
      expect(resumen.top, filtros.top);
    });

    testWidgets('Inicio de la propietaria: una opcion por fila en telefono, '
        'tres en escritorio', (tester) async {
      final caso = _caso('Inicio de la propietaria');

      await _montar(tester, _tamanos['telefono']!, caso);
      var menus = _rectsDe(tester, find.byType(TarjetaMenu));
      expect(menus, hasLength(3));
      expect(menus[1].top, greaterThan(menus[0].bottom));

      await _montar(tester, _tamanos['escritorio']!, caso);
      menus = _rectsDe(tester, find.byType(TarjetaMenu));
      expect(menus[1].top, menus[0].top);
      expect(menus[2].top, menus[0].top);
      expect(menus[0].width, menus[2].width);
    });
  });
}
