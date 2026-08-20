import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  final api = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository(api))..restaurarSesion(),
        ),
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
      EstadoSesion.autenticado => const HomeScreen(),
    };
  }
}
