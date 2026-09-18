import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/avatar_perfil.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/boton_texto.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/hoja_opciones.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../data/foto_del_telefono.dart';
import '../providers/auth_provider.dart';

/// Lo que puede estar pasando en Mi perfil. Mientras pasa una cosa, todo lo
/// demas queda quieto.
enum _Tarea { whatsapp, subirFoto, quitarFoto }

/// Lo que se elige en la hoja de la foto.
enum _OpcionFoto { camara, galeria, quitar }

/// Mi perfil (flujo v0.1): la foto, los datos de la cuenta y la salida.
///
/// Se editan dos cosas. La foto, las dos: es opcional y sin ella se ve el
/// icono del rol. El WhatsApp, solo la propietaria: es el dato que el producto
/// existe para proteger (evidencia 9), y si cambia de numero, cada visita que
/// apruebe le daria a la inquilina uno que ya no sirve. Usuario, correo y rol
/// se muestran pero no se tocan: el rol decide que app ve cada una, y el
/// correo es con lo que se recupera la cuenta.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key, this.elegirFoto = elegirFotoDelTelefono});

  /// De donde sale la foto. Las pruebas la reemplazan: no hay camara ahi.
  final ElegirFoto elegirFoto;

  static const String fotoCambiada = 'Listo, cambiaste tu foto.';
  static const String fotoQuitada = 'Quitaste tu foto.';
  static const String sinCamara =
      'No se pudo abrir la cámara. Revisá el permiso en los ajustes del teléfono.';
  static const String sinGaleria =
      'No se pudo abrir la galería. Revisá el permiso en los ajustes del teléfono.';

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final TextEditingController _whatsapp;
  String? _errorWhatsapp;

  /// Lo que salio bien, para el aviso de arriba.
  String? _exito;

  /// Lo que fallo antes de llegar al servidor (la camara no abrio).
  String? _errorLocal;

  _Tarea? _tarea;

  /// La foto recien elegida. Se ve mientras sube y se queda despues, para no
  /// esperar a bajar del servidor la misma foto que ya esta en el telefono.
  String? _fotoLocal;

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

  /// Escribir de nuevo borra el aviso y el error: ya no hablan de lo que hay
  /// en el campo.
  void _rearmar() {
    if (!mounted) return;
    setState(() {
      _exito = null;
      _errorLocal = null;
      _errorWhatsapp = null;
    });
  }

  /// Cada accion empieza sin los avisos de la anterior.
  void _empezar(_Tarea tarea) {
    context.read<AuthProvider>().limpiarError();
    setState(() {
      _tarea = tarea;
      _exito = null;
      _errorLocal = null;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    final numero = _whatsapp.text.trim();
    if (!_ochoDigitos.hasMatch(numero)) {
      setState(() => _errorWhatsapp = 'Escribí los 8 dígitos, como 70099988.');
      return;
    }
    _empezar(_Tarea.whatsapp);
    final ok = await context.read<AuthProvider>().actualizarWhatsapp(numero);
    if (!mounted) return;
    setState(() {
      _tarea = null;
      if (ok) {
        _exito = 'Guardado. Es el número que se libera cuando aprobás una visita.';
      }
    });
  }

  Future<void> _cambiarFoto() async {
    final tieneFoto = context.read<AuthProvider>().perfil?.tieneFoto ?? false;
    final opcion = await mostrarHojaOpciones<_OpcionFoto>(
      context,
      titulo: 'Foto de perfil',
      opciones: [
        const OpcionHoja(
          valor: _OpcionFoto.camara,
          icono: Icons.photo_camera_outlined,
          etiqueta: 'Sacar una foto',
        ),
        const OpcionHoja(
          valor: _OpcionFoto.galeria,
          icono: Icons.photo_library_outlined,
          etiqueta: 'Elegir de la galería',
        ),
        // Quitar solo tiene sentido si hay algo que quitar.
        if (tieneFoto)
          const OpcionHoja(
            valor: _OpcionFoto.quitar,
            icono: Icons.delete_outline,
            etiqueta: 'Quitar foto',
            destructiva: true,
          ),
      ],
    );
    if (!mounted || opcion == null) return;
    if (opcion == _OpcionFoto.quitar) return _quitarFoto();

    final String? ruta;
    try {
      ruta = await widget.elegirFoto(
        opcion == _OpcionFoto.camara ? OrigenFoto.camara : OrigenFoto.galeria,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exito = null;
        _errorLocal = opcion == _OpcionFoto.camara
            ? PerfilScreen.sinCamara
            : PerfilScreen.sinGaleria;
      });
      return;
    }
    // Se arrepintio en la camara o en la galeria: nada cambia.
    if (ruta == null || !mounted) return;

    _empezar(_Tarea.subirFoto);
    final anterior = _fotoLocal;
    setState(() => _fotoLocal = ruta);
    final ok = await context.read<AuthProvider>().subirFoto(ruta);
    if (!mounted) return;
    setState(() {
      _tarea = null;
      if (ok) {
        _exito = PerfilScreen.fotoCambiada;
      } else {
        // No quedo: vuelve la que habia.
        _fotoLocal = anterior;
      }
    });
  }

  Future<void> _quitarFoto() async {
    _empezar(_Tarea.quitarFoto);
    final ok = await context.read<AuthProvider>().quitarFoto();
    if (!mounted) return;
    setState(() {
      _tarea = null;
      if (ok) {
        _fotoLocal = null;
        _exito = PerfilScreen.fotoQuitada;
      }
    });
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

    final libre = _tarea == null;
    final cambio = _whatsapp.text.trim() != perfil.whatsapp;
    final errorWhatsapp = _errorWhatsapp ?? auth.erroresPorCampo['whatsapp'];
    // Lo que fallo va arriba; el WhatsApp mal escrito, debajo de su campo.
    final error = _errorLocal ?? auth.error ?? auth.erroresPorCampo['foto'];
    final hayFoto = _fotoLocal != null || perfil.tieneFoto;

    Widget dato(IconData icono, String texto) => FilaCondicion(
          icono: icono,
          texto: texto,
          colorIcono: AppColors.text70,
          estilo: AppText.body(context).copyWith(color: AppColors.text),
        );

    // AUTO LAYOUT (Figma, Mi perfil): el aviso de lo que paso arriba, la foto
    // con su enlace (8 entre ellos), 24, "Tus datos", 24, "Tu WhatsApp" con su
    // nota, 24, y las acciones con 8 entre ellas. Sin pie: los botones van en
    // el contenido, como en Figma.
    return Pagina(
      titulo: 'Mi perfil',
      ancho: AnchoPagina.formulario,
      hijos: [
        if (_exito != null) ...[
          Aviso(tipo: TipoAviso.exito, mensaje: _exito!),
          const SizedBox(height: Espacio.lg),
        ] else if (error != null) ...[
          Aviso(tipo: TipoAviso.error, mensaje: error),
          const SizedBox(height: Espacio.lg),
        ],

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarPerfil(
                diametro: 96,
                icono: perfil.esPropietario ? Icons.home_work_outlined : Icons.search,
                foto: perfil.foto,
                archivoLocal: _fotoLocal,
                subiendo: _tarea == _Tarea.subirFoto || _tarea == _Tarea.quitarFoto,
                alTocar: libre ? _cambiarFoto : null,
              ),
              const SizedBox(height: Espacio.sm),
              BotonTexto(
                etiqueta: _tarea == _Tarea.subirFoto
                    ? 'Subiendo foto…'
                    : hayFoto
                        ? 'Cambiar foto'
                        : 'Agregar foto',
                icono: Icons.photo_camera_outlined,
                alTocar: libre ? _cambiarFoto : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacio.lg),

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
            alEnviar: (_) => cambio && libre ? _guardar() : null,
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
            alTocar: cambio && libre ? _guardar : null,
            cargando: _tarea == _Tarea.whatsapp,
            pistaDeshabilitado: 'Cambiá el número para guardarlo.',
          ),
          const SizedBox(height: Espacio.sm),
        ],
        BotonSecundario(
          etiqueta: 'CERRAR SESIÓN',
          destructiva: true,
          alTocar: libre ? _cerrarSesion : null,
        ),
      ],
    );
  }
}
