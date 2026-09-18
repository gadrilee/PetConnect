import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/enlaces.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/acceso/data/auth_repository.dart';
import 'package:alquilamatch/features/acceso/data/perfil.dart';
import 'package:alquilamatch/features/acceso/presentation/login_screen.dart';
import 'package:alquilamatch/features/acceso/presentation/nueva_contrasena_screen.dart';
import 'package:alquilamatch/features/acceso/presentation/perfil_screen.dart';
import 'package:alquilamatch/features/acceso/presentation/recuperar_screen.dart';
import 'package:alquilamatch/features/acceso/providers/auth_provider.dart';
import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:alquilamatch/shared/widgets/tarjeta_perfil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// La cuenta del flujo v0.1: recuperar la contrasena, el enlace del correo y
/// Mi perfil.

const _marta = Perfil(
  username: 'marta',
  rol: Rol.propietario,
  whatsapp: '70011122',
  email: 'marta@uagrm.edu.bo',
);
const _andrea = Perfil(
  username: 'andrea',
  rol: Rol.inquilino,
  email: 'andrea@uagrm.edu.bo',
);

class _Auth extends Fake implements AuthRepository {
  _Auth({this.perfil = _marta});

  Perfil perfil;
  Object? falla;
  final pedidos = <String>[];
  final confirmaciones = <Map<String, String>>[];
  bool salio = false;

  Future<T> _o<T>(T valor) async {
    if (falla != null) throw falla!;
    return valor;
  }

  @override
  Future<Perfil> login({required String username, required String password}) =>
      _o(perfil);

  @override
  Future<Perfil> miPerfil() => _o(perfil);

  @override
  Future<Perfil> actualizarWhatsapp(String whatsapp) async {
    await _o(null);
    return perfil = Perfil(
      username: perfil.username,
      rol: perfil.rol,
      whatsapp: whatsapp,
      email: perfil.email,
    );
  }

  @override
  Future<void> pedirRecuperacion(String email) async {
    await _o(null);
    pedidos.add(email);
  }

  @override
  Future<Perfil> confirmarRecuperacion({
    required String uid,
    required String token,
    required String password,
  }) async {
    await _o(null);
    confirmaciones.add({'uid': uid, 'token': token, 'password': password});
    return perfil;
  }

  @override
  Future<void> logout() async => salio = true;
}

Future<AuthProvider> _montar(
  WidgetTester tester,
  Widget pantalla, {
  _Auth? repo,
  bool conSesion = false,
}) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = AuthProvider(repo ?? _Auth());
  if (conSesion) await provider.login(username: 'x', password: 'x');

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(theme: AppTheme.claro, home: pantalla),
    ),
  );
  await tester.pumpAndSettle();
  return provider;
}

Finder _campo(String etiqueta) => find.descendant(
      of: find.widgetWithText(CampoTexto, etiqueta),
      matching: find.byType(TextField),
    );

EstadoBoton _estadoBoton(WidgetTester tester, [Finder? boton]) {
  final state = tester.state(boton ?? find.byType(BotonPrincipal));
  return (state as dynamic).estado as EstadoBoton;
}

void main() {
  group('Olvidaste tu contraseña', () {
    testWidgets('Ingresar lo ofrece, entre ENTRAR y "No tengo cuenta"', (tester) async {
      await _montar(tester, const LoginScreen());

      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.byType(RecuperarScreen), findsOneWidget);
    });

    testWidgets('pide el correo y confirma sin decir si tiene cuenta', (tester) async {
      final repo = _Auth();
      await _montar(tester, const RecuperarScreen(), repo: repo);
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado);

      await tester.enterText(_campo('Correo'), ' marta@uagrm.edu.bo ');
      await tester.pump();
      expect(_estadoBoton(tester), EstadoBoton.reposo);

      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(repo.pedidos, ['marta@uagrm.edu.bo']);
      expect(
        find.text('Si ese correo tiene una cuenta, te llegó un enlace. Revisá tu bandeja.'),
        findsOneWidget,
      );
      expect(find.text('VOLVER A INGRESAR'), findsOneWidget);
    });

    testWidgets('sin conexión: el error se ve y se puede reintentar', (tester) async {
      final repo = _Auth()..falla = ApiException('No se pudo conectar con el servidor.');
      await _montar(tester, const RecuperarScreen(), repo: repo);

      await tester.enterText(_campo('Correo'), 'marta@uagrm.edu.bo');
      await tester.pump();
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo enviar el enlace. Revisá tu conexión y probá de nuevo.'),
        findsOneWidget,
      );
      expect(_estadoBoton(tester), EstadoBoton.reposo);
    });
  });

  group('Nueva contraseña', () {
    Widget pantalla() => const NuevaContrasenaScreen(uid: 'MQ', token: 'abc-123');

    testWidgets('las dos tienen que coincidir', (tester) async {
      final repo = _Auth();
      await _montar(tester, pantalla(), repo: repo);

      await tester.enterText(_campo('Contraseña nueva'), 'otra-clave-456');
      await tester.enterText(_campo('Repetir contraseña'), 'otra-clave-457');
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();

      expect(find.text('Las dos contraseñas no coinciden.'), findsOneWidget);
      expect(repo.confirmaciones, isEmpty);
    });

    testWidgets('al guardar entra directo, con el aviso de que ya está adentro',
        (tester) async {
      final repo = _Auth();
      final auth = await _montar(tester, pantalla(), repo: repo);

      await tester.enterText(_campo('Contraseña nueva'), 'otra-clave-456');
      await tester.enterText(_campo('Repetir contraseña'), 'otra-clave-456');
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();

      expect(repo.confirmaciones.single['token'], 'abc-123');
      expect(auth.estado, EstadoSesion.autenticado);
      expect(auth.avisoInicial, AuthProvider.avisoContrasenaCambiada);
    });

    testWidgets('enlace vencido: lo dice y ofrece pedir otro', (tester) async {
      const vencido = 'Ese enlace ya venció. Pedí uno nuevo y volvé a intentar.';
      final repo = _Auth()
        ..falla = ApiException(vencido, codigo: 400, porCampo: {'detalle': vencido});
      await _montar(tester, pantalla(), repo: repo);

      await tester.enterText(_campo('Contraseña nueva'), 'otra-clave-456');
      await tester.enterText(_campo('Repetir contraseña'), 'otra-clave-456');
      await tester.pump();
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();

      expect(find.text(vencido), findsOneWidget);
      await tester.tap(find.text('PEDIR OTRO ENLACE'));
      await tester.pumpAndSettle();
      expect(find.byType(RecuperarScreen), findsOneWidget);
    });
  });

  group('El enlace del correo', () {
    test('/recuperar con uid y token abre Nueva contraseña', () {
      final ruta = rutaDesdeEnlace(
        const RouteSettings(name: '/recuperar?uid=MQ&token=abc-123'),
      );
      expect(ruta, isA<MaterialPageRoute<dynamic>>());
    });

    test('cualquier otra ruta, o sin token, no es suya', () {
      expect(rutaDesdeEnlace(const RouteSettings(name: '/')), isNull);
      expect(rutaDesdeEnlace(const RouteSettings(name: '/recuperar?uid=MQ')), isNull);
      expect(rutaDesdeEnlace(const RouteSettings(name: '/otra?uid=MQ&token=x')), isNull);
    });
  });

  group('Mi perfil', () {
    testWidgets('propietaria: sus datos, el WhatsApp y GUARDAR apagado hasta cambiarlo',
        (tester) async {
      await _montar(tester, const PerfilScreen(), conSesion: true);

      expect(find.text('marta'), findsOneWidget);
      expect(find.text('marta@uagrm.edu.bo'), findsOneWidget);
      expect(find.text('Propietaria'), findsOneWidget);
      expect(find.text('70011122'), findsOneWidget);
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado);

      await tester.enterText(_campo('WhatsApp'), '70099988');
      await tester.pump();
      expect(_estadoBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('guardar un número nuevo lo confirma', (tester) async {
      final repo = _Auth();
      await _montar(tester, const PerfilScreen(), repo: repo, conSesion: true);

      await tester.enterText(_campo('WhatsApp'), '70099988');
      await tester.pump();
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(repo.perfil.whatsapp, '70099988');
      expect(
        find.text('Guardado. Es el número que se libera cuando aprobás una visita.'),
        findsOneWidget,
      );
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado,
          reason: 'ya no hay nada que guardar');
    });

    testWidgets('un número incompleto no se manda', (tester) async {
      final repo = _Auth();
      await _montar(tester, const PerfilScreen(), repo: repo, conSesion: true);

      await tester.enterText(_campo('WhatsApp'), '7009');
      await tester.pump();
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(find.text('Escribí los 8 dígitos, como 70099988.'), findsOneWidget);
      expect(repo.perfil.whatsapp, '70011122');
    });

    testWidgets('inquilina: sin WhatsApp ni nada que guardar, sólo la salida',
        (tester) async {
      await _montar(tester, const PerfilScreen(),
          repo: _Auth(perfil: _andrea), conSesion: true);

      expect(find.text('Inquilina'), findsOneWidget);
      expect(find.widgetWithText(CampoTexto, 'WhatsApp'), findsNothing);
      expect(find.text('GUARDAR'), findsNothing);
      expect(find.text('CERRAR SESIÓN'), findsOneWidget);
    });

    testWidgets('CERRAR SESIÓN sale de la cuenta', (tester) async {
      final repo = _Auth();
      final auth = await _montar(tester, const PerfilScreen(), repo: repo, conSesion: true);

      await tester.ensureVisible(find.text('CERRAR SESIÓN'));
      await tester.tap(find.text('CERRAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(repo.salio, isTrue);
      expect(auth.estado, EstadoSesion.sinSesion);
    });
  });

  testWidgets('La tarjeta de perfil es la puerta a Mi perfil', (tester) async {
    var tocada = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.claro,
        home: Scaffold(
          body: TarjetaPerfil(
            nombre: 'marta',
            rol: 'Propietario',
            icono: Icons.home_work_outlined,
            alTocar: () => tocada = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing,
        reason: 'cerrar sesión vive adentro de Mi perfil');

    await tester.tap(find.byType(TarjetaPerfil));
    expect(tocada, isTrue);
  });
}
