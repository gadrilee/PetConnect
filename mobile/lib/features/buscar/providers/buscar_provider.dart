import 'package:flutter/foundation.dart';

import '../../../core/api_client.dart';
import '../../anuncios/data/anuncio.dart';
import '../data/solicitudes_repository.dart';

/// Filtros activos en la pantalla de busqueda.
class FiltrosBusqueda {
  const FiltrosBusqueda({
    this.precioMax,
    this.tipoEspacio,
    this.aceptaMascotas,
    this.minutosMax,
  });

  final double? precioMax;
  final TipoEspacio? tipoEspacio;
  final bool? aceptaMascotas;
  final int? minutosMax;
}

/// Maneja los filtros, la busqueda y la lista de resultados.
///
/// Se crea fresco por cada sesion de busqueda para no arrastrar estado viejo.
class BuscarProvider extends ChangeNotifier {
  BuscarProvider(this._repo);

  final SolicitudesRepository _repo;

  List<Anuncio> _resultados = [];
  bool _cargando = false;
  String? error;
  bool _busquedaRealizada = false;

  List<Anuncio> get resultados => _resultados;
  bool get cargando => _cargando;
  bool get busquedaRealizada => _busquedaRealizada;

  Future<void> buscar(FiltrosBusqueda filtros) async {
    _cargando = true;
    error = null;
    notifyListeners();

    try {
      _resultados = await _repo.buscar(
        precioMax: filtros.precioMax,
        tipoEspacio: filtros.tipoEspacio,
        aceptaMascotas: filtros.aceptaMascotas,
        minutosMax: filtros.minutosMax,
      );
      _busquedaRealizada = true;
    } on ApiException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No se pudieron cargar los anuncios.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
