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

  Future<void> logout() => _api.borrarTokens();

  Future<bool> haySesionGuardada() => _api.haySesion;
}
