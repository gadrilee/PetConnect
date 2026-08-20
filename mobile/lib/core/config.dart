/// Configuracion del entorno.
class Config {
  /// Base de la API.
  ///
  /// `10.0.2.2` es como el emulador de Android ve el `localhost` de la maquina
  /// anfitriona: dentro del emulador, `localhost` es el propio Android.
  ///
  /// En un telefono fisico hay que pasar la IP de la maquina en la red local:
  ///
  ///     flutter run --dart-define=API_URL=http://192.168.1.42:8000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
