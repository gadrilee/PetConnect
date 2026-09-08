import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/auth_repository.dart';
import '../data/perfil.dart';

enum EstadoSesion { comprobando, sinSesion, autenticado }

/// Estado de la sesion para toda la app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  EstadoSesion _estado = EstadoSesion.comprobando;
  Perfil? _perfil;
  String? _error;
  Map<String, String> _erroresPorCampo = const {};
  bool _ocupado = false;

  EstadoSesion get estado => _estado;
  Perfil? get perfil => _perfil;
  String? get error => _error;
  Map<String, String> get erroresPorCampo => _erroresPorCampo;
  bool get ocupado => _ocupado;

  /// Se llama al arrancar la app: si hay un token guardado, intenta usarlo.
  Future<void> restaurarSesion() async {
    if (!await _repo.haySesionGuardada()) {
      _estado = EstadoSesion.sinSesion;
      notifyListeners();
      return;
    }

    try {
      _perfil = await _repo.miPerfil();
      _estado = EstadoSesion.autenticado;
    } catch (_) {
      // Token vencido o servidor caido: se arranca sin sesion, sin molestar.
      await _repo.logout();
      _estado = EstadoSesion.sinSesion;
    }
    notifyListeners();
  }

  Future<bool> login({required String username, required String password}) {
    return _intentar(() => _repo.login(username: username, password: password));
  }

  Future<bool> registro({
    required String username,
    required String password,
    required Rol rol,
    String whatsapp = '',
  }) {
    return _intentar(() => _repo.registro(
          username: username,
          password: password,
          rol: rol,
          whatsapp: whatsapp,
        ));
  }

  Future<void> logout() async {
    await _repo.logout();
    _perfil = null;
    _estado = EstadoSesion.sinSesion;
    _limpiarErrores();
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null && _erroresPorCampo.isEmpty) return;
    _limpiarErrores();
    notifyListeners();
  }

  // ------------------------------------------------------------------ interno

  Future<bool> _intentar(Future<Perfil> Function() accion) async {
    _ocupado = true;
    _limpiarErrores();
    notifyListeners();

    try {
      _perfil = await accion();
      _estado = EstadoSesion.autenticado;
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _erroresPorCampo = e.porCampo;
      return false;
    } catch (e) {
      _error = 'Ocurrió un error inesperado.';
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  void _limpiarErrores() {
    _error = null;
    _erroresPorCampo = const {};
  }
}
