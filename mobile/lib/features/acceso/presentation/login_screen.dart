import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/boton_principal.dart';
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
  bool _verClave = false;
  
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
      _errorClave =
          _clave.text.isEmpty ? 'Escribí tu contraseña' : null;
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacio.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  // ---- Usuario ----
                  CampoTexto(
                    etiqueta: 'Usuario',
                    controlador: _usuario,
                    icono: Icons.person_outline,
                    mensajeError: _errorUsuario,
                    accionTeclado: TextInputAction.next,
                    alEnviar: (_) => FocusScope.of(context).nextFocus(),
                  ),

                  const SizedBox(height: Espacio.md),

                  // ---- Contraseña ----
                  CampoTexto(
                    etiqueta: 'Contraseña',
                    controlador: _clave,
                    icono: Icons.lock_outline,
                    ocultarTexto: !_verClave,
                    mensajeError: _errorClave ?? errorBackend,
                    accionTeclado: TextInputAction.done,
                    alEnviar: (_) => _entrar(),
                    sufijo: IconButton(
                      icon: Icon(
                        _verClave
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.text.withValues(alpha: 0.5),
                      ),
                      onPressed: () =>
                          setState(() => _verClave = !_verClave),
                    ),
                  ),

                  const SizedBox(height: Espacio.xl),

                  // ---- Botón entrar ----
                  BotonPrincipal(
                    etiqueta: 'ENTRAR',
                    etiquetaCargando: 'ENTRANDO...',
                    alTocar: auth.ocupado ? null : _entrar,
                    cargando: auth.ocupado,
                  ),

                  const SizedBox(height: Espacio.md),

                  // ---- Botón registro ----
                  TextButton(
                    onPressed: auth.ocupado
                        ? null
                        : () {
                            context.read<AuthProvider>().limpiarError();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const ElegirRolScreen(),
                            ));
                          },
                    child: Text(
                      'No tengo cuenta',
                      style: AppText.button(context).copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
