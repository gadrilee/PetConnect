import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/aviso_error.dart';
import '../data/perfil.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _whatsapp = TextEditingController();
  Rol? _rol;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    if (_rol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí si vas a buscar o a publicar.')),
      );
      return;
    }
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().registro(
          username: _usuario.text.trim(),
          password: _clave.text,
          rol: _rol!,
          whatsapp: _whatsapp.text.trim(),
        );

    // Si salio bien, main.dart cambia solo de pantalla al ver el estado.
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Qué vas a hacer en la app',
                        style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    _TarjetaRol(
                      titulo: 'Busco dónde alquilar',
                      detalle: 'Filtrás por precio final, mascotas y minutos '
                          'caminando a la UAGRM.',
                      icono: Icons.search,
                      elegido: _rol == Rol.inquilino,
                      onTap: () => setState(() => _rol = Rol.inquilino),
                    ),
                    const SizedBox(height: 10),
                    _TarjetaRol(
                      titulo: 'Quiero publicar',
                      detalle: 'Publicás una vez con las condiciones por '
                          'delante y dejás de repetirte por WhatsApp.',
                      icono: Icons.home_work_outlined,
                      elegido: _rol == Rol.propietario,
                      onTap: () => setState(() => _rol = Rol.propietario),
                    ),

                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usuario,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: auth.erroresPorCampo['username'],
                      ),
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Escribí un usuario'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _clave,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Al menos 8 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: auth.erroresPorCampo['password'],
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Al menos 8 caracteres'
                          : null,
                    ),

                    // El WhatsApp solo tiene sentido para quien publica: es lo
                    // que se libera cuando aprueba una solicitud. El backend
                    // rechaza a un propietario sin este dato.
                    if (_rol == Rol.propietario) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _whatsapp,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'WhatsApp',
                          helperText: 'No aparece en tus anuncios. Se libera '
                              'solo cuando aprobás una visita.',
                          helperMaxLines: 2,
                          prefixIcon: const Icon(Icons.chat_outlined),
                          errorText: auth.erroresPorCampo['whatsapp'],
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Un propietario necesita un WhatsApp'
                            : null,
                      ),
                    ],

                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      AvisoError(mensaje: auth.error!),
                    ],

                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: auth.ocupado ? null : _crearCuenta,
                      child: auth.ocupado
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vas a poder cambiar de rol creando otra cuenta.',
                      textAlign: TextAlign.center,
                      style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
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

class _TarjetaRol extends StatelessWidget {
  const _TarjetaRol({
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.elegido,
    required this.onTap,
  });

  final String titulo;
  final String detalle;
  final IconData icono;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: elegido
              ? esquema.primaryContainer
              : esquema.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
            color: elegido ? esquema.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono,
                color: elegido ? esquema.onPrimaryContainer : esquema.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: texto.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: elegido ? esquema.onPrimaryContainer : null,
                      )),
                  const SizedBox(height: 4),
                  Text(detalle,
                      style: texto.bodySmall?.copyWith(
                        color: elegido
                            ? esquema.onPrimaryContainer
                            : esquema.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            if (elegido)
              Icon(Icons.check_circle, color: esquema.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
