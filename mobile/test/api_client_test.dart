import 'dart:convert';
import 'dart:io';

import 'package:alquilamatch/core/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Pruebas del unico lugar de la app que habla HTTP.
///
/// Lo que se fija aca es la recuperacion de un token vencido: que el pedido se
/// reintente solo, y que se reintente **una sola vez** para no quedar dando
/// vueltas contra un servidor que responde 401 siempre.

/// Archivo temporal, porque MultipartFile.fromPath lee del disco de verdad.
late File _foto;

/// Un cliente que responde segun el token que le llega.
///
/// Guarda cada intento para poder afirmar cuantas veces se pidio y con que
/// credencial, que es justo lo que distingue "reintento" de "no reintento".
MockClient _servidor({
  required List<String?> intentos,
  bool refrescoFunciona = true,
  bool siempre401 = false,
}) {
  return MockClient((peticion) async {
    if (peticion.url.path.endsWith('/token/refresh/')) {
      return refrescoFunciona
          ? http.Response(jsonEncode({'access': 'token-nuevo'}), 200)
          : http.Response(jsonEncode({'detail': 'refresh vencido'}), 401);
    }

    final auth = peticion.headers['Authorization'];
    intentos.add(auth);

    if (siempre401 || auth == 'Bearer token-viejo') {
      return http.Response(
        jsonEncode({'detail': 'Token is invalid or expired'}),
        401,
      );
    }
    return http.Response(jsonEncode({'id': 7}), 201);
  });
}

Future<dynamic> _subir(ApiClient api) => api.postArchivo(
  '/api/anuncios/1/fotos/',
  campo: 'imagen',
  rutaArchivo: _foto.path,
  campos: const {'fecha_captura': '2026-08-12'},
);

void main() {
  setUpAll(() async {
    _foto = File('${Directory.systemTemp.path}/alquilamatch_prueba.jpg');
    await _foto.writeAsBytes(List<int>.filled(16, 0));
  });

  tearDownAll(() async {
    if (_foto.existsSync()) await _foto.delete();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'token-viejo',
      'refresh_token': 'refresh-bueno',
    });
  });

  group('Subir una foto con el token vencido', () {
    test('renueva el token y vuelve a subirla', () async {
      final intentos = <String?>[];
      final api = ApiClient(cliente: _servidor(intentos: intentos));

      final resultado = await _subir(api);

      // Antes esto tiraba ApiException con "Usuario o contrasena incorrectos":
      // subir fotos era lo unico que no se recuperaba de un token vencido.
      expect(resultado, {'id': 7});
      expect(intentos, [
        'Bearer token-viejo',
        'Bearer token-nuevo',
      ], reason: 'debe reintentar con el token renovado');
    });

    test('no reintenta mas de una vez', () async {
      final intentos = <String?>[];
      final api = ApiClient(
        cliente: _servidor(intentos: intentos, siempre401: true),
      );

      // Si el servidor responde 401 siempre, la app tiene que rendirse: dos
      // intentos y afuera. Reintentar sin tope seria un bucle infinito.
      await expectLater(_subir(api), throwsA(isA<ApiException>()));
      expect(intentos.length, 2);
    });

    test('si el refresh tambien vencio, falla sin reintentar', () async {
      final intentos = <String?>[];
      final api = ApiClient(
        cliente: _servidor(intentos: intentos, refrescoFunciona: false),
      );

      await expectLater(_subir(api), throwsA(isA<ApiException>()));
      expect(
        intentos.length,
        1,
        reason: 'sin token nuevo no hay que reintentar',
      );
    });
  });

  group('El resto de los pedidos', () {
    test('un GET con el token vencido tambien se recupera', () async {
      final intentos = <String?>[];
      final api = ApiClient(cliente: _servidor(intentos: intentos));

      expect(await api.get('/api/anuncios/'), {'id': 7});
      expect(intentos, ['Bearer token-viejo', 'Bearer token-nuevo']);
    });
  });
}
