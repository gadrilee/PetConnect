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

  List<Anuncio> get anuncios => _anuncios;
  bool get cargando => _cargando;

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

  /// Cambiar el estado tiene que costar un solo toque, o no va a pasar.
  /// Por eso el cambio se refleja en la lista sin recargarla entera.
  Future<void> alternarEstado(Anuncio anuncio) async {
    try {
      final actualizado = anuncio.estaDisponible
          ? await _repo.marcarAlquilado(anuncio.id)
          : await _repo.marcarDisponible(anuncio.id);

      final i = _anuncios.indexWhere((a) => a.id == anuncio.id);
      if (i != -1) _anuncios[i] = actualizado;
      notifyListeners();
    } on ApiException catch (e) {
      error = e.mensaje;
      notifyListeners();
    }
  }
}
