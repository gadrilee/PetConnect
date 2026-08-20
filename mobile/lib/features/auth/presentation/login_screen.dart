import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/aviso_error.dart';
import '../providers/auth_provider.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _verClave = false;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('AlquilaMatch', style: texto.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 8),
                    Text(
                      'Alquiler con las condiciones por delante.',
                      style: texto.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _usuario,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Escribí tu usuario'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _clave,
                      obscureText: !_verClave,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_verClave
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _verClave = !_verClave),
                        ),
                      ),
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Escribí tu contraseña'
                          : null,
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      AvisoError(mensaje: auth.error!),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.ocupado ? null : _entrar,
                      child: auth.ocupado
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
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
      ),
    );
  }
}

