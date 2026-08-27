import '../../anuncios/data/anuncio.dart';

/// Estado de una solicitud de visita, tal como lo devuelve el backend.
enum EstadoSolicitud {
  pendiente('PENDIENTE', 'Pendiente'),
  aprobada('APROBADA', 'Aprobada'),
  rechazada('RECHAZADA', 'Rechazada');

  const EstadoSolicitud(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoSolicitud desdeApi(String v) => EstadoSolicitud.values.firstWhere(
        (e) => e.valor == v,
        orElse: () => EstadoSolicitud.pendiente,
      );
}

/// Una solicitud de visita tal como la devuelve la API.
///
/// El campo [contacto] es `null` mientras no haya aprobacion. Es la regla
/// central del producto: el WhatsApp no existe para el inquilino hasta que
/// el propietario aprueba.
class SolicitudVisita {
  const SolicitudVisita({
    required this.id,
    required this.anuncio,
    required this.estado,
    required this.creadaEn,
    this.contacto,
    this.respondidaEn,
  });

  final int id;
  final Anuncio anuncio;
  final EstadoSolicitud estado;
  final DateTime creadaEn;

  /// El WhatsApp del propietario, o null si la solicitud no fue aprobada aun.
  final String? contacto;
  final DateTime? respondidaEn;

  bool get estaAprobada => estado == EstadoSolicitud.aprobada;
  bool get estaPendiente => estado == EstadoSolicitud.pendiente;
  bool get estaRechazada => estado == EstadoSolicitud.rechazada;

  factory SolicitudVisita.desdeJson(Map<String, dynamic> j) {
    final anuncioJson = j['anuncio'] as Map<String, dynamic>? ?? {};
    return SolicitudVisita(
      id: j['id'] as int,
      anuncio: Anuncio.desdeJson(anuncioJson),
      estado: EstadoSolicitud.desdeApi(j['estado'] as String? ?? ''),
      creadaEn: DateTime.tryParse(j['creada_en'] as String? ?? '') ?? DateTime.now(),
      contacto: j['contacto'] as String?,
      respondidaEn: j['respondida_en'] != null
          ? DateTime.tryParse(j['respondida_en'] as String)
          : null,
    );
  }
}
