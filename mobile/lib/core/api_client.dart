import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

/// Error de la API con un mensaje ya legible para mostrarle a la persona.
class ApiException implements Exception {
  ApiException(this.mensaje, {this.codigo, this.porCampo = const {}});

  final String mensaje;
  final int? codigo;

  /// Errores por campo, tal como los devuelve DRF: `{"whatsapp": ["..."]}`.
  /// Sirve para pintarlos debajo del input correspondiente.
  final Map<String, String> porCampo;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP con JWT.
///
/// Guarda los tokens en almacenamiento seguro, los adjunta a cada pedido y
/// renueva el access token cuando vence, reintentando el pedido una sola vez.
class ApiClient {
  ApiClient({http.Client? cliente, FlutterSecureStorage? almacen})
      : _http = cliente ?? http.Client(),
        _almacen = almacen ?? const FlutterSecureStorage();

  final http.Client _http;
  final FlutterSecureStorage _almacen;

  static const _claveAccess = 'access_token';
  static const _claveRefresh = 'refresh_token';

  Future<String?> get accessToken => _almacen.read(key: _claveAccess);

  Future<bool> get haySesion async => (await accessToken) != null;

  Future<void> guardarTokens({required String access, required String refresh}) async {
    await _almacen.write(key: _claveAccess, value: access);
    await _almacen.write(key: _claveRefresh, value: refresh);
  }

  Future<void> borrarTokens() async {
    await _almacen.delete(key: _claveAccess);
    await _almacen.delete(key: _claveRefresh);
  }

  // ---------------------------------------------------------------- pedidos

  Future<dynamic> get(String ruta, {Map<String, String>? query}) {
    return _enviar('GET', ruta, query: query);
  }

  Future<dynamic> post(String ruta, {Object? cuerpo, bool conToken = true}) {
    return _enviar('POST', ruta, cuerpo: cuerpo, conToken: conToken);
  }

  Future<dynamic> patch(String ruta, {Object? cuerpo}) {
    return _enviar('PATCH', ruta, cuerpo: cuerpo);
  }

  /// Sube un archivo con `multipart/form-data`.
  ///
  /// Lo usa la carga de fotos del anuncio, que ademas manda la fecha de
  /// captura: lo que importa es cuando se saco la foto, no cuando se subio.
  Future<dynamic> postArchivo(
    String ruta, {
    required String campo,
    required String rutaArchivo,
    Map<String, String> campos = const {},
  }) async {
    final uri = Uri.parse('${Config.baseUrl}$ruta');
    final peticion = http.MultipartRequest('POST', uri)
      ..fields.addAll(campos)
      ..files.add(await http.MultipartFile.fromPath(campo, rutaArchivo));

    final token = await accessToken;
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(await _http.send(peticion));
    } catch (_) {
      throw ApiException('No se pudo subir la foto. Revisá tu conexión.');
    }
    return _interpretar(respuesta);
  }

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Object? cuerpo,
    Map<String, String>? query,
    bool conToken = true,
    bool esReintento = false,
  }) async {
    final uri = Uri.parse('${Config.baseUrl}$ruta').replace(queryParameters: query);
    final cabeceras = <String, String>{'Content-Type': 'application/json'};

    if (conToken) {
      final token = await accessToken;
      if (token != null) cabeceras['Authorization'] = 'Bearer $token';
    }

    final http.Response respuesta;
    try {
      final peticion = http.Request(metodo, uri)..headers.addAll(cabeceras);
      if (cuerpo != null) peticion.body = jsonEncode(cuerpo);
      respuesta = await http.Response.fromStream(await _http.send(peticion));
    } catch (e) {
      throw ApiException(
        'No se pudo conectar con el servidor.\n'
        'Revisá que el backend esté corriendo en ${Config.baseUrl}.',
      );
    }

    // El access vencio: renovarlo y reintentar una unica vez.
    if (respuesta.statusCode == 401 && conToken && !esReintento) {
      if (await _renovarToken()) {
        return _enviar(metodo, ruta,
            cuerpo: cuerpo, query: query, conToken: conToken, esReintento: true);
      }
    }

    return _interpretar(respuesta);
  }

  dynamic _interpretar(http.Response r) {
    final cuerpo = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));

    if (r.statusCode >= 200 && r.statusCode < 300) return cuerpo;

    throw ApiException(
      _mensajeDeError(cuerpo, r.statusCode),
      codigo: r.statusCode,
      porCampo: _erroresPorCampo(cuerpo),
    );
  }

  /// DRF devuelve los errores de varias formas segun el caso. Las cubrimos
  /// todas para no mostrarle un JSON crudo a la persona.
  String _mensajeDeError(dynamic cuerpo, int codigo) {
    if (cuerpo is Map) {
      if (cuerpo['detail'] is String) return cuerpo['detail'] as String;
      for (final valor in cuerpo.values) {
        if (valor is List && valor.isNotEmpty) return valor.first.toString();
        if (valor is String) return valor;
      }
    }
    if (cuerpo is List && cuerpo.isNotEmpty) return cuerpo.first.toString();

    return switch (codigo) {
      401 => 'Usuario o contraseña incorrectos.',
      403 => 'No tenés permiso para hacer esto.',
      404 => 'No se encontró lo que buscabas.',
      >= 500 => 'El servidor tuvo un problema. Intentá de nuevo en un momento.',
      _ => 'Ocurrió un error inesperado (código $codigo).',
    };
  }

  Map<String, String> _erroresPorCampo(dynamic cuerpo) {
    if (cuerpo is! Map) return const {};
    final salida = <String, String>{};
    cuerpo.forEach((clave, valor) {
      if (clave == 'detail') return;
      if (valor is List && valor.isNotEmpty) {
        salida[clave.toString()] = valor.first.toString();
      } else if (valor is String) {
        salida[clave.toString()] = valor;
      }
    });
    return salida;
  }

  Future<bool> _renovarToken() async {
    final refresh = await _almacen.read(key: _claveRefresh);
    if (refresh == null) return false;

    try {
      final r = await _http.post(
        Uri.parse('${Config.baseUrl}/api/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (r.statusCode != 200) {
        await borrarTokens();
        return false;
      }
      final datos = jsonDecode(r.body) as Map<String, dynamic>;
      await _almacen.write(key: _claveAccess, value: datos['access'] as String);
      return true;
    } catch (_) {
      return false;
    }
  }
}
