import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../providers/auth_provider.dart';
import 'recuperar_screen.dart';

/// Flujo v0.1, pantalla 04: poner la contrasena nueva.
///
/// Se llega desde el enlace del correo (`alquilamatch://app/recuperar`), que
/// trae el [uid] y el [token]. Al guardar la persona queda adentro, sin volver
/// a escribirla en Ingresar: el backend devuelve la sesion.
class NuevaContrasenaScreen extends StatefulWidget {
  const NuevaContrasenaScreen({super.key, required this.uid, required this.token});

  final String uid;
  final String token;

  @override
  State<NuevaContrasenaScreen> createState() => _NuevaContrasenaScreenState();
}

class _NuevaContrasenaScreenState extends State<NuevaContrasenaScreen> {
  final _clave = TextEditingController();
  final _repetir = TextEditingController();
  String? _errorClave;
  String? _errorRepetir;

  @override
  void initState() {
    super.initState();
    for (final c in [_clave, _repetir]) {
      c.addListener(_rearmar);
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthProvider>().limpiarError(),
    );
  }

  @override
  void dispose() {
    for (final c in [_clave, _repetir]) {
      c
        ..removeListener(_rearmar)
        ..dispose();
    }
    super.dispose();
  }

  void _rearmar() {
    if (mounted) setState(() {});
  }

  bool get _completo => _clave.text.isNotEmpty && _repetir.text.isNotEmpty;

  bool _validar() {
    setState(() {
      _errorClave = _clave.text.length < 8
          ? 'Asegurate de que tenga al menos 8 caracteres.'
          : null;
      _errorRepetir = _errorClave == null && _repetir.text != _clave.text
          ? 'Las dos contraseñas no coinciden.'
          : null;
    });
    return _errorClave == null && _errorRepetir == null;
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_validar()) return;
    final ok = await context.read<AuthProvider>().confirmarRecuperacion(
          uid: widget.uid,
          token: widget.token,
          password: _clave.text,
        );
    // La puerta de la app ya muestra el inicio con el aviso "Ya estás
    // adentro": se cierra esta pantalla, que quedo encima.
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _pedirOtro() {
    context.read<AuthProvider>().limpiarError();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RecuperarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // El backend solo rechaza el enlace entero (vencido o ya usado) o la
    // contrasena; lo primero no tiene campo donde pegarse.
    final errorClave = _errorClave ?? auth.erroresPorCampo['password'];
    final enlaceVencido = auth.error != null && errorClave == null;

    if (enlaceVencido) {
      return Pagina(
        titulo: 'Nueva contraseña',
        ancho: AnchoPagina.formulario,
        hijos: [
          Aviso(tipo: TipoAviso.error, mensaje: auth.error!),
          const SizedBox(height: Espacio.lg),
          BotonPrincipal(etiqueta: 'PEDIR OTRO ENLACE', alTocar: _pedirOtro),
        ],
      );
    }

    final listo = _completo && !auth.ocupado;

    return Pagina(
      titulo: 'Nueva contraseña',
      ancho: AnchoPagina.formulario,
      hijos: [
        const TituloSeccion('Elegí una contraseña nueva'),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Contraseña nueva',
          controlador: _clave,
          icono: Icons.lock_outline,
          esClave: true,
          pista: 'Al menos 8 caracteres',
          mensajeError: errorClave,
          accionTeclado: TextInputAction.next,
          alEnviar: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Repetir contraseña',
          controlador: _repetir,
          icono: Icons.lock_outline,
          esClave: true,
          pista: 'Repetí la contraseña',
          mensajeError: _errorRepetir,
          accionTeclado: TextInputAction.done,
          alEnviar: (_) => listo ? _guardar() : null,
        ),
        const SizedBox(height: Espacio.lg),
        const Aviso(
          icono: Icons.lock_outline,
          mensaje: 'Al menos 8 caracteres. Al guardar entrás directo, sin volver '
              'a escribirla.',
        ),
        const SizedBox(height: Espacio.lg),
        BotonPrincipal(
          etiqueta: 'GUARDAR CONTRASEÑA',
          etiquetaCargando: 'GUARDANDO...',
          alTocar: listo ? _guardar : null,
          cargando: auth.ocupado,
          pistaDeshabilitado: 'Escribí la contraseña nueva dos veces.',
        ),
      ],
    );
  }
}
