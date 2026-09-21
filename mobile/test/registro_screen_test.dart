import 'dart:async';

import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/core/theme.dart';
import 'package:alquilamatch/features/acceso/data/auth_repository.dart';
import 'package:alquilamatch/features/acceso/data/perfil.dart';
import 'package:alquilamatch/features/acceso/presentation/registro_screen.dart';
import 'package:alquilamatch/features/acceso/providers/auth_provider.dart';
import 'package:alquilamatch/shared/widgets/aviso.dart';
import 'package:alquilamatch/shared/widgets/boton_principal.dart';
import 'package:alquilamatch/shared/widgets/campo_texto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Crear cuenta, como en Figma (03 Crear cuenta · vacío / completo / datos
/// con error): el boton se prende solo con todos los campos llenos, al tocar
/// cada campo explica su error debajo, y el aviso de arriba del boton cuenta
/// los campos en rojo, vengan de la pantalla o del backend.

const _marta = Perfil(
  username: 'marta',
  rol: Rol.propietario,
  whatsapp: '70011122',
);
const _andrea = Perfil(username: 'andrea', rol: Rol.inquilino);

/// Los textos de Figma, escritos aca a mano: si la pantalla los cambia, la
/// prueba lo tiene que notar.
const _claveCorta = 'Asegurate de que este campo tenga al menos 8 caracteres.';
const _whatsappInvalido = 'Escribí un número de 8 dígitos.';
const _correoInvalido = 'Escribí un correo completo, como marta@uagrm.edu.bo.';
const _usuarioTomado = 'Ese nombre de usuario ya está tomado.';
const _correoTomado = 'Ya hay una cuenta con ese correo.';
const _sinConexion = 'No se pudo conectar con el servidor.';

/// El backend del registro: anota lo que le llega y responde como se le
/// indique en [respuesta]. `null` es crear la cuenta sin problemas.
class _Auth extends Fake implements AuthRepository {
  _Auth({this.respuesta});

  final Future<Perfil> Function()? respuesta;

  /// Cada registro que llego, con lo que la pantalla mando.
  final registros = <Map<String, String>>[];

  @override
  Future<Perfil> registro({
    required String username,
    required String password,
    required Rol rol,
    String whatsapp = '',
    String email = '',
  }) {
    registros.add({
      'username': username,
      'email': email,
      'password': password,
      'rol': rol.valor,
      'whatsapp': whatsapp,
    });
    return respuesta?.call() ??
        Future.value(rol == Rol.propietario ? _marta : _andrea);
  }
}

Future<_Auth> _montar(
  WidgetTester tester, {
  Rol rol = Rol.propietario,
  Future<Perfil> Function()? respuesta,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = _Auth(respuesta: respuesta);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(repo),
      child: MaterialApp(theme: AppTheme.claro, home: RegistroScreen(rol: rol)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// El campo de texto de la pieza con esa etiqueta.
Finder _campo(String etiqueta) => find.descendant(
      of: find.widgetWithText(CampoTexto, etiqueta),
      matching: find.byType(TextField),
    );

Future<void> _escribir(
  WidgetTester tester,
  String etiqueta,
  String texto,
) async {
  await tester.enterText(_campo(etiqueta), texto);
  await tester.pump();
}

/// Llena los cuatro campos. Por defecto, con datos que el backend aceptaria.
Future<void> _completar(
  WidgetTester tester, {
  String usuario = 'marta',
  String correo = 'marta@uagrm.edu.bo',
  String clave = '12345678',
  String whatsapp = '70011122',
}) async {
  await _escribir(tester, 'Usuario', usuario);
  await _escribir(tester, 'Correo', correo);
  await _escribir(tester, 'Contraseña', clave);
  await _escribir(tester, 'WhatsApp', whatsapp);
}

Future<void> _tocarCrearCuenta(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(BotonPrincipal));
  await tester.tap(find.byType(BotonPrincipal), warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// El estado no se pasa por parametro: se deriva. Se lee desde el State.
EstadoBoton _estadoBoton(WidgetTester tester) {
  final state = tester.state(find.byType(BotonPrincipal));
  return (state as dynamic).estado as EstadoBoton;
}

/// Que campos estan en rojo, por etiqueta.
Iterable<String> _camposEnRojo(WidgetTester tester) => [
      for (final campo in find.byType(CampoTexto).evaluate())
        if ((campo as StatefulElement).state case final estado
            when (estado as dynamic).estado == EstadoCampo.error)
          (campo.widget as CampoTexto).etiqueta,
    ];

/// El resumen de arriba del boton: el unico Aviso de error de la pantalla.
/// `null` si no hay ninguno.
String? _resumen(WidgetTester tester) {
  final avisos = tester
      .widgetList<Aviso>(find.byType(Aviso))
      .where((aviso) => aviso.tipo == TipoAviso.error)
      .toList();
  expect(avisos.length, lessThan(2), reason: 'un solo resumen de errores');
  return avisos.isEmpty ? null : avisos.single.mensaje;
}

void main() {
  group('El boton CREAR CUENTA', () {
    testWidgets('vacío: apagado hasta que usuario, correo, contraseña y '
        'WhatsApp tengan texto; completo: prendido', (tester) async {
      final repo = await _montar(tester);
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado);

      // Tocarlo apagado no manda nada ni marca campos.
      await _tocarCrearCuenta(tester);
      expect(repo.registros, isEmpty);
      expect(_camposEnRojo(tester), isEmpty);
      expect(_resumen(tester), isNull);

      await _escribir(tester, 'Usuario', 'marta');
      await _escribir(tester, 'Contraseña', '12345678');
      await _escribir(tester, 'WhatsApp', '70011122');
      expect(
        _estadoBoton(tester),
        EstadoBoton.deshabilitado,
        reason: 'falta el correo: sin él no se puede recuperar la cuenta',
      );

      await _escribir(tester, 'WhatsApp', '');
      await _escribir(tester, 'Correo', 'marta@uagrm.edu.bo');
      expect(
        _estadoBoton(tester),
        EstadoBoton.deshabilitado,
        reason: 'falta el WhatsApp',
      );

      await _escribir(tester, 'WhatsApp', '70011122');
      expect(_estadoBoton(tester), EstadoBoton.reposo);

      // Y se vuelve a apagar si un campo queda vacio.
      await _escribir(tester, 'Usuario', '');
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado);
    });

    testWidgets('el "listo" del teclado con un campo vacío no crea la cuenta '
        'ni marca nada: pasa por la misma compuerta que el boton', (
      tester,
    ) async {
      final repo = await _montar(tester);
      await _escribir(tester, 'Correo', 'marta@uagrm.edu.bo');
      await _escribir(tester, 'Contraseña', '12345678');
      await _escribir(tester, 'WhatsApp', '70011122');
      expect(
        _estadoBoton(tester),
        EstadoBoton.deshabilitado,
        reason: 'falta el usuario',
      );

      // El foco quedo en WhatsApp, cuyo teclado termina en "listo".
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repo.registros, isEmpty, reason: 'no llega al backend');
      expect(_camposEnRojo(tester), isEmpty);
      expect(_resumen(tester), isNull);
      // El usuario vacio no tiene motivo propio: ese texto no esta en Figma.
      expect(find.text('Escribí un usuario'), findsNothing);

      // Con los tres llenos, el mismo "listo" si crea la cuenta.
      await _escribir(tester, 'Usuario', 'marta');
      await tester.tap(_campo('WhatsApp'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.registros, hasLength(1));
    });

    testWidgets('inquilina: no se le pide WhatsApp, alcanza con usuario, '
        'correo y contraseña', (tester) async {
      await _montar(tester, rol: Rol.inquilino);
      expect(find.widgetWithText(CampoTexto, 'WhatsApp'), findsNothing);
      expect(_estadoBoton(tester), EstadoBoton.deshabilitado);

      await _escribir(tester, 'Usuario', 'andrea');
      await _escribir(tester, 'Correo', 'andrea@uagrm.edu.bo');
      await _escribir(tester, 'Contraseña', '12345678');
      expect(_estadoBoton(tester), EstadoBoton.reposo);
    });

    testWidgets('mientras se crea la cuenta se ve cargando y no acepta otro '
        'toque', (tester) async {
      final enCurso = Completer<Perfil>();
      final repo = await _montar(tester, respuesta: () => enCurso.future);
      await _completar(tester);

      await tester.ensureVisible(find.byType(BotonPrincipal));
      await tester.tap(find.byType(BotonPrincipal));
      // Sin pumpAndSettle: el spinner gira mientras el backend no responde.
      await tester.pump();
      expect(_estadoBoton(tester), EstadoBoton.cargando);
      expect(find.text('CREANDO...'), findsOneWidget);

      await tester.tap(find.byType(BotonPrincipal), warnIfMissed: false);
      await tester.pump();
      expect(repo.registros, hasLength(1), reason: 'no se crea dos veces');

      enCurso.complete(_marta);
      await tester.pumpAndSettle();
      expect(_estadoBoton(tester), EstadoBoton.reposo);
    });
  });

  group('Al tocar, cada campo explica su error y el aviso los cuenta', () {
    testWidgets('contraseña corta y WhatsApp que no son 8 dígitos: dos '
        'campos en rojo, cada uno con su motivo', (tester) async {
      final repo = await _montar(tester);
      await _completar(tester, clave: '1234', whatsapp: '700');

      // Mientras se escribe no se marca nada: se revisa al tocar.
      expect(_camposEnRojo(tester), isEmpty);
      expect(_resumen(tester), isNull);

      await _tocarCrearCuenta(tester);

      expect(repo.registros, isEmpty, reason: 'no llega al backend');
      expect(_camposEnRojo(tester), ['Contraseña', 'WhatsApp']);
      expect(find.text(_claveCorta), findsOneWidget);
      expect(find.text(_whatsappInvalido), findsOneWidget);
      expect(
        _resumen(tester),
        'Corregí los 2 campos marcados en rojo para crear la cuenta.',
      );
    });

    testWidgets('WhatsApp de 9 dígitos tampoco sirve: son exactamente 8', (
      tester,
    ) async {
      await _montar(tester);
      await _completar(tester, whatsapp: '700111222');
      await _tocarCrearCuenta(tester);

      expect(_camposEnRojo(tester), ['WhatsApp']);
      expect(find.text(_whatsappInvalido), findsOneWidget);
    });

    testWidgets('un solo campo en rojo: el aviso habla en singular', (
      tester,
    ) async {
      await _montar(tester);
      await _completar(tester, whatsapp: '7001112');
      await _tocarCrearCuenta(tester);

      expect(_camposEnRojo(tester), ['WhatsApp']);
      expect(
        _resumen(tester),
        'Corregí el campo marcado en rojo para crear la cuenta.',
      );
    });

    testWidgets('usuario tomado: el backend lo pone debajo del campo y '
        'cuenta en el resumen, no lo reemplaza', (tester) async {
      await _montar(
        tester,
        respuesta: () async => throw ApiException(
          _usuarioTomado,
          codigo: 400,
          porCampo: {'username': _usuarioTomado},
        ),
      );
      await _completar(tester);
      await _tocarCrearCuenta(tester);

      expect(_camposEnRojo(tester), ['Usuario']);
      expect(
        find.descendant(
          of: find.widgetWithText(CampoTexto, 'Usuario'),
          matching: find.text(_usuarioTomado),
        ),
        findsOneWidget,
      );
      expect(
        _resumen(tester),
        'Corregí el campo marcado en rojo para crear la cuenta.',
      );
    });

    testWidgets('sin conexión: el aviso trae el mensaje del error, sin '
        'campos en rojo', (tester) async {
      await _montar(
        tester,
        respuesta: () async => throw ApiException(_sinConexion),
      );
      await _completar(tester);
      await _tocarCrearCuenta(tester);

      expect(_camposEnRojo(tester), isEmpty);
      expect(_resumen(tester), _sinConexion);
    });

    testWidgets('correo sin arroba ni dominio: el campo dice cómo tiene que '
        'ser', (tester) async {
      final repo = await _montar(tester);
      await _completar(tester, correo: 'marta');
      await _tocarCrearCuenta(tester);

      expect(repo.registros, isEmpty, reason: 'no llega al backend');
      expect(_camposEnRojo(tester), ['Correo']);
      expect(find.text(_correoInvalido), findsOneWidget);
    });

    testWidgets('correo ya usado: el backend lo pone debajo del campo', (
      tester,
    ) async {
      await _montar(
        tester,
        respuesta: () async => throw ApiException(
          _correoTomado,
          codigo: 400,
          porCampo: {'email': _correoTomado},
        ),
      );
      await _completar(tester);
      await _tocarCrearCuenta(tester);

      expect(_camposEnRojo(tester), ['Correo']);
      expect(
        find.descendant(
          of: find.widgetWithText(CampoTexto, 'Correo'),
          matching: find.text(_correoTomado),
        ),
        findsOneWidget,
      );
    });

    testWidgets('con datos válidos manda lo escrito, sin espacios, y no '
        'marca nada', (tester) async {
      final repo = await _montar(tester);
      await _completar(tester, usuario: ' marta ', correo: ' marta@uagrm.edu.bo ');
      await _tocarCrearCuenta(tester);

      expect(repo.registros, [
        {
          'username': 'marta',
          'email': 'marta@uagrm.edu.bo',
          'password': '12345678',
          'rol': 'PROPIETARIO',
          'whatsapp': '70011122',
        },
      ]);
      expect(_camposEnRojo(tester), isEmpty);
      expect(_resumen(tester), isNull);
    });
  });
}
