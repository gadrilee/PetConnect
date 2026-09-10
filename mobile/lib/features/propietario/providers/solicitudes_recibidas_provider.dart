import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../inquilina/data/solicitud.dart';
import '../data/solicitudes_recibidas_repository.dart';

/// Estado de la bandeja de solicitudes recibidas (flujo v0.4).
class SolicitudesRecibidasProvider extends ChangeNotifier {
  SolicitudesRecibidasProvider(this._repo);

  final SolicitudesRecibidasRepository _repo;

  List<SolicitudVisita> _solicitudes = [];
  bool _cargando = false;

  /// Las solicitudes que se estan aprobando o rechazando en este momento.
  final Set<int> _enCurso = {};

  String? error;

  /// Las pendientes primero, porque son las unicas que piden una decision.
  /// Dentro de cada grupo, la mas nueva arriba.
  List<SolicitudVisita> get solicitudes {
    final orden = [..._solicitudes];
    orden.sort((a, b) {
      if (a.estaPendiente != b.estaPendiente) return a.estaPendiente ? -1 : 1;
      return b.creadaEn.compareTo(a.creadaEn);
    });
    return orden;
  }

  bool get cargando => _cargando;

  /// Si la solicitud [id] se esta enviando. Mientras tanto sus acciones se
  /// apagan, para que un doble toque no mande dos pedidos.
  bool procesando(int id) => _enCurso.contains(id);

  SolicitudVisita? porId(int id) {
    for (final s in _solicitudes) {
      if (s.id == id) return s;
    }
    return null;
  }

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

  /// Aprobar libera el WhatsApp de la propietaria, y solo a esta persona.
  Future<bool> aprobar(int id) =>
      _responder(id, _repo.aprobar, 'Error al aprobar.');

  /// Rechazar cierra la solicitud sin abrir ninguna conversacion.
  Future<bool> rechazar(int id) =>
      _responder(id, _repo.rechazar, 'Error al rechazar.');

  Future<bool> _responder(
    int id,
    Future<SolicitudVisita> Function(int id) enviar,
    String siFalla,
  ) async {
    if (!_enCurso.add(id)) return false;
    error = null;
    notifyListeners();

    try {
      final actualizada = await enviar(id);
      final i = _solicitudes.indexWhere((s) => s.id == actualizada.id);
      if (i >= 0) _solicitudes[i] = actualizada;
      return true;
    } on ApiException catch (e) {
      error = e.mensaje;
      return false;
    } catch (_) {
      error = siFalla;
      return false;
    } finally {
      _enCurso.remove(id);
      notifyListeners();
    }
  }
}
