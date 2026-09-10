import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/tarjeta_menu.dart';
import '../../../shared/widgets/tarjeta_perfil.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../../acceso/providers/auth_provider.dart';
import '../providers/mis_solicitudes_provider.dart';
import 'buscar_screen.dart';
import 'mis_solicitudes_screen.dart';

class InicioInquilinaScreen extends StatelessWidget {
  const InicioInquilinaScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AuthProvider>().perfil;

    if (perfil == null) return const SizedBox.shrink();

    return Pagina(
      titulo: 'AlquilaMatch',
      conBotonVolver: false,
      hijos: [
        TarjetaPerfil(
          nombre: perfil.username,
          rol: perfil.rol.etiqueta,
          icono: Icons.search,
          alCerrarSesion: () => context.read<AuthProvider>().logout(),
        ),
        const SizedBox(height: Espacio.xxl),
        const TituloSeccion('¿Qué querés hacer?'),
        const SizedBox(height: Espacio.lg),
        // GRID: una opcion por fila en movil; desde tablet, las dos lado a lado.
        Grilla12(
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 6),
              child: TarjetaMenu(
                titulo: 'Buscar alquiler',
                detalle:
                    'Filtrar por precio final, mascotas, tipo y minutos caminando a la UAGRM.',
                icono: Icons.search,
                alTocar: () => _abrir(context, const BuscarScreen()),
              ),
            ),
            CeldaGrilla(
              columnas: const Columnas(tablet: 6),
              child: TarjetaMenu(
                titulo: 'Estado de Solicitudes',
                detalle:
                    'Revisa si los dueños aceptaron tus visitas y contactalos.',
                icono: Icons.mark_email_read_outlined,
                alTocar: () => _abrir(
                  context,
                  ChangeNotifierProvider(
                    create: (ctx) => MisSolicitudesProvider(ctx.read()),
                    child: const MisSolicitudesScreen(),
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
