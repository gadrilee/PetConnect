import 'package:url_launcher/url_launcher.dart';

/// Lo que la app abre afuera: WhatsApp, el mapa, el navegador.
///
/// Devuelve `false` cuando el aparato no tiene con qué abrirlo. La excepcion
/// se trata igual que ese `false`: para la persona es el mismo "no se pudo",
/// y no hay motivo para que la pantalla tenga dos caminos de error para lo
/// mismo. Cada pantalla lo cuenta con sus palabras, en su pie.
Future<bool> abrirEnlaceExterno(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// El mapa con el punto marcado.
///
/// Es la direccion universal de Google Maps: en el telefono abre la app si
/// esta instalada, y si no, el navegador; en la web abre una pestana. Por eso
/// no se usa `geo:`, que solo existe en Android.
Uri mapaDeGoogle(double lat, double lng) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
