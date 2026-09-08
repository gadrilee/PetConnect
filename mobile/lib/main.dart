import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/propietario/data/anuncios_repository.dart';
import 'features/propietario/providers/mis_anuncios_provider.dart';
import 'features/acceso/data/auth_repository.dart';
import 'features/acceso/presentation/login_screen.dart';
import 'features/acceso/providers/auth_provider.dart';
import 'features/inquilina/data/solicitudes_repository.dart';
import 'features/inquilina/presentation/inicio_screen.dart';
import 'features/propietario/presentation/inicio_screen.dart';
import 'features/propietario/data/solicitudes_recibidas_repository.dart';

void main() {
  final api = ApiClient();
  final anuncios = AnunciosRepository(api);
  final solicitudes = SolicitudesRepository(api);
  final solicitudesRecibidas = SolicitudesRecibidasRepository(api);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<AnunciosRepository>.value(value: anuncios),
        Provider<SolicitudesRepository>.value(value: solicitudes),
        Provider<SolicitudesRecibidasRepository>.value(value: solicitudesRecibidas),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository(api))..restaurarSesion(),
        ),
        ChangeNotifierProvider(create: (_) => MisAnunciosProvider(anuncios)),
      ],
      child: const AlquilaMatchApp(),
    ),
  );
}

class AlquilaMatchApp extends StatelessWidget {
  const AlquilaMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlquilaMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: const _Puerta(),
    );
  }
}

/// Decide que se ve segun el estado de la sesion.
class _Puerta extends StatelessWidget {
  const _Puerta();

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AuthProvider>().estado;

    return switch (estado) {
      EstadoSesion.comprobando => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      EstadoSesion.sinSesion => const LoginScreen(),
      EstadoSesion.autenticado => Builder(builder: (context) {
          final perfil = context.watch<AuthProvider>().perfil;
          if (perfil == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return perfil.esPropietario ? const InicioPropietarioScreen() : const InicioInquilinaScreen();
        }),
    };
  }
}
