import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../buscar/data/solicitud.dart';
import '../data/solicitudes_recibidas_repository.dart';

class SolicitudesRecibidasProvider extends ChangeNotifier {
  SolicitudesRecibidasProvider(this._repo);

  final SolicitudesRecibidasRepository _repo;

  List<SolicitudVisita> _solicitudes = [];
  bool _cargando = false;
  String? error;

  List<SolicitudVisita> get solicitudes => _solicitudes;
  bool get cargando => _cargando;

  Future<void> cargar() async {
    _cargando = true;
    error = null;
    notifyListeners();

    try {
      _solicitudes = await _repo.obtenerTodas();
    } on ApiException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No se pudieron cargar las solicitudes.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> aprobar(int id) async {
    try {
      final actualizada = await _repo.aprobar(id);
      _actualizarEnLista(actualizada);
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Error al aprobar.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rechazar(int id) async {
    try {
      final actualizada = await _repo.rechazar(id);
      _actualizarEnLista(actualizada);
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      error = 'Error al rechazar.';
      notifyListeners();
      return false;
    }
  }

  void _actualizarEnLista(SolicitudVisita s) {
    final i = _solicitudes.indexWhere((x) => x.id == s.id);
    if (i >= 0) {
      _solicitudes[i] = s;
      notifyListeners();
    }
  }
}
