import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/tarjeta_menu.dart';
import '../../../shared/widgets/tarjeta_perfil.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../../acceso/providers/auth_provider.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';
import '../providers/solicitudes_recibidas_provider.dart';
import 'mis_anuncios_screen.dart';
import 'publicar_screen.dart';
import 'solicitudes_recibidas_screen.dart';

/// El inicio del propietario: quien es, y las tres cosas que puede hacer.
///
/// Los resultados que llegan de otra pantalla —"Cuenta creada con éxito" al
/// registrarse, "Publicado..." al volver de Publicar— se cuentan en el pie,
/// como un aviso de exito a todo el ancho. Nunca como un toast suelto.
class InicioPropietarioScreen extends StatefulWidget {
  const InicioPropietarioScreen({super.key, this.avisoInicial});

  /// Un resultado para mostrar al entrar, como "Cuenta creada con éxito".
  /// Quien navega hasta aca lo pasa; `null` es entrar sin novedades.
  final String? avisoInicial;

  @override
  State<InicioPropietarioScreen> createState() =>
      _InicioPropietarioScreenState();
}

class _InicioPropietarioScreenState extends State<InicioPropietarioScreen> {
  /// El aviso de exito que se ve en el pie. Se va cuando la persona sigue a
  /// otra pantalla: ya lo leyo.
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _aviso = widget.avisoInicial;
  }

  @override
  void didUpdateWidget(covariant InicioPropietarioScreen viejo) {
    super.didUpdateWidget(viejo);
    // Un aviso nuevo reemplaza al que se veia; que lo quiten (null) no borra
    // el que esta pantalla ya decidio mostrar, como "Publicado...".
    final nuevo = widget.avisoInicial;
    if (nuevo != null && nuevo != viejo.avisoInicial) _aviso = nuevo;
  }

  /// Seguir a otra pantalla es haber leido el aviso: se apaga aca y en el
  /// provider, de donde llega el de "Cuenta creada", para que no vuelva.
  void _darPorLeido() {
    setState(() => _aviso = null);
    context.read<AuthProvider>().consumirAvisoInicial();
  }

  void _abrir(Widget pantalla) {
    _darPorLeido();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  Future<void> _publicar() async {
    _darPorLeido();
    final publicado = await Navigator.of(context).push<Anuncio>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => PublicarProvider(ctx.read()),
          child: const PublicarScreen(),
        ),
      ),
    );
    if (!mounted) return;
    context.read<MisAnunciosProvider>().cargar();
    if (publicado != null) {
      setState(() {
        _aviso = 'Publicado. Está a ${publicado.minutosCaminando} min '
            'caminando de la UAGRM.';
      });
    }
  }

  /// El pie solo existe cuando hay un resultado que contar.
  PieAcciones? _pie() {
    if (_aviso == null) return null;
    return PieAcciones(
      aviso: Aviso(mensaje: _aviso!, tipo: TipoAviso.exito),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AuthProvider>().perfil;

    if (perfil == null) return const SizedBox.shrink();

    // GRID: una opcion por fila en movil, dos en tablet y tres en escritorio.
    const columnas = Columnas(tablet: 6, escritorio: 4);

    return Pagina(
      titulo: 'AlquilaMatch',
      conBotonVolver: false,
      pie: _pie(),
      hijos: [
        TarjetaPerfil(
          nombre: perfil.username,
          rol: perfil.rol.etiqueta,
          icono: Icons.home_work_outlined,
          // El propietario es quien tiene un WhatsApp que proteger: la fila
          // le recuerda que no aparece en ningun anuncio.
          whatsappOculto: true,
          alCerrarSesion: () => context.read<AuthProvider>().logout(),
        ),
        // 24 entre bloques de la pantalla; 16 entre el titulo y su contenido.
        const SizedBox(height: Espacio.lg),
        const TituloSeccion('¿Qué querés hacer?'),
        const SizedBox(height: Espacio.md),
        Grilla12(
          celdas: [
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Publicar anuncio',
                detalle:
                    'Las cuatro condiciones de descarte, GPS y fotos con fecha.',
                icono: Icons.add_home_outlined,
                alTocar: _publicar,
              ),
            ),
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Mis anuncios',
                detalle: 'Marcar Ya alquilado en un toque.',
                icono: Icons.list_alt_outlined,
                alTocar: () => _abrir(const MisAnunciosScreen()),
              ),
            ),
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Gestionar solicitudes',
                detalle: 'Aprobar libera tu contacto, y sólo a esa persona.',
                icono: Icons.mark_email_unread_outlined,
                alTocar: () => _abrir(
                  ChangeNotifierProvider(
                    create: (ctx) => SolicitudesRecibidasProvider(ctx.read()),
                    child: const SolicitudesRecibidasScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
