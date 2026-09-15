import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/auth_repository.dart';
import '../data/perfil.dart';

enum EstadoSesion { comprobando, sinSesion, autenticado }

/// Estado de la sesion para toda la app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  /// El aviso con el que se entra despues de crear la cuenta. El inicio lo
  /// muestra en su pie, como unico contenido del `PieAcciones`.
  static const String avisoCuentaCreada = 'Cuenta creada con éxito';

  EstadoSesion _estado = EstadoSesion.comprobando;
  Perfil? _perfil;
  String? _error;
  Map<String, String> _erroresPorCampo = const {};
  bool _ocupado = false;
  String? _avisoInicial;

  EstadoSesion get estado => _estado;
  Perfil? get perfil => _perfil;
  String? get error => _error;
  Map<String, String> get erroresPorCampo => _erroresPorCampo;
  bool get ocupado => _ocupado;

  /// Lo que el inicio muestra en su pie apenas se entra, una sola vez: hoy,
  /// [avisoCuentaCreada] despues del registro. `null` es sin aviso.
  ///
  /// El registro llega al inicio con `popUntil` y `_Puerta` cambia la raiz
  /// segun la sesion, asi que no hay ruta ni argumento por donde pasar el
  /// mensaje: viaja por aca. Quien lo muestra lo da por visto con
  /// [consumirAvisoInicial] cuando la persona sigue a otra pantalla.
  String? get avisoInicial => _avisoInicial;

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
    return _intentar(
      () => _repo.registro(
        username: username,
        password: password,
        rol: rol,
        whatsapp: whatsapp,
      ),
      avisoAlLograrlo: avisoCuentaCreada,
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    _perfil = null;
    _estado = EstadoSesion.sinSesion;
    _limpiarErrores();
    _avisoInicial = null;
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null && _erroresPorCampo.isEmpty) return;
    _limpiarErrores();
    notifyListeners();
  }

  /// Da por visto el [avisoInicial], para que no vuelva a aparecer. Avisa a
  /// quien escucha, asi que no se llama durante un build: se llama al tocar
  /// una opcion del inicio o al salir de la pantalla.
  void consumirAvisoInicial() {
    if (_avisoInicial == null) return;
    _avisoInicial = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------ interno

  /// Corre una accion que termina con la sesion iniciada. Si sale bien deja
  /// [avisoAlLograrlo] como aviso inicial, en la misma notificacion en la que
  /// la sesion pasa a autenticada: el inicio aparece ya con su aviso.
  Future<bool> _intentar(
    Future<Perfil> Function() accion, {
    String? avisoAlLograrlo,
  }) async {
    _ocupado = true;
    _limpiarErrores();
    _avisoInicial = null;
    notifyListeners();

    try {
      _perfil = await accion();
      _estado = EstadoSesion.autenticado;
      _avisoInicial = avisoAlLograrlo;
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
