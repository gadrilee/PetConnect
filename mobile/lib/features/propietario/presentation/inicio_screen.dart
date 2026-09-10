import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/tarjeta_menu.dart';
import '../../../shared/widgets/tarjeta_perfil.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../../acceso/providers/auth_provider.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';
import '../providers/solicitudes_recibidas_provider.dart';
import 'mis_anuncios_screen.dart';
import 'publicar_screen.dart';
import 'solicitudes_recibidas_screen.dart';

class InicioPropietarioScreen extends StatelessWidget {
  const InicioPropietarioScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  void _publicar(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (ctx) => PublicarProvider(ctx.read()),
              child: const PublicarScreen(),
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<MisAnunciosProvider>().cargar();
        });
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
      hijos: [
        TarjetaPerfil(
          nombre: perfil.username,
          rol: perfil.rol.etiqueta,
          icono: Icons.home_work_outlined,
          whatsappOculto: perfil.whatsapp.isNotEmpty,
          alCerrarSesion: () => context.read<AuthProvider>().logout(),
        ),
        const SizedBox(height: Espacio.xxl),
        const TituloSeccion('¿Qué querés hacer?'),
        const SizedBox(height: Espacio.lg),
        Grilla12(
          celdas: [
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Publicar anuncio',
                detalle:
                    'Las cuatro condiciones de descarte, GPS y fotos con fecha.',
                icono: Icons.add_home_outlined,
                alTocar: () => _publicar(context),
              ),
            ),
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Mis anuncios',
                detalle: 'Marcar Ya alquilado en un toque.',
                icono: Icons.list_alt_outlined,
                alTocar: () => _abrir(context, const MisAnunciosScreen()),
              ),
            ),
            CeldaGrilla(
              columnas: columnas,
              child: TarjetaMenu(
                titulo: 'Gestionar solicitudes',
                detalle: 'Aprobar libera tu contacto, y sólo a esa persona.',
                icono: Icons.mark_email_unread_outlined,
                alTocar: () => _abrir(
                  context,
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
