import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../providers/auth_provider.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;
  // Mensajes de error por campo: null = válido.
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
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    // Si el backend devuelve error, lo mostramos en el campo de contraseña.
    final errorBackend = auth.error;

    return Scaffold(
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
                  Text(
                    'AlquilaMatch',
                    style: texto.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Espacio.sm),
                  Text(
                    'Alquiler con las condiciones por delante.',
                    style: texto.bodyMedium
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),

                  const SizedBox(height: Espacio.xl),

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
                        color: esquema.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _verClave = !_verClave),
                    ),
                  ),

                  const SizedBox(height: Espacio.lg),

                  // ---- Botón entrar ----
                  BotonPrincipal(
                    etiqueta: 'ENTRAR',
                    etiquetaCargando: 'ENTRANDO...',
                    alTocar: auth.ocupado ? null : _entrar,
                    cargando: auth.ocupado,
                  ),

                  const SizedBox(height: Espacio.sm),

                  TextButton(
                    onPressed: auth.ocupado
                        ? null
                        : () {
                            context.read<AuthProvider>().limpiarError();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RegistroScreen(),
                            ));
                          },
                    child: const Text('No tengo cuenta'),
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
