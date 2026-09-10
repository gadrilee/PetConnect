import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_texto.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/logo_alquilamatch.dart';
import '../providers/auth_provider.dart';
import 'elegir_rol_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();

  // Mensajes de error locales por campo: null = válido.
  String? _errorUsuario;
  String? _errorClave;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  bool _validar() {
    bool ok = true;
    setState(() {
      _errorUsuario =
          _usuario.text.trim().isEmpty ? 'Escribí tu usuario' : null;
      _errorClave = _clave.text.isEmpty ? 'Escribí tu contraseña' : null;
      ok = _errorUsuario == null && _errorClave == null;
    });
    return ok;
  }

  Future<void> _entrar() async {
    if (!_validar()) return;
    FocusScope.of(context).unfocus();
    await context.read<AuthProvider>().login(
          username: _usuario.text.trim(),
          password: _clave.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Si el backend devuelve error general, lo pasamos al campo de contraseña
    final errorBackend = auth.error;

    // CONSTRAINTS: la Pagina centra el formulario en los dos ejes y lo deja
    // con el ancho de formulario, igual que en el registro.
    return Pagina(
      ancho: AnchoPagina.formulario,
      centrarVertical: true,
      hijos: [
        const LogoAlquilaMatch(),
        const SizedBox(height: Espacio.sm),
        Text(
          'Alquiler con las condiciones por delante.',
          textAlign: TextAlign.center,
          style: AppText.body(context).copyWith(
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: Espacio.xxl),
        CampoTexto(
          etiqueta: 'Usuario',
          controlador: _usuario,
          icono: Icons.person_outline,
          mensajeError: _errorUsuario,
          accionTeclado: TextInputAction.next,
          alEnviar: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Contraseña',
          controlador: _clave,
          icono: Icons.lock_outline,
          esClave: true,
          mensajeError: _errorClave ?? errorBackend,
          accionTeclado: TextInputAction.done,
          alEnviar: (_) => _entrar(),
        ),
        const SizedBox(height: Espacio.xl),
        BotonPrincipal(
          etiqueta: 'ENTRAR',
          etiquetaCargando: 'ENTRANDO...',
          alTocar: auth.ocupado ? null : _entrar,
          cargando: auth.ocupado,
        ),
        const SizedBox(height: Espacio.md),
        BotonTexto(
          etiqueta: 'No tengo cuenta',
          alTocar: auth.ocupado
              ? null
              : () {
                  context.read<AuthProvider>().limpiarError();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ElegirRolScreen()),
                  );
                },
        ),
      ],
    );
  }
}
