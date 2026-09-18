import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter_localizations/flutter_localizations.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // En la web Flutter dibuja en un canvas y no arma el arbol de semantica
  // hasta que alguien lo pide: un lector de pantalla o un escaner (Lighthouse
  // veia 17 auditorias aplicables y 49 "no aplica") no encuentran nada hasta
  // tocar un boton escondido. Pedirlo al arrancar deja el DOM de semantica
  // siempre disponible. En un telefono el sistema lo pide solo cuando hace
  // falta.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();

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

  /// El idioma de la app. Con el, los nombres que pone Material solo —la
  /// flecha de volver, el menu de copiar y pegar, los dialogos— se anuncian
  /// en castellano y no en ingles. Las pruebas montan las pantallas con el
  /// mismo idioma y los mismos delegados, para probar lo que se anuncia.
  static const Locale idioma = Locale('es');

  static const List<Locale> idiomas = [idioma];

  static const List<LocalizationsDelegate<dynamic>> delegados =
      GlobalMaterialLocalizations.delegates;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlquilaMatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      locale: idioma,
      supportedLocales: idiomas,
      localizationsDelegates: delegados,
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
          final auth = context.watch<AuthProvider>();
          final perfil = auth.perfil;
          if (perfil == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          // Lo que hay que contar al entrar ("Cuenta creada con éxito") viaja
          // por el provider: no hay ruta por donde pasarlo, porque esta puerta
          // reemplaza la raiz. El inicio lo muestra en su pie y lo da por
          // visto cuando la persona sigue a otra pantalla.
          final aviso = auth.avisoInicial;
          return perfil.esPropietario
              ? InicioPropietarioScreen(avisoInicial: aviso)
              : InicioInquilinaScreen(avisoInicial: aviso);
        }),
    };
  }
}
