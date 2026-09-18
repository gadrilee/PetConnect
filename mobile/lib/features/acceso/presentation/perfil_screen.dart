import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../providers/auth_provider.dart';

/// Mi perfil (flujo v0.1): los datos de la cuenta y la salida.
///
/// Lo unico que se edita es el WhatsApp, y solo la propietaria lo tiene: es el
/// dato que el producto existe para proteger (evidencia 9), y si cambia de
/// numero, cada visita que apruebe le daria a la inquilina uno que ya no
/// sirve. Usuario, correo y rol se muestran pero no se tocan: el rol decide
/// que app ve cada una, y el correo es con lo que se recupera la cuenta.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final TextEditingController _whatsapp;
  String? _errorWhatsapp;
  bool _guardado = false;

  static final _ochoDigitos = RegExp(r'^\d{8}$');

  @override
  void initState() {
    super.initState();
    final perfil = context.read<AuthProvider>().perfil;
    _whatsapp = TextEditingController(text: perfil?.whatsapp ?? '')
      ..addListener(_rearmar);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthProvider>().limpiarError(),
    );
  }

  @override
  void dispose() {
    _whatsapp
      ..removeListener(_rearmar)
      ..dispose();
    super.dispose();
  }

  /// Escribir de nuevo borra el "guardado" y el error: ya no hablan de lo que
  /// hay en el campo.
  void _rearmar() {
    if (!mounted) return;
    setState(() {
      _guardado = false;
      _errorWhatsapp = null;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final numero = _whatsapp.text.trim();
    if (!_ochoDigitos.hasMatch(numero)) {
      setState(() => _errorWhatsapp = 'Escribí los 8 dígitos, como 70099988.');
      return;
    }
    final ok = await context.read<AuthProvider>().actualizarWhatsapp(numero);
    if (ok && mounted) setState(() => _guardado = true);
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().logout();
    // La puerta de la app ya muestra Ingresar: se cierran las pantallas de
    // arriba para no dejar Mi perfil abierto sobre el login.
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final perfil = auth.perfil;
    if (perfil == null) return const Pagina(titulo: 'Mi perfil');

    final guardando = auth.ocupado;
    final cambio = _whatsapp.text.trim() != perfil.whatsapp;
    final errorWhatsapp = _errorWhatsapp ?? auth.erroresPorCampo['whatsapp'];

    Widget dato(IconData icono, String texto) => FilaCondicion(
          icono: icono,
          texto: texto,
          colorIcono: AppColors.text70,
          estilo: AppText.body(context).copyWith(color: AppColors.text),
        );

    // AUTO LAYOUT (Figma, Mi perfil): el aviso de lo que paso arriba, "Tus
    // datos", 24, "Tu WhatsApp" con su nota, 24, y las acciones con 8 entre
    // ellas. Sin pie: los botones van en el contenido, como en Figma.
    return Pagina(
      titulo: 'Mi perfil',
      ancho: AnchoPagina.formulario,
      hijos: [
        if (_guardado) ...[
          const Aviso(
            tipo: TipoAviso.exito,
            mensaje: 'Guardado. Es el número que se libera cuando aprobás una visita.',
          ),
          const SizedBox(height: Espacio.lg),
        ] else if (auth.error != null) ...[
          Aviso(tipo: TipoAviso.error, mensaje: auth.error!),
          const SizedBox(height: Espacio.lg),
        ],

        const TituloSeccion('Tus datos'),
        const SizedBox(height: Espacio.md),
        dato(Icons.person_outline, perfil.username),
        const SizedBox(height: Espacio.sm),
        if (perfil.email.isNotEmpty) ...[
          dato(Icons.mark_email_unread_outlined, perfil.email),
          const SizedBox(height: Espacio.sm),
        ],
        dato(
          perfil.esPropietario ? Icons.home_work_outlined : Icons.search,
          perfil.esPropietario ? 'Propietaria' : 'Inquilina',
        ),

        if (perfil.esPropietario) ...[
          const SizedBox(height: Espacio.lg),
          const TituloSeccion('Tu WhatsApp'),
          const SizedBox(height: Espacio.md),
          CampoTexto(
            etiqueta: 'WhatsApp',
            controlador: _whatsapp,
            icono: Icons.chat_outlined,
            tipoTeclado: TextInputType.phone,
            formateadores: [FilteringTextInputFormatter.digitsOnly],
            mensajeError: errorWhatsapp,
            accionTeclado: TextInputAction.done,
            alEnviar: (_) => cambio && !guardando ? _guardar() : null,
          ),
          const SizedBox(height: Espacio.lg),
          const Aviso(
            icono: Icons.lock_outline,
            mensaje: 'No aparece en tus anuncios. Se libera sólo cuando aprobás una visita.',
          ),
        ],

        const SizedBox(height: Espacio.lg),
        if (perfil.esPropietario) ...[
          BotonPrincipal(
            etiqueta: 'GUARDAR',
            etiquetaCargando: 'GUARDANDO...',
            // Nace apagado: al entrar todavia no cambio nada.
            alTocar: cambio && !guardando ? _guardar : null,
            cargando: guardando,
            pistaDeshabilitado: 'Cambiá el número para guardarlo.',
          ),
          const SizedBox(height: Espacio.sm),
        ],
        BotonSecundario(
          etiqueta: 'CERRAR SESIÓN',
          destructiva: true,
          alTocar: guardando ? null : _cerrarSesion,
        ),
      ],
    );
  }
}
