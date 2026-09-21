import '../../../core/enlace_externo.dart';

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
    this.lat,
    this.lng,
    this.fotos = const [],
    this.solicitudesPendientes = 0,
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

  /// Donde queda. Solo viene en el detalle: las listas no lo necesitan y el
  /// backend ya manda calculados los minutos caminando a la UAGRM.
  final double? lat;
  final double? lng;

  final List<FotoAnuncio> fotos;

  /// Cuantas solicitudes esperan respuesta. Solo viene en Mis anuncios, que
  /// es de la duena: marcar el cuarto como alquilado las cierra, y si hay
  /// alguna eso se confirma antes (flujo v0.5).
  final int solicitudesPendientes;

  bool get estaDisponible => estado == EstadoAnuncio.disponible;

  /// El mapa de este anuncio, o `null` si la API no mando donde queda.
  ///
  /// Lo arma el anuncio y no la pantalla: quien muestre la ubicacion en otro
  /// lado abre el mismo mapa, sin volver a escribir la direccion.
  Uri? get mapa {
    final (y, x) = (lat, lng);
    return y == null || x == null ? null : mapaDeGoogle(y, x);
  }

  /// La foto que representa al anuncio en una tarjeta, o `null` si no tiene.
  ///
  /// Es siempre la primera, que es la que el backend manda en las listas.
  /// Estaba escrito igual en cuatro pantallas; con el getter, quien dibuje
  /// una tarjeta nueva no tiene que acordarse de la regla.
  String? get fotoPrincipal => fotos.isEmpty ? null : fotos.first.imagen;

  /// Las fotos vengan como vengan.
  ///
  /// El detalle del anuncio manda la lista completa en `fotos`. Las listas
  /// —resultados de la busqueda, mis anuncios, el historial de solicitudes—
  /// mandan solo la primera, en `foto_principal`, para no arrastrar diez
  /// fotos por tarjeta. Leer una sola de las dos formas es lo que dejaba las
  /// tarjetas con el icono gris aunque el anuncio tuviera fotos.
  static List<FotoAnuncio> _fotos(Map<String, dynamic> j) {
    final lista = j['fotos'] as List?;
    if (lista != null) {
      return lista
          .map((f) => FotoAnuncio.desdeJson(f as Map<String, dynamic>))
          .toList();
    }
    final principal = j['foto_principal'];
    if (principal is Map<String, dynamic>) {
      return [FotoAnuncio.desdeJson(principal)];
    }
    return const [];
  }

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
      // Vienen como numero: a veces con decimales y a veces redondo, que en
      // JSON llega como int. `num` toma los dos.
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      fotos: _fotos(j),
      solicitudesPendientes: j['solicitudes_pendientes'] as int? ?? 0,
    );
  }
}
