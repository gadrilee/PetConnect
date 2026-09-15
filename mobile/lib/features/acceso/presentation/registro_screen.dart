import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/titulo_seccion.dart';
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

  // Mensajes de error locales por campo: null = válido. Se calculan al
  // enviar, como en el login, no mientras se escribe.
  String? _errorUsuario;
  String? _errorClave;
  String? _errorWhatsapp;

  /// El WhatsApp se pide solo al propietario: es lo que libera al aprobar.
  bool get _pideWhatsapp => widget.rol == Rol.propietario;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  /// Revisa lo que se puede revisar sin backend. Devuelve si se puede enviar.
  bool _validar() {
    bool ok = true;
    setState(() {
      _errorUsuario =
          _usuario.text.trim().isEmpty ? 'Escribí un usuario' : null;
      _errorClave = _clave.text.isEmpty
          ? 'Escribí una contraseña'
          : _clave.text.length < 8
              ? 'Al menos 8 caracteres'
              : null;
      _errorWhatsapp = _pideWhatsapp && _whatsapp.text.trim().isEmpty
          ? 'Escribí tu WhatsApp'
          : null;
      ok = _errorUsuario == null &&
          _errorClave == null &&
          _errorWhatsapp == null;
    });
    return ok;
  }

  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    if (!_validar()) return;

    final ok = await context.read<AuthProvider>().registro(
          username: _usuario.text.trim(),
          password: _clave.text,
          rol: widget.rol,
          whatsapp: _whatsapp.text.trim(),
        );

    // Con exito el provider ya dejo la sesion iniciada y guardo el aviso
    // "Cuenta creada con éxito" en `avisoInicial`: _Puerta reemplaza el login
    // por el inicio, y el inicio lo muestra en su pie. Aca solo se cierran
    // Elegir rol y Crear cuenta. Nada de toasts: el aviso nunca queda suelto.
    if (ok && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final errores = auth.erroresPorCampo;

    // Lo local manda sobre lo del backend: es lo mas reciente.
    final errorUsuario = _errorUsuario ?? errores['username'];
    final errorClave = _errorClave ?? errores['password'];
    final errorWhatsapp =
        _pideWhatsapp ? _errorWhatsapp ?? errores['whatsapp'] : null;

    // Cuantos campos quedaron en rojo: el resumen de arriba del boton cuenta
    // los mismos que la persona ve marcados.
    final camposConError =
        [errorUsuario, errorClave, errorWhatsapp].whereType<String>().length;

    // El aviso de arriba del boton: el resumen de los campos en rojo o, si no
    // hay ninguno marcado, el error general (sin conexion, servidor caido).
    final String? mensajeError = switch (camposConError) {
      0 => auth.error,
      1 => 'Corregí el campo marcado en rojo para crear la cuenta.',
      _ => 'Corregí los $camposConError campos marcados en rojo '
          'para crear la cuenta.',
    };

    // AUTO LAYOUT (Figma, Crear cuenta): la seccion "Tus datos" —titulo y
    // campos, con 16 entre ellos—, 24, el aviso del WhatsApp, 24, y las
    // acciones: el aviso de error, 16, el boton. Sin pie: el boton va en el
    // contenido, como en Figma. El resumen de errores es un Aviso arriba del
    // boton, igual que el de "sin conexión"; nunca un texto suelto debajo.
    return Pagina(
      titulo: 'Crear cuenta',
      ancho: AnchoPagina.formulario,
      hijos: [
        const TituloSeccion('Tus datos'),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Usuario',
          controlador: _usuario,
          icono: Icons.person_outline,
          mensajeError: errorUsuario,
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
          mensajeError: errorClave,
          accionTeclado:
              _pideWhatsapp ? TextInputAction.next : TextInputAction.done,
          alEnviar: (_) => _pideWhatsapp
              ? FocusScope.of(context).nextFocus()
              : _crearCuenta(),
        ),

        // ---- WhatsApp (solo propietario) ----
        if (_pideWhatsapp) ...[
          const SizedBox(height: Espacio.md),
          CampoTexto(
            etiqueta: 'WhatsApp',
            controlador: _whatsapp,
            icono: Icons.chat_outlined,
            tipoTeclado: TextInputType.phone,
            formateadores: [FilteringTextInputFormatter.digitsOnly],
            pista: '70011122',
            mensajeError: errorWhatsapp,
            accionTeclado: TextInputAction.done,
            alEnviar: (_) => _crearCuenta(),
          ),
          const SizedBox(height: Espacio.lg),
          const Aviso(
            icono: Icons.lock_outline,
            mensaje:
                'No aparece en tus anuncios. Se libera solo cuando aprobás una visita.',
            tipo: TipoAviso.info,
          ),
        ],

        // ---- Acciones: el resumen de errores y el boton ----
        const SizedBox(height: Espacio.lg),
        if (mensajeError != null) ...[
          Aviso(mensaje: mensajeError, tipo: TipoAviso.error),
          const SizedBox(height: Espacio.md),
        ],
        BotonPrincipal(
          etiqueta: 'CREAR CUENTA',
          etiquetaCargando: 'CREANDO...',
          alTocar: auth.ocupado ? null : _crearCuenta,
          cargando: auth.ocupado,
        ),
      ],
    );
  }
}
