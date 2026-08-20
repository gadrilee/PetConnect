import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api_client.dart';
import '../data/anuncio.dart';
import '../data/anuncios_repository.dart';

/// Estado del formulario de publicar.
///
/// La ubicacion y las fotos no son campos de texto: se capturan con el
/// telefono estando en el inmueble. Por eso viven aca y no en el widget.
class PublicarProvider extends ChangeNotifier {
  PublicarProvider(this._repo);

  final AnunciosRepository _repo;
  final ImagePicker _camara = ImagePicker();

  // --- Ubicacion ---
  double? lat;
  double? lng;
  bool _buscandoUbicacion = false;
  String? errorUbicacion;

  bool get buscandoUbicacion => _buscandoUbicacion;
  bool get hayUbicacion => lat != null && lng != null;

  // --- Fotos ---
  final List<FotoParaSubir> fotos = [];

  // --- Envio ---
  bool _publicando = false;
  String? error;
  Map<String, String> erroresPorCampo = const {};

  bool get publicando => _publicando;

  /// Toma la ubicacion del GPS. Se espera que el propietario este parado en el
  /// inmueble: de esa coordenada sale el calculo de minutos caminando.
  Future<void> tomarUbicacion() async {
    _buscandoUbicacion = true;
    errorUbicacion = null;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        errorUbicacion = 'Prendé la ubicación del teléfono para marcar el inmueble.';
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        errorUbicacion = 'Sin permiso de ubicación no se puede marcar el inmueble.';
        return;
      }
      if (permiso == LocationPermission.deniedForever) {
        errorUbicacion =
            'El permiso de ubicación está bloqueado. Hay que habilitarlo desde '
            'los ajustes del teléfono.';
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      lat = posicion.latitude;
      lng = posicion.longitude;
    } catch (e) {
      errorUbicacion = 'No se pudo obtener la ubicación. Intentá de nuevo.';
    } finally {
      _buscandoUbicacion = false;
      notifyListeners();
    }
  }

  /// Ajuste manual, para cuando el GPS deja el pin corrido.
  void fijarUbicacionManual(double nuevaLat, double nuevoLng) {
    lat = nuevaLat;
    lng = nuevoLng;
    errorUbicacion = null;
    notifyListeners();
  }

  /// Saca una foto con la camara. La fecha de captura es **ahora**: esa es la
  /// garantia de que la foto corresponde al estado actual del inmueble.
  Future<void> agregarFoto() async {
    try {
      final archivo = await _camara.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (archivo == null) return;

      fotos.add(FotoParaSubir(ruta: archivo.path, fechaCaptura: DateTime.now()));
      notifyListeners();
    } catch (e) {
      error = 'No se pudo abrir la cámara.';
      notifyListeners();
    }
  }

  void quitarFoto(int indice) {
    fotos.removeAt(indice);
    notifyListeners();
  }

  Future<Anuncio?> publicar({
    required String titulo,
    required TipoEspacio tipoEspacio,
    required String precioAlquiler,
    required bool incluyeAgua,
    required bool incluyeLuz,
    required bool incluyeInternet,
    required String costoServiciosEstimado,
    required bool aceptaMascotas,
    String restricciones = '',
    String direccionReferencia = '',
  }) async {
    if (!hayUbicacion) {
      error = 'Falta marcar la ubicación del inmueble.';
      notifyListeners();
      return null;
    }

    _publicando = true;
    error = null;
    erroresPorCampo = const {};
    notifyListeners();

    try {
      return await _repo.publicar(
        titulo: titulo,
        tipoEspacio: tipoEspacio,
        precioAlquiler: precioAlquiler,
        incluyeAgua: incluyeAgua,
        incluyeLuz: incluyeLuz,
        incluyeInternet: incluyeInternet,
        costoServiciosEstimado: costoServiciosEstimado,
        aceptaMascotas: aceptaMascotas,
        restricciones: restricciones,
        direccionReferencia: direccionReferencia,
        lat: lat!,
        lng: lng!,
        fotos: List.of(fotos),
      );
    } on ApiException catch (e) {
      error = e.mensaje;
      erroresPorCampo = e.porCampo;
      return null;
    } catch (e) {
      error = 'Ocurrió un error inesperado al publicar.';
      return null;
    } finally {
      _publicando = false;
      notifyListeners();
    }
  }
}
