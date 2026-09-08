import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/solicitud.dart';
import '../data/solicitudes_repository.dart';

/// Maneja el ciclo de vida de una solicitud de visita.
///
/// Se crea fresco por cada solicitud para no arrastrar errores anteriores.
class SolicitudProvider extends ChangeNotifier {
  SolicitudProvider(this._repo);

  final SolicitudesRepository _repo;

  SolicitudVisita? _solicitud;
  bool _cargando = false;
  String? error;

  SolicitudVisita? get solicitud => _solicitud;
  bool get cargando => _cargando;

  /// Envia la solicitud para el anuncio dado.
  ///
  /// Si ya existe una solicitud para ese anuncio, el backend devuelve un error
  /// que se muestra en [error].
  Future<bool> enviar(int anuncioId) async {
    _cargando = true;
    error = null;
    notifyListeners();

    try {
      _solicitud = await _repo.crearSolicitud(anuncioId);
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      return false;
    } catch (_) {
      error = 'No se pudo enviar la solicitud.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Refresca el estado de la solicitud desde el servidor.
  ///
  /// Sirve para que el inquilino vea cuando el propietario la aprobo.
  Future<void> refrescar() async {
    if (_solicitud == null) return;
    _cargando = true;
    notifyListeners();

    try {
      _solicitud = await _repo.solicitud(_solicitud!.id);
    } on ApiException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No se pudo actualizar el estado.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void setSolicitud(SolicitudVisita s) {
    _solicitud = s;
    notifyListeners();
  }
}
