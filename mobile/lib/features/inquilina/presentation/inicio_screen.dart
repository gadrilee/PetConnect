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
import '../providers/mis_solicitudes_provider.dart';
import 'buscar_screen.dart';
import 'mis_solicitudes_screen.dart';

/// Inicio de la inquilina: quien entro y que puede hacer.
///
/// Con [avisoInicial] muestra en el pie lo que acaba de pasar, como "Cuenta
/// creada con éxito" al llegar desde Crear cuenta. Es un pie con solo el
/// aviso, nunca un toast flotante.
class InicioInquilinaScreen extends StatelessWidget {
  const InicioInquilinaScreen({super.key, this.avisoInicial});

  /// El resultado con el que se llega al inicio, o `null` si no hay ninguno.
  final String? avisoInicial;

  void _abrir(BuildContext context, Widget pantalla) {
    // Seguir a otra pantalla es haber leido el aviso: se da por visto en el
    // provider, que es de donde llega, y el pie desaparece al volver.
    context.read<AuthProvider>().consumirAvisoInicial();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AuthProvider>().perfil;
    final aviso = avisoInicial;

    if (perfil == null) return const SizedBox.shrink();

    return Pagina(
      titulo: 'AlquilaMatch',
      conBotonVolver: false,
      pie: aviso == null
          ? null
          : PieAcciones(aviso: Aviso(tipo: TipoAviso.exito, mensaje: aviso)),
      hijos: [
        TarjetaPerfil(
          nombre: perfil.username,
          rol: perfil.rol.etiqueta,
          icono: Icons.search,
          alCerrarSesion: () => context.read<AuthProvider>().logout(),
        ),
        // 24 entre bloques de la pantalla; 16 entre el titulo y su contenido.
        const SizedBox(height: Espacio.lg),
        const TituloSeccion('¿Qué querés hacer?'),
        const SizedBox(height: Espacio.md),
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
                titulo: 'Estado de solicitudes',
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
