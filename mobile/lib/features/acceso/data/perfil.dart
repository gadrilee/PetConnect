/// Los dos actores del sistema. Se elige al registrarse y decide que ve cada
/// quien: el propietario publica, la inquilina busca.
enum Rol {
  inquilino('INQUILINO', 'Inquilino'),
  propietario('PROPIETARIO', 'Propietario');

  const Rol(this.valor, this.etiqueta);

  /// Valor que entiende la API.
  final String valor;

  /// Texto para mostrar en pantalla.
  final String etiqueta;

  static Rol desdeApi(String valor) {
    return Rol.values.firstWhere(
      (r) => r.valor == valor,
      orElse: () => Rol.inquilino,
    );
  }
}

class Perfil {
  const Perfil({required this.username, required this.rol, this.whatsapp = ''});

  final String username;
  final Rol rol;

  /// El dato que la app protege: no viaja en ningun anuncio. Solo se libera
  /// cuando el propietario aprueba una solicitud de visita.
  final String whatsapp;

  bool get esPropietario => rol == Rol.propietario;

  factory Perfil.desdeJson(Map<String, dynamic> json) {
    return Perfil(
      username: json['username'] as String? ?? '',
      rol: Rol.desdeApi(json['rol'] as String? ?? 'INQUILINO'),
      whatsapp: json['whatsapp'] as String? ?? '',
    );
  }
}
