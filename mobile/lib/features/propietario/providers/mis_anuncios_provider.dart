import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../data/anuncio.dart';
import '../data/anuncios_repository.dart';

class MisAnunciosProvider extends ChangeNotifier {
  MisAnunciosProvider(this._repo);

  final AnunciosRepository _repo;

  List<Anuncio> _anuncios = [];
  bool _cargando = false;
  String? error;

  /// Lo que acaba de pasar, para contarlo en el pie: que salio de la busqueda
  /// y cuantas solicitudes se cerraron, o que volvio a publicarse.
  String? aviso;

  /// El anuncio que se esta cambiando: su boton no acepta un segundo toque.
  int? _cambiando;

  List<Anuncio> get anuncios => _anuncios;
  bool get cargando => _cargando;
  bool cambiando(int id) => _cambiando == id;

  /// Lo que se leyo ya no se vuelve a mostrar: al refrescar, o al abrir la
  /// confirmacion, que no tiene que arrancar con el error de otro intento.
  void limpiarMensajes() {
    error = null;
    aviso = null;
    notifyListeners();
  }

  Future<void> cargar() async {
    _cargando = true;
    error = null;
    notifyListeners();

    try {
      _anuncios = await _repo.mios();
    } on ApiException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No se pudieron cargar tus anuncios.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Sacar el cuarto de la busqueda. El backend cierra las solicitudes que
  /// seguian pendientes y dice cuantas: eso es lo que libera a la propietaria
  /// de los mensajes (evidencia 8), asi que se le cuenta.
  Future<bool> marcarAlquilado(Anuncio anuncio) => _cambiar(
        anuncio,
        fallo: 'No se pudo marcar como alquilado. Revisá tu conexión y probá de nuevo.',
        accion: () async {
          final r = await _repo.marcarAlquilado(anuncio.id);
          aviso = switch (r.cerradas) {
            0 => 'Salió de la búsqueda.',
            1 => 'Salió de la búsqueda. Cerramos 1 solicitud y le avisamos.',
            final n => 'Salió de la búsqueda. Cerramos $n solicitudes y les avisamos.',
          };
          return r.anuncio;
        },
      );

  /// El inquilino se fue: vuelve a la busqueda en un toque, con los mismos
  /// datos. Volver a publicar no puede costar lo mismo que publicar de cero.
  Future<bool> volverAPublicar(Anuncio anuncio) => _cambiar(
        anuncio,
        fallo: 'No se pudo volver a publicar. Sigue como alquilado; probá de nuevo.',
        accion: () async {
          final actualizado = await _repo.marcarDisponible(anuncio.id);
          aviso = 'Volvió a la búsqueda. Ya pueden encontrarlo de nuevo.';
          return actualizado;
        },
      );

  /// El cambio se refleja en la lista sin recargarla entera: tiene que costar
  /// un solo toque, o no va a pasar.
  Future<bool> _cambiar(
    Anuncio anuncio, {
    required String fallo,
    required Future<Anuncio> Function() accion,
  }) async {
    error = null;
    aviso = null;
    _cambiando = anuncio.id;
    notifyListeners();

    try {
      final actualizado = await accion();
      final i = _anuncios.indexWhere((a) => a.id == anuncio.id);
      if (i != -1) _anuncios[i] = actualizado;
      return true;
    } catch (_) {
      error = fallo;
      return false;
    } finally {
      _cambiando = null;
      notifyListeners();
    }
  }
}
