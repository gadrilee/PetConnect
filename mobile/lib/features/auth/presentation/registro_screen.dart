import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../data/perfil.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
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
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().registro(
          username: _usuario.text.trim(),
          password: _clave.text,
          rol: _rol!,
          whatsapp: _whatsapp.text.trim(),
        );

    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    // Errores del backend por campo
    final errores = auth.erroresPorCampo;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              Espacio.lg, Espacio.sm, Espacio.lg, Espacio.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 416),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Qué vas a hacer en la app',
                    style: texto.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Espacio.md),

                  // ---- Selector de rol ----
                  _TarjetaRol(
                    titulo: 'Busco dónde alquilar',
                    detalle:
                        'Filtrás por precio final, mascotas y minutos caminando a la UAGRM.',
                    icono: Icons.search,
                    elegido: _rol == Rol.inquilino,
                    onTap: () => setState(() => _rol = Rol.inquilino),
                  ),
                  const SizedBox(height: Espacio.sm),
                  _TarjetaRol(
                    titulo: 'Quiero publicar',
                    detalle:
                        'Publicás una vez con las condiciones por delante y dejás de repetirte por WhatsApp.',
                    icono: Icons.home_work_outlined,
                    elegido: _rol == Rol.propietario,
                    onTap: () => setState(() => _rol = Rol.propietario),
                  ),

                  const SizedBox(height: Espacio.xl),

                  // ---- Usuario ----
                  CampoTexto(
                    etiqueta: 'Usuario',
                    controlador: _usuario,
                    icono: Icons.person_outline,
                    mensajeError: errores['username'],
                    accionTeclado: TextInputAction.next,
                    alEnviar: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: Espacio.md),

                  // ---- Contraseña ----
                  CampoTexto(
                    etiqueta: 'Contraseña',
                    controlador: _clave,
                    icono: Icons.lock_outline,
                    ocultarTexto: true,
                    pista: 'Al menos 8 caracteres',
                    mensajeError: errores['password'] ??
                        (_clave.text.isNotEmpty && _clave.text.length < 8
                            ? 'Al menos 8 caracteres'
                            : null),
                    accionTeclado: TextInputAction.next,
                    alEnviar: (_) => FocusScope.of(context).nextFocus(),
                  ),

                  // ---- WhatsApp (solo propietario) ----
                  if (_rol == Rol.propietario) ...[
                    const SizedBox(height: Espacio.md),
                    CampoTexto(
                      etiqueta: 'WhatsApp',
                      controlador: _whatsapp,
                      icono: Icons.chat_outlined,
                      tipoTeclado: TextInputType.phone,
                      formateadores: [FilteringTextInputFormatter.digitsOnly],
                      pista: '70011122',
                      mensajeError: errores['whatsapp'],
                    ),
                    const SizedBox(height: Espacio.sm),
                    Aviso(
                      icono: Icons.lock_outline,
                      mensaje:
                          'No aparece en tus anuncios. Se libera solo cuando aprobás una visita.',
                      tipo: TipoAviso.info,
                    ),
                  ],

                  // ---- Error general del backend ----
                  if (auth.error != null) ...[
                    const SizedBox(height: Espacio.md),
                    Aviso(
                      icono: Icons.error_outline,
                      mensaje: auth.error!,
                      tipo: TipoAviso.error,
                    ),
                  ],

                  const SizedBox(height: Espacio.xl),

                  // ---- Botón crear cuenta ----
                  BotonPrincipal(
                    etiqueta: 'CREAR CUENTA',
                    etiquetaCargando: 'CREANDO...',
                    alTocar: auth.ocupado ? null : _crearCuenta,
                    cargando: auth.ocupado,
                  ),

                  const SizedBox(height: Espacio.md),
                  Text(
                    'Vas a poder cambiar de rol creando otra cuenta.',
                    textAlign: TextAlign.center,
                    style: texto.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(Espacio.md),
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
            Icon(
              icono,
              color: elegido
                  ? esquema.onPrimaryContainer
                  : esquema.onSurfaceVariant,
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: texto.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: elegido ? esquema.onPrimaryContainer : null,
                    ),
                  ),
                  const SizedBox(height: Espacio.xs),
                  Text(
                    detalle,
                    style: texto.bodySmall?.copyWith(
                      color: elegido
                          ? esquema.onPrimaryContainer
                          : esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (elegido)
              Icon(Icons.check_circle, color: esquema.primary, size: 24),
          ],
        ),
      ),
    );
  }
}
