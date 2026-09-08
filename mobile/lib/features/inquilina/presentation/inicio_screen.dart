import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/encabezado.dart';
import '../../../shared/widgets/tarjeta_menu.dart';
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: Encabezado(
        titulo: 'AlquilaMatch',
        conBotonVolver: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Espacio.lg),
          children: [
            // Header del perfil
            Container(
              padding: const EdgeInsets.all(Espacio.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Medida.radio),
                border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: Espacio.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perfil.username,
                          style: AppText.heading(context).copyWith(
                            color: AppColors.text,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          perfil.rol.etiqueta,
                          style: AppText.caption(context).copyWith(
                            color: AppColors.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    onPressed: () => context.read<AuthProvider>().logout(),
                    tooltip: 'Cerrar sesión',
                  ),
                ],
              ),
            ),
            const SizedBox(height: Espacio.xxl),
            
            Text(
              '¿Qué querés hacer?',
              style: AppText.heading(context).copyWith(color: AppColors.text, fontSize: 18),
            ),
            const SizedBox(height: Espacio.lg),

            TarjetaMenu(
              titulo: 'Buscar alquiler',
              detalle: 'Filtrar por precio final, mascotas, tipo y minutos caminando a la UAGRM.',
              icono: Icons.search,
              alTocar: () => _abrir(context, const BuscarScreen()),
            ),
            const SizedBox(height: Espacio.md),
            
            TarjetaMenu(
              titulo: 'Estado de Solicitudes',
              detalle: 'Revisa si los dueños aceptaron tus visitas y contactalos.',
              icono: Icons.mark_email_read_outlined,
              alTocar: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (ctx) => MisSolicitudesProvider(ctx.read()),
                    child: const MisSolicitudesScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
