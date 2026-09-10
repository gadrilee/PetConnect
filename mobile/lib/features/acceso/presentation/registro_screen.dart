import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../data/perfil.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatefulWidget {
  final Rol rol;

  const RegistroScreen({
    super.key,
    required this.rol,
  });

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  final _whatsapp = TextEditingController();

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();

    final ok = await context.read<AuthProvider>().registro(
          username: _usuario.text.trim(),
          password: _clave.text,
          rol: widget.rol,
          whatsapp: _whatsapp.text.trim(),
        );

    if (ok && mounted) {
      Aviso.mostrarToast(
        context,
        mensaje: 'Cuenta creada con éxito',
        tipo: TipoAviso.exito,
      );
      // Cerramos ElegirRolScreen y RegistroScreen para volver al login o ir al inicio
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final errores = auth.erroresPorCampo;

    return Pagina(
      titulo: 'Crear cuenta',
      ancho: AnchoPagina.formulario,
      hijos: [
        Text(
          'Tus datos',
          style: AppText.heading(context).copyWith(color: AppColors.text),
        ),
        const SizedBox(height: Espacio.xxl),
        CampoTexto(
          etiqueta: 'Usuario',
          controlador: _usuario,
          icono: Icons.person_outline,
          mensajeError: errores['username'],
          accionTeclado: TextInputAction.next,
          alEnviar: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Contraseña',
          controlador: _clave,
          icono: Icons.lock_outline,
          esClave: true,
          pista: 'Al menos 8 caracteres',
          mensajeError: errores['password'] ??
              (_clave.text.isNotEmpty && _clave.text.length < 8
                  ? 'Al menos 8 caracteres'
                  : null),
          accionTeclado: TextInputAction.next,
          alEnviar: (_) => FocusScope.of(context).nextFocus(),
        ),

        // ---- WhatsApp (solo propietario) ----
        if (widget.rol == Rol.propietario) ...[
          const SizedBox(height: Espacio.md),
          CampoTexto(
            etiqueta: 'WhatsApp',
            controlador: _whatsapp,
            icono: Icons.chat_outlined,
            tipoTeclado: TextInputType.phone,
            formateadores: [FilteringTextInputFormatter.digitsOnly],
            pista: '70011122',
            mensajeError: errores['whatsapp'],
            accionTeclado: TextInputAction.done,
            alEnviar: (_) => _crearCuenta(),
          ),
          const SizedBox(height: Espacio.sm),
          const Aviso(
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
          style: AppText.caption(context).copyWith(
            color: AppColors.text.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
