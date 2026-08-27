import '../../../core/api_client.dart';
import '../../buscar/data/solicitud.dart';

/// Repositorio para que el propietario gestione las solicitudes recibidas.
class SolicitudesRecibidasRepository {
  SolicitudesRecibidasRepository(this._api);

  final ApiClient _api;

  /// Obtiene todas las solicitudes dirigidas a los anuncios de este propietario.
  Future<List<SolicitudVisita>> obtenerTodas() async {
    final datos = await _api.get('/api/solicitudes/') as Map<String, dynamic>;
    final lista = datos['results'] as List? ?? [];
    return lista
        .map((s) => SolicitudVisita.desdeJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Aprueba la solicitud y libera el contacto del propietario.
  Future<SolicitudVisita> aprobar(int id) async {
    final datos = await _api.post('/api/solicitudes/$id/aprobar/', cuerpo: {})
        as Map<String, dynamic>;
    return SolicitudVisita.desdeJson(datos);
  }

  /// Rechaza la solicitud.
  Future<SolicitudVisita> rechazar(int id) async {
    final datos = await _api.post('/api/solicitudes/$id/rechazar/', cuerpo: {})
        as Map<String, dynamic>;
    return SolicitudVisita.desdeJson(datos);
  }
}
