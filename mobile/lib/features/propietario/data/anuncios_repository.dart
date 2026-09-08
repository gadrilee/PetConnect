import '../../../core/api_client.dart';
import 'anuncio.dart';

/// Foto lista para subir: el archivo y el momento en que se tomo.
class FotoParaSubir {
  const FotoParaSubir({required this.ruta, required this.fechaCaptura});

  final String ruta;
  final DateTime fechaCaptura;
}

class AnunciosRepository {
  AnunciosRepository(this._api);

  final ApiClient _api;

  /// Publica el anuncio y despues sube las fotos.
  ///
  /// Van en dos pasos porque el anuncio se crea con JSON y las fotos necesitan
  /// `multipart`, y ademas cada foto se cuelga de un anuncio que ya existe.
  Future<Anuncio> publicar({
    required String titulo,
    required TipoEspacio tipoEspacio,
    required String precioAlquiler,
    required bool incluyeAgua,
    required bool incluyeLuz,
    required bool incluyeInternet,
    required String costoServiciosEstimado,
    required bool aceptaMascotas,
    required double lat,
    required double lng,
    String restricciones = '',
    String direccionReferencia = '',
    List<FotoParaSubir> fotos = const [],
  }) async {
    final creado = await _api.post('/api/anuncios/', cuerpo: {
      'titulo': titulo,
      'tipo_espacio': tipoEspacio.valor,
      'precio_alquiler': precioAlquiler,
      'incluye_agua': incluyeAgua,
      'incluye_luz': incluyeLuz,
      'incluye_internet': incluyeInternet,
      'costo_servicios_estimado': costoServiciosEstimado,
      'acepta_mascotas': aceptaMascotas,
      'restricciones': restricciones,
      'lat': lat,
      'lng': lng,
      'direccion_referencia': direccionReferencia,
    }) as Map<String, dynamic>;

    final id = creado['id'] as int;

    for (final foto in fotos) {
      await _api.postArchivo(
        '/api/anuncios/$id/fotos/',
        campo: 'imagen',
        rutaArchivo: foto.ruta,
        campos: {'fecha_captura': foto.fechaCaptura.toUtc().toIso8601String()},
      );
    }

    return detalle(id);
  }

  Future<Anuncio> detalle(int id) async {
    final datos = await _api.get('/api/anuncios/$id/') as Map<String, dynamic>;
    return Anuncio.desdeJson(datos);
  }

  /// Los anuncios del propietario, en cualquier estado.
  Future<List<Anuncio>> mios() async {
    final datos = await _api.get('/api/anuncios/mios/') as Map<String, dynamic>;
    return (datos['results'] as List)
        .map((a) => Anuncio.desdeJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Apagar el anuncio en un toque. Si cuesta mas que eso, no va a pasar.
  Future<Anuncio> marcarAlquilado(int id) async {
    final datos =
        await _api.post('/api/anuncios/$id/marcar_alquilado/') as Map<String, dynamic>;
    return Anuncio.desdeJson(datos);
  }

  Future<Anuncio> marcarDisponible(int id) async {
    final datos =
        await _api.post('/api/anuncios/$id/marcar_disponible/') as Map<String, dynamic>;
    return Anuncio.desdeJson(datos);
  }
}
