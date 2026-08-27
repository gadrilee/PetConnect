import '../../../core/api_client.dart';
import '../../anuncios/data/anuncio.dart';
import 'solicitud.dart';

/// Repositorio del flujo del inquilino.
///
/// Cubre buscar anuncios con filtros y todo el ciclo de vida de una solicitud.
class SolicitudesRepository {
  SolicitudesRepository(this._api);

  final ApiClient _api;

  // ---------------------------------------------------------------- Busqueda

  /// Busca anuncios disponibles aplicando las cuatro condiciones de descarte.
  ///
  /// El backend ordena por minutos_caminando ASC, precio ASC. Los filtros
  /// son exactamente los del AnuncioFilter del backend.
  Future<List<Anuncio>> buscar({
    double? precioMax,
    TipoEspacio? tipoEspacio,
    bool? aceptaMascotas,
    int? minutosMax,
  }) async {
    final query = <String, String>{};
    if (precioMax != null) query['precio_max'] = precioMax.toStringAsFixed(0);
    if (tipoEspacio != null) query['tipo_espacio'] = tipoEspacio.valor;
    if (aceptaMascotas != null) query['acepta_mascotas'] = aceptaMascotas.toString();
    if (minutosMax != null) query['minutos_max'] = minutosMax.toString();

    final datos = await _api.get('/api/anuncios/', query: query) as Map<String, dynamic>;
    final lista = datos['results'] as List? ?? [];
    return lista
        .map((a) => Anuncio.desdeJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Detalle completo de un anuncio (fotos, restricciones, servicios).
  Future<Anuncio> detalle(int id) async {
    final datos = await _api.get('/api/anuncios/$id/') as Map<String, dynamic>;
    return Anuncio.desdeJson(datos);
  }

  // -------------------------------------------------------------- Solicitudes

  /// Enviar una solicitud aceptando las condiciones. El backend valida que
  /// condiciones_aceptadas sea true antes de crear la solicitud.
  Future<SolicitudVisita> crearSolicitud(int anuncioId) async {
    final datos = await _api.post('/api/solicitudes/', cuerpo: {
      'anuncio': anuncioId,
      'condiciones_aceptadas': true,
    }) as Map<String, dynamic>;
    return SolicitudVisita.desdeJson(datos);
  }

  /// Las solicitudes del inquilino autenticado, ordenadas por fecha desc.
  Future<List<SolicitudVisita>> misSolicitudes() async {
    final datos = await _api.get('/api/solicitudes/') as Map<String, dynamic>;
    final lista = datos['results'] as List? ?? [];
    return lista
        .map((s) => SolicitudVisita.desdeJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Solicitud especifica por ID. Util para refrescar el estado.
  Future<SolicitudVisita> solicitud(int id) async {
    final datos = await _api.get('/api/solicitudes/$id/') as Map<String, dynamic>;
    return SolicitudVisita.desdeJson(datos);
  }
}
