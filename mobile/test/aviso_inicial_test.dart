import 'package:alquilamatch/features/acceso/data/auth_repository.dart';
import 'package:alquilamatch/features/acceso/data/perfil.dart';
import 'package:alquilamatch/features/acceso/providers/auth_provider.dart';
import 'package:alquilamatch/features/inquilina/data/solicitud.dart';
import 'package:alquilamatch/features/inquilina/data/solicitudes_repository.dart';
import 'package:alquilamatch/features/inquilina/presentation/inicio_screen.dart';
import 'package:alquilamatch/features/inquilina/presentation/mis_solicitudes_screen.dart';
import 'package:alquilamatch/features/propietario/data/anuncio.dart';
import 'package:alquilamatch/features/propietario/data/anuncios_repository.dart';
import 'package:alquilamatch/features/propietario/presentation/inicio_screen.dart';
import 'package:alquilamatch/features/propietario/presentation/mis_anuncios_screen.dart';
import 'package:alquilamatch/features/propietario/providers/mis_anuncios_provider.dart';
import 'package:alquilamatch/main.dart';
import 'package:alquilamatch/shared/widgets/aviso.dart';
import 'package:alquilamatch/shared/widgets/pie_acciones.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// "Cuenta creada con éxito" llega al inicio y se ve en su pie, una sola vez.
///
/// Crear cuenta cierra sus pantallas con popUntil y la puerta de main.dart
/// reemplaza la raiz segun la sesion: no hay ruta ni argumento por donde
/// pasar el mensaje, viaja por AuthProvider. Esta prueba fija el camino
/// entero —de registro() al pie del inicio— para los dos roles, y que el
/// aviso no vuelve cuando la persona sigue a otra pantalla.

const _propietaria = Perfil(
  username: 'marta',
  rol: Rol.propietario,
  whatsapp: '70011122',
);
const _inquilina = Perfil(username: 'andrea', rol: Rol.inquilino);

/// Sin sesion guardada; crear la cuenta o entrar devuelve el perfil dado.
class _Auth extends Fake implements AuthRepository {
  _Auth(this.perfil);

  final Perfil perfil;

  @override
  Future<bool> haySesionGuardada() async => false;

  @override
  Future<Perfil> login({
    required String username,
    required String password,
  }) async => perfil;

  @override
  Future<Perfil> registro({
    required String username,
    required String password,
    required Rol rol,
    String whatsapp = '',
    String email = '',
  }) async => perfil;
}

class _Anuncios extends Fake implements AnunciosRepository {
  @override
  Future<List<Anuncio>> mios() async => const [];
}

class _Solicitudes extends Fake implements SolicitudesRepository {
  @override
  Future<List<SolicitudVisita>> misSolicitudes() async => const [];
}

/// Arranca la app entera sin sesion, como al abrirla por primera vez.
Future<AuthProvider> _arrancar(WidgetTester tester, Perfil perfil) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final auth = AuthProvider(_Auth(perfil));
  await auth.restaurarSesion();
  final anuncios = _Anuncios();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AnunciosRepository>.value(value: anuncios),
        Provider<SolicitudesRepository>.value(value: _Solicitudes()),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider(create: (_) => MisAnunciosProvider(anuncios)),
      ],
      child: const AlquilaMatchApp(),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('ENTRAR'), findsOneWidget, reason: 'arranca en Ingresar');

  return auth;
}

/// Crea la cuenta como lo hace Crear cuenta: por el provider.
Future<AuthProvider> _crearCuenta(WidgetTester tester, Perfil perfil) async {
  final auth = await _arrancar(tester, perfil);
  final ok = await auth.registro(
    username: perfil.username,
    password: '12345678',
    rol: perfil.rol,
    whatsapp: perfil.whatsapp,
  );
  expect(ok, isTrue);
  await tester.pumpAndSettle();
  return auth;
}

/// El pie del inicio es solo el aviso de exito, y dice lo que paso.
void _esperarAvisoEnElPie(WidgetTester tester) {
  final pie = find.byType(PieAcciones);
  expect(pie, findsOneWidget);

  final aviso = find.descendant(of: pie, matching: find.byType(Aviso));
  expect(aviso, findsOneWidget);
  expect(tester.widget<Aviso>(aviso).tipo, TipoAviso.exito);
  expect(
    find.descendant(
      of: pie,
      matching: find.text(AuthProvider.avisoCuentaCreada),
    ),
    findsOneWidget,
  );
  expect(find.byType(TarjetaMenu), findsWidgets, reason: 'es el inicio');
}

/// Toca una opcion del menu, vuelve, y el aviso ya no esta.
Future<void> _seguirYVolver(
  WidgetTester tester,
  AuthProvider auth, {
  required String opcion,
  required Type pantalla,
}) async {
  await tester.ensureVisible(find.widgetWithText(TarjetaMenu, opcion));
  await tester.tap(find.widgetWithText(TarjetaMenu, opcion));
  await tester.pumpAndSettle();
  expect(find.byType(pantalla), findsOneWidget);
  expect(auth.avisoInicial, isNull, reason: 'seguir es haberlo leido');

  Navigator.of(tester.element(find.byType(pantalla))).pop();
  await tester.pumpAndSettle();
  expect(find.byType(pantalla), findsNothing);
  expect(find.text(AuthProvider.avisoCuentaCreada), findsNothing);
  expect(find.byType(PieAcciones), findsNothing);
}

void main() {
  group('Cuenta creada con éxito', () {
    testWidgets('propietaria: entra al inicio con el aviso en el pie, y no '
        'vuelve al seguir', (tester) async {
      final auth = await _crearCuenta(tester, _propietaria);

      expect(find.byType(InicioPropietarioScreen), findsOneWidget);
      _esperarAvisoEnElPie(tester);

      await _seguirYVolver(
        tester,
        auth,
        opcion: 'Mis anuncios',
        pantalla: MisAnunciosScreen,
      );
      expect(find.byType(InicioPropietarioScreen), findsOneWidget);
    });

    testWidgets('inquilina: entra al inicio con el aviso en el pie, y no '
        'vuelve al seguir', (tester) async {
      final auth = await _crearCuenta(tester, _inquilina);

      expect(find.byType(InicioInquilinaScreen), findsOneWidget);
      _esperarAvisoEnElPie(tester);

      await _seguirYVolver(
        tester,
        auth,
        opcion: 'Estado de solicitudes',
        pantalla: MisSolicitudesScreen,
      );
      expect(find.byType(InicioInquilinaScreen), findsOneWidget);
    });

    testWidgets('entrar con una cuenta que ya existe no trae aviso', (
      tester,
    ) async {
      final auth = await _arrancar(tester, _propietaria);
      await auth.login(username: 'marta', password: '12345678');
      await tester.pumpAndSettle();

      expect(find.byType(InicioPropietarioScreen), findsOneWidget);
      expect(find.byType(PieAcciones), findsNothing);
      expect(find.text(AuthProvider.avisoCuentaCreada), findsNothing);
    });
  });
}
