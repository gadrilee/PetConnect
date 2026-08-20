import 'package:alquilamatch/core/api_client.dart';
import 'package:alquilamatch/features/auth/data/auth_repository.dart';
import 'package:alquilamatch/features/auth/data/perfil.dart';
import 'package:alquilamatch/features/auth/presentation/login_screen.dart';
import 'package:alquilamatch/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Envuelve una pantalla con lo minimo para que se pueda construir.
///
/// No se llama a `restaurarSesion()`: sin eso el provider se queda en
/// `comprobando` y no toca el almacenamiento seguro, que no existe en un test.
Widget _conProvider(Widget hijo) {
  return MaterialApp(
    home: ChangeNotifierProvider(
      create: (_) => AuthProvider(AuthRepository(ApiClient())),
      child: hijo,
    ),
  );
}

void main() {
  group('Perfil', () {
    test('mapea el rol que devuelve la API', () {
      final p = Perfil.desdeJson({
        'username': 'marta',
        'rol': 'PROPIETARIO',
        'whatsapp': '70011122',
      });
      expect(p.rol, Rol.propietario);
      expect(p.esPropietario, isTrue);
      expect(p.whatsapp, '70011122');
    });

    test('una inquilina no es propietaria', () {
      final p = Perfil.desdeJson({'username': 'andrea', 'rol': 'INQUILINO'});
      expect(p.rol, Rol.inquilino);
      expect(p.esPropietario, isFalse);
      expect(p.whatsapp, isEmpty);
    });

    test('un rol desconocido no rompe la app', () {
      final p = Perfil.desdeJson({'username': 'x', 'rol': 'MARCIANO'});
      expect(p.rol, Rol.inquilino);
    });
  });

  group('LoginScreen', () {
    testWidgets('muestra los campos y el boton de entrar', (tester) async {
      await tester.pumpWidget(_conProvider(const LoginScreen()));

      expect(find.text('AlquilaMatch'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Usuario'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    });

    testWidgets('no envia el formulario vacio', (tester) async {
      await tester.pumpWidget(_conProvider(const LoginScreen()));

      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pump();

      // La validacion corta antes de tocar la red.
      expect(find.text('Escribí tu usuario'), findsOneWidget);
      expect(find.text('Escribí tu contraseña'), findsOneWidget);
    });

    testWidgets('el ojito revela la contrasena', (tester) async {
      await tester.pumpWidget(_conProvider(const LoginScreen()));

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
