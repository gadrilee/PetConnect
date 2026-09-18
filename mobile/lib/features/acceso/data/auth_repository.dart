import '../../../core/api_client.dart';
import 'perfil.dart';

/// Todo lo que la app hace contra los endpoints de autenticacion y perfil.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  /// Pide los tokens, los guarda y devuelve el perfil.
  Future<Perfil> login({required String username, required String password}) async {
    final tokens = await _api.post(
      '/api/auth/token/',
      cuerpo: {'username': username, 'password': password},
      conToken: false,
    ) as Map<String, dynamic>;

    await _api.guardarTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );

    return miPerfil();
  }

  /// Crea la cuenta con su rol y deja la sesion iniciada.
  ///
  /// El backend rechaza a un propietario sin WhatsApp: no habria nada que
  /// liberar cuando aprueba una solicitud.
  Future<Perfil> registro({
    required String username,
    required String password,
    required Rol rol,
    String whatsapp = '',
    String email = '',
  }) async {
    await _api.post(
      '/api/usuarios/registro/',
      cuerpo: {
        'username': username,
        'password': password,
        'rol': rol.valor,
        if (whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (email.isNotEmpty) 'email': email,
      },
      conToken: false,
    );

    return login(username: username, password: password);
  }

  Future<Perfil> miPerfil() async {
    final datos = await _api.get('/api/usuarios/yo/') as Map<String, dynamic>;
    return Perfil.desdeJson(datos);
  }

  /// Cambia el WhatsApp: lo unico que se edita desde Mi perfil.
  Future<Perfil> actualizarWhatsapp(String whatsapp) async {
    final datos = await _api.patch(
      '/api/usuarios/yo/',
      cuerpo: {'whatsapp': whatsapp},
    ) as Map<String, dynamic>;
    return Perfil.desdeJson(datos);
  }

  /// Pide el enlace para poner una contrasena nueva. El backend responde lo
  /// mismo exista o no la cuenta, asi que aca no hay nada que devolver.
  Future<void> pedirRecuperacion(String email) async {
    await _api.post(
      '/api/usuarios/recuperar/',
      cuerpo: {'email': email},
      conToken: false,
    );
  }

  /// Pone la contrasena nueva con el enlace del correo y deja la sesion
  /// iniciada: el backend devuelve los tokens, asi que no hay que volver a
  /// escribirla en Ingresar.
  Future<Perfil> confirmarRecuperacion({
    required String uid,
    required String token,
    required String password,
  }) async {
    final tokens = await _api.post(
      '/api/usuarios/recuperar/confirmar/',
      cuerpo: {'uid': uid, 'token': token, 'password': password},
      conToken: false,
    ) as Map<String, dynamic>;

    await _api.guardarTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    return miPerfil();
  }

  Future<void> logout() => _api.borrarTokens();

  Future<bool> haySesionGuardada() => _api.haySesion;
}
