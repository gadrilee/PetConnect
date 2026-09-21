import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/auth_repository.dart';
import '../data/foto_del_telefono.dart';
import '../data/perfil.dart';

enum EstadoSesion { comprobando, sinSesion, autenticado }

/// Estado de la sesion para toda la app.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  /// El aviso con el que se entra despues de crear la cuenta. El inicio lo
  /// muestra en su pie, como unico contenido del `PieAcciones`.
  static const String avisoCuentaCreada = 'Cuenta creada con éxito';

  /// El aviso con el que se entra despues de poner una contrasena nueva: la
  /// persona queda adentro sin volver a escribirla en Ingresar.
  static const String avisoContrasenaCambiada =
      'Listo, cambiaste tu contraseña. Ya estás adentro.';

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
    String email = '',
    String whatsapp = '',
  }) {
    return _intentar(
      () => _repo.registro(
        username: username,
        password: password,
        rol: rol,
        email: email,
        whatsapp: whatsapp,
      ),
      avisoAlLograrlo: avisoCuentaCreada,
    );
  }

  /// Pone la contrasena nueva con el enlace del correo y entra.
  Future<bool> confirmarRecuperacion({
    required String uid,
    required String token,
    required String password,
  }) {
    return _intentar(
      () => _repo.confirmarRecuperacion(uid: uid, token: token, password: password),
      avisoAlLograrlo: avisoContrasenaCambiada,
    );
  }

  /// Pide el enlace para una contrasena nueva. No toca la sesion: quien lo
  /// pide todavia no entro.
  Future<bool> pedirRecuperacion(String email) {
    return _sinSesion(
      () => _repo.pedirRecuperacion(email),
      fallo: 'No se pudo enviar el enlace. Revisá tu conexión y probá de nuevo.',
    );
  }

  /// Cambia el WhatsApp desde Mi perfil.
  Future<bool> actualizarWhatsapp(String whatsapp) {
    return _sinSesion(
      () async => _perfil = await _repo.actualizarWhatsapp(whatsapp),
      fallo: 'No se pudo guardar. Revisá tu conexión y probá de nuevo.',
    );
  }

  /// Lo que se dice cuando la foto no llego al servidor (Figma, Validaciones
  /// "08 Mi perfil · no se pudo subir la foto"). Si el servidor la recibio y
  /// la rechazo (pesa mucho, no es una imagen), se dice su motivo, que queda
  /// en `erroresPorCampo['foto']`.
  static const String noSeSubioLaFoto =
      'No se pudo subir la foto. Revisá tu conexión y probá de nuevo.';

  /// Pone o cambia la foto de perfil desde Mi perfil.
  Future<bool> subirFoto(FotoElegida foto) {
    return _sinSesion(
      () async => _perfil = await _repo.subirFoto(foto),
      fallo: noSeSubioLaFoto,
    );
  }

  /// Quita la foto de perfil: vuelve el icono del rol.
  Future<bool> quitarFoto() {
    return _sinSesion(
      () async => _perfil = await _repo.quitarFoto(),
      fallo: 'No se pudo quitar la foto. Revisá tu conexión y probá de nuevo.',
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

  /// Corre una accion que no cambia el estado de la sesion (pedir el enlace,
  /// guardar el WhatsApp). Los errores por campo del backend quedan para
  /// pintarlos debajo del campo; si no hay ninguno, va [fallo].
  Future<bool> _sinSesion(
    Future<void> Function() accion, {
    required String fallo,
  }) async {
    _ocupado = true;
    _limpiarErrores();
    notifyListeners();

    try {
      await accion();
      return true;
    } on ApiException catch (e) {
      _erroresPorCampo = e.porCampo;
      _error = e.porCampo.isEmpty ? fallo : null;
      return false;
    } catch (_) {
      _error = fallo;
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
