import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../providers/auth_provider.dart';

/// Flujo v0.1, pantallas 02 y 03: pedir el enlace para una contrasena nueva.
///
/// Es una sola pantalla con dos momentos, como en Figma: primero el correo;
/// despues, la confirmacion de que se mando. La confirmacion no dice si ese
/// correo tiene cuenta: si dijera "no existe", cualquiera podria averiguar
/// quien usa la app probando correos.
class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  final _correo = TextEditingController();
  bool _enviado = false;

  @override
  void initState() {
    super.initState();
    _correo.addListener(_rearmar);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthProvider>().limpiarError(),
    );
  }

  @override
  void dispose() {
    _correo
      ..removeListener(_rearmar)
      ..dispose();
    super.dispose();
  }

  void _rearmar() {
    if (mounted) setState(() {});
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    final ok = await context.read<AuthProvider>().pedirRecuperacion(_correo.text.trim());
    if (ok && mounted) setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_enviado) {
      return Pagina(
        titulo: 'Recuperar contraseña',
        ancho: AnchoPagina.formulario,
        hijos: [
          const Aviso(
            tipo: TipoAviso.exito,
            mensaje: 'Si ese correo tiene una cuenta, te llegó un enlace. '
                'Revisá tu bandeja.',
          ),
          const SizedBox(height: Espacio.lg),
          BotonPrincipal(
            etiqueta: 'VOLVER A INGRESAR',
            alTocar: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    final vacio = _correo.text.trim().isEmpty;

    // AUTO LAYOUT (Figma, Olvidaste tu contraseña): la seccion "Tu correo",
    // 24, la nota de lo que va a pasar, 24, y el boton.
    return Pagina(
      titulo: 'Recuperar contraseña',
      ancho: AnchoPagina.formulario,
      hijos: [
        const TituloSeccion('Tu correo'),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Correo',
          controlador: _correo,
          icono: Icons.mark_email_unread_outlined,
          tipoTeclado: TextInputType.emailAddress,
          pista: 'tucorreo@ejemplo.com',
          mensajeError: auth.erroresPorCampo['email'],
          accionTeclado: TextInputAction.done,
          alEnviar: (_) => vacio || auth.ocupado ? null : _enviar(),
        ),
        const SizedBox(height: Espacio.lg),
        if (auth.error != null) ...[
          Aviso(tipo: TipoAviso.error, mensaje: auth.error!),
          const SizedBox(height: Espacio.md),
        ] else ...[
          const Aviso(
            icono: Icons.lock_outline,
            mensaje: 'Te mandamos un enlace para poner una contraseña nueva.',
          ),
          const SizedBox(height: Espacio.lg),
        ],
        BotonPrincipal(
          etiqueta: 'ENVIAR ENLACE',
          etiquetaCargando: 'ENVIANDO...',
          alTocar: vacio || auth.ocupado ? null : _enviar,
          cargando: auth.ocupado,
          pistaDeshabilitado: 'Escribí tu correo para recibir el enlace.',
        ),
      ],
    );
  }
}
