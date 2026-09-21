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

  /// Lo que se dice cuando falta la ubicacion (Figma "04 Falta la
  /// ubicación"). La pantalla lo muestra como advertencia, no como error:
  /// falta un paso, no fallo nada.
  static const String faltaUbicacion =
      'Falta marcar la ubicación del inmueble. Tocá Usar GPS.';

  /// Lo que se dice cuando el envio no llego a buen puerto por la red o por
  /// el servidor caido (Figma "05 No se pudo publicar"). Es un error: la
  /// pantalla deja el boton prendido para reintentar. Lo que el backend
  /// objeta de un campo no va aca: va en [erroresPorCampo], debajo del campo.
  static const String noSePudoPublicar =
      'No se pudo publicar. Revisá tu conexión e intentá de nuevo.';

  /// Una vez marcada la ubicacion, la advertencia de que faltaba ya no vale.
  void _olvidarFaltaUbicacion() {
    if (error == faltaUbicacion) error = null;
  }

  /// La persona corrigio el campo: lo que el backend le habia objetado ya no
  /// describe lo que hay escrito. Sin esto el campo seguiria en rojo y el
  /// boton apagado hasta el proximo envio, que justamente no se podria hacer.
  void olvidarErrorDeCampo(String campo) {
    if (!erroresPorCampo.containsKey(campo)) return;
    erroresPorCampo = Map.of(erroresPorCampo)..remove(campo);
    notifyListeners();
  }

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
      _olvidarFaltaUbicacion();
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
    _olvidarFaltaUbicacion();
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

      fotos.add(FotoParaSubir(
        nombre: archivo.name,
        bytes: await archivo.readAsBytes(),
        fechaCaptura: DateTime.now(),
      ));
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
      error = faltaUbicacion;
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
      // Cada fallo se cuenta en un solo lugar, nunca en dos. `error` y
      // `erroresPorCampo` no se llenan a la vez.
      if (e.porCampo.isNotEmpty) {
        // El backend objeto campos concretos (400): eso se pinta en rojo
        // debajo de cada campo y el pie cuenta cuantos son. No fallo la
        // conexion, asi que decir "revisá tu conexión" seria mentir.
        erroresPorCampo = e.porCampo;
      } else if (e.codigo != null && e.codigo! < 500) {
        // El backend rechazo el pedido entero y dijo por que (sin permiso,
        // sesion vencida): se repite lo que dijo.
        error = e.mensaje;
      } else {
        // Sin red o con el servidor caido: no se publico, y la persona puede
        // reintentar (Figma "05 No se pudo publicar").
        error = noSePudoPublicar;
      }
      return null;
    } catch (e) {
      error = noSePudoPublicar;
      return null;
    } finally {
      _publicando = false;
      notifyListeners();
    }
  }
}
