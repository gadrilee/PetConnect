import 'package:image_picker/image_picker.dart';

/// De donde sale la foto de perfil.
enum OrigenFoto { camara, galeria }

/// Consigue una foto y devuelve la ruta del archivo en el telefono, o `null`
/// si la persona se arrepintio. Si no se puede abrir la camara o la galeria
/// (sin permiso, sin camara), tira la excepcion del sistema.
typedef ElegirFoto = Future<String?> Function(OrigenFoto origen);

/// La de verdad: la camara o la galeria del telefono.
///
/// La foto se achica aca, antes de subirla: 1024 px y calidad 85 alcanzan
/// para un avatar de 96, y asi sube rapido aun con datos moviles. La camara
/// arranca en la frontal porque es una foto de uno mismo.
Future<String?> elegirFotoDelTelefono(OrigenFoto origen) async {
  final archivo = await ImagePicker().pickImage(
    source: origen == OrigenFoto.camara ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.front,
  );
  return archivo?.path;
}
