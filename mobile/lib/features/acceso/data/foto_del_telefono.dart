import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// De donde sale la foto de perfil.
enum OrigenFoto { camara, galeria }

/// Una foto ya elegida, lista para mostrar y para subir.
///
/// Lleva los **bytes**, no la ruta del archivo. En el telefono una ruta
/// alcanzaba, pero en la web el selector devuelve un `blob:` que `dart:io` no
/// sabe abrir: `MultipartFile.fromPath` e `Image.file` fallan, y el error caia
/// en el mismo `catch` que la falta de conexion. Resultado: "No se pudo subir
/// la foto. Revisá tu conexión" con la conexion perfecta.
class FotoElegida {
  const FotoElegida({required this.nombre, required this.bytes});

  /// Con su extension: el servidor valida que sea una imagen.
  final String nombre;
  final Uint8List bytes;
}

/// Consigue una foto, o `null` si la persona se arrepintio. Si no se puede
/// abrir la camara o la galeria (sin permiso, sin camara), tira la excepcion
/// del sistema.
typedef ElegirFoto = Future<FotoElegida?> Function(OrigenFoto origen);

/// La de verdad: la camara o la galeria del aparato.
///
/// La foto se achica aca, antes de subirla: 1024 px y calidad 85 alcanzan
/// para un avatar de 96, y asi sube rapido aun con datos moviles. La camara
/// arranca en la frontal porque es una foto de uno mismo.
Future<FotoElegida?> elegirFotoDelTelefono(OrigenFoto origen) async {
  final archivo = await ImagePicker().pickImage(
    source: origen == OrigenFoto.camara ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.front,
  );
  if (archivo == null) return null;
  return FotoElegida(nombre: archivo.name, bytes: await archivo.readAsBytes());
}
