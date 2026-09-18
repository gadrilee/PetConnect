import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/solicitud.dart';
import '../data/solicitudes_repository.dart';

class MisSolicitudesProvider extends ChangeNotifier {
  MisSolicitudesProvider(this._repo);

  final SolicitudesRepository _repo;

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
      _solicitudes = await _repo.misSolicitudes();
    } on ApiException catch (e) {
      error = e.motivo;
    } catch (_) {
      error = ApiException.sinRespuesta;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
