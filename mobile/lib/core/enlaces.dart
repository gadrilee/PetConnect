import 'package:flutter/material.dart';

import '../features/acceso/presentation/nueva_contrasena_screen.dart';

/// Los enlaces que abren la app desde afuera.
///
/// Hoy hay uno: el del correo de recuperacion,
/// `alquilamatch://app/recuperar?uid=…&token=…`. Android se lo pasa a Flutter
/// como la ruta `/recuperar?uid=…&token=…`, y aca se convierte en la pantalla
/// "Nueva contraseña". Va con el host `app` porque Flutter arma la ruta con el
/// path del enlace: en `alquilamatch://recuperar` la palabra quedaria como
/// host y se perderia.
///
/// Devuelve `null` para cualquier otra ruta, y el `MaterialApp` sigue con su
/// pantalla de inicio.
Route<dynamic>? rutaDesdeEnlace(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');
  if (uri == null || uri.path != '/recuperar') return null;

  final uid = uri.queryParameters['uid'];
  final token = uri.queryParameters['token'];
  if (uid == null || uid.isEmpty || token == null || token.isEmpty) return null;

  return MaterialPageRoute(
    settings: settings,
    builder: (_) => NuevaContrasenaScreen(uid: uid, token: token),
  );
}
