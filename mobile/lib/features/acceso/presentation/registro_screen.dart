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
  // enviar, como en el login, no mientras se escribe. El usuario no tiene
  // uno: lo unico que puede fallarle lo sabe el backend.
  String? _errorClave;
  String? _errorWhatsapp;

  /// Los motivos de cada campo, con el texto de Figma (Crear cuenta · datos
  /// con error). El del usuario ("Ese nombre de usuario ya está tomado.") no
  /// esta aca: solo lo sabe el backend, y llega por `erroresPorCampo`.
  static const _claveCorta =
      'Asegurate de que este campo tenga al menos 8 caracteres.';
  static const _whatsappInvalido = 'Escribí un número de 8 dígitos.';

  /// Un WhatsApp de Bolivia: exactamente 8 digitos, ni uno mas ni uno menos.
  static final _ochoDigitos = RegExp(r'^\d{8}$');

  /// El WhatsApp se pide solo al propietario: es lo que libera al aprobar.
  bool get _pideWhatsapp => widget.rol == Rol.propietario;

  /// Si todos los campos que se ven tienen texto (Figma: Crear cuenta ·
  /// vacío / completo). Decide si el boton se prende; que lo escrito sirva
  /// se revisa recien al tocar, en [_validar].
  bool get _completo =>
      _usuario.text.trim().isNotEmpty &&
      _clave.text.isNotEmpty &&
      (!_pideWhatsapp || _whatsapp.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    // El estado del boton se deriva de lo escrito: hay que rearmar la
    // pantalla con cada tecla, no solo al enviar.
    for (final controlador in [_usuario, _clave, _whatsapp]) {
      controlador.addListener(_rearmar);
    }
  }

  @override
  void dispose() {
    for (final controlador in [_usuario, _clave, _whatsapp]) {
      controlador
        ..removeListener(_rearmar)
        ..dispose();
    }
    super.dispose();
  }

  void _rearmar() {
    if (mounted) setState(() {});
  }

  /// Revisa lo que se puede revisar sin backend, al enviar. Devuelve si se
  /// puede enviar. Aca ya no llega ningun campo vacio: [_crearCuenta] no
  /// pasa sin [_completo].
  bool _validar() {
    bool ok = true;
    setState(() {
      _errorClave = _clave.text.length < 8 ? _claveCorta : null;
      _errorWhatsapp =
          _pideWhatsapp && !_ochoDigitos.hasMatch(_whatsapp.text.trim())
              ? _whatsappInvalido
              : null;
      ok = _errorClave == null && _errorWhatsapp == null;
    });
    return ok;
  }

  /// La unica compuerta para crear la cuenta, la toque el boton o el "listo"
  /// del teclado: con un campo vacio, o con la cuenta ya creandose, no pasa
  /// nada, igual que el boton apagado. Sin esto el teclado saltaba el boton.
  Future<void> _crearCuenta() async {
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    if (auth.ocupado || !_completo) return;
    if (!_validar()) return;

    final ok = await auth.registro(
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

    // Lo local manda sobre lo del backend: es lo mas reciente. El usuario
    // solo tiene lo del backend.
    final errorUsuario = errores['username'];
    final errorClave = _errorClave ?? errores['password'];
    final errorWhatsapp =
        _pideWhatsapp ? _errorWhatsapp ?? errores['whatsapp'] : null;

    // Cuantos campos quedaron en rojo: el resumen de arriba del boton cuenta
    // los mismos que la persona ve marcados, vengan de aca o del backend
    // (el usuario tomado tambien es un campo en rojo).
    final camposConError =
        [errorUsuario, errorClave, errorWhatsapp].whereType<String>().length;

    // El aviso de arriba del boton (Figma: Crear cuenta · datos con error):
    // el resumen de los campos en rojo o, si no hay ninguno marcado, el error
    // general con su propio mensaje (sin conexion, servidor caido).
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
    // El boton pasa por sus estados: apagado con algun campo vacio (Crear
    // cuenta · vacío), prendido con los tres llenos (· completo) y cargando
    // mientras se crea la cuenta.
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
          // `null` apaga el boton: falta texto en algun campo, o ya se esta
          // creando la cuenta (y entonces `cargando` es lo que se ve).
          alTocar: auth.ocupado || !_completo ? null : _crearCuenta,
          cargando: auth.ocupado,
          pistaDeshabilitado: 'Completá todos los campos para crear la cuenta',
        ),
      ],
    );
  }
}
