/// Tipos de espacio que se pueden publicar. Es una de las cuatro condiciones
/// de descarte del Brief v0.2.0.
enum TipoEspacio {
  habitacion('HABITACION', 'Habitación'),
  departamento('DEPARTAMENTO', 'Departamento'),
  casa('CASA', 'Casa');

  const TipoEspacio(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoEspacio desdeApi(String v) => TipoEspacio.values.firstWhere(
        (t) => t.valor == v,
        orElse: () => TipoEspacio.habitacion,
      );
}

enum EstadoAnuncio {
  disponible('DISPONIBLE', 'Disponible'),
  alquilado('ALQUILADO', 'Ya alquilado');

  const EstadoAnuncio(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoAnuncio desdeApi(String v) => EstadoAnuncio.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => EstadoAnuncio.disponible,
      );
}

class FotoAnuncio {
  const FotoAnuncio({required this.imagen, required this.fechaCaptura});

  final String imagen;

  /// Cuando se **tomo** la foto, no cuando se subio. Es lo que ataca las
  /// fotos viejas de los anuncios de hoy.
  final DateTime fechaCaptura;

  factory FotoAnuncio.desdeJson(Map<String, dynamic> j) => FotoAnuncio(
        imagen: j['imagen'] as String? ?? '',
        fechaCaptura:
            DateTime.tryParse(j['fecha_captura'] as String? ?? '') ?? DateTime(2000),
      );
}

/// Un anuncio tal como lo devuelve la API.
///
/// Nunca trae el telefono del propietario: el unico camino al contacto es una
/// solicitud de visita aprobada.
class Anuncio {
  const Anuncio({
    required this.id,
    required this.titulo,
    required this.tipoEspacio,
    required this.precioFinal,
    required this.aceptaMascotas,
    required this.minutosCaminando,
    required this.estado,
    this.precioAlquiler,
    this.costoServicios,
    this.serviciosIncluidos = const {},
    this.restricciones = '',
    this.direccionReferencia = '',
    this.fotos = const [],
  });

  final int id;
  final String titulo;
  final TipoEspacio tipoEspacio;

  /// Alquiler + servicios que se pagan aparte. Es el criterio de descarte n.º 1.
  final String precioFinal;

  final bool aceptaMascotas;
  final int minutosCaminando;
  final EstadoAnuncio estado;

  final String? precioAlquiler;
  final String? costoServicios;
  final Map<String, bool> serviciosIncluidos;
  final String restricciones;
  final String direccionReferencia;
  final List<FotoAnuncio> fotos;

  bool get estaDisponible => estado == EstadoAnuncio.disponible;

  factory Anuncio.desdeJson(Map<String, dynamic> j) {
    final servicios = j['servicios_incluidos'];
    return Anuncio(
      id: j['id'] as int,
      titulo: j['titulo'] as String? ?? '',
      tipoEspacio: TipoEspacio.desdeApi(j['tipo_espacio'] as String? ?? ''),
      precioFinal: j['precio_final']?.toString() ?? '0',
      aceptaMascotas: j['acepta_mascotas'] as bool? ?? false,
      minutosCaminando: j['minutos_caminando'] as int? ?? 0,
      estado: EstadoAnuncio.desdeApi(j['estado'] as String? ?? ''),
      precioAlquiler: j['precio_alquiler']?.toString(),
      costoServicios: j['costo_servicios_estimado']?.toString(),
      serviciosIncluidos: servicios is Map
          ? servicios.map((k, v) => MapEntry(k.toString(), v == true))
          : const {},
      restricciones: j['restricciones'] as String? ?? '',
      direccionReferencia: j['direccion_referencia'] as String? ?? '',
      fotos: (j['fotos'] as List?)
              ?.map((f) => FotoAnuncio.desdeJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
