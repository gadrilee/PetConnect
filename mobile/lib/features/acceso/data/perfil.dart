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
  const Perfil({
    required this.username,
    required this.rol,
    this.whatsapp = '',
    this.email = '',
    this.foto,
  });

  final String username;
  final Rol rol;

  /// El dato que la app protege: no viaja en ningun anuncio. Solo se libera
  /// cuando el propietario aprueba una solicitud de visita.
  final String whatsapp;

  /// Con lo que se recupera la cuenta. Se muestra en Mi perfil pero no se
  /// cambia desde ahi: cambiarlo pide confirmar la direccion nueva.
  final String email;

  /// La direccion de la foto de perfil, ya lista para mostrar. `null` si no
  /// puso ninguna: la app muestra el icono del rol.
  final String? foto;

  bool get esPropietario => rol == Rol.propietario;

  bool get tieneFoto => foto != null && foto!.isNotEmpty;

  factory Perfil.desdeJson(Map<String, dynamic> json) {
    return Perfil(
      username: json['username'] as String? ?? '',
      rol: Rol.desdeApi(json['rol'] as String? ?? 'INQUILINO'),
      whatsapp: json['whatsapp'] as String? ?? '',
      email: json['email'] as String? ?? '',
      foto: json['foto'] as String?,
    );
  }
}
