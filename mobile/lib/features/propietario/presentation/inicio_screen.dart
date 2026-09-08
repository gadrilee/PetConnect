import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/encabezado.dart';
import '../../../shared/widgets/tarjeta_menu.dart';
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
                      Icons.home_work_outlined,
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
                        if (perfil.whatsapp.isNotEmpty) ...[
                          const SizedBox(height: Espacio.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppColors.text.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: Espacio.xs),
                              Expanded(
                                child: Text(
                                  'Tu WhatsApp está oculto',
                                  style: AppText.caption(context).copyWith(
                                    color: AppColors.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
              titulo: 'Publicar anuncio',
              detalle: 'Las cuatro condiciones de descarte, GPS y fotos con fecha.',
              icono: Icons.add_home_outlined,
              alTocar: () => _publicar(context),
            ),
            const SizedBox(height: Espacio.md),
            
            TarjetaMenu(
              titulo: 'Mis anuncios',
              detalle: 'Marcar Ya alquilado en un toque.',
              icono: Icons.list_alt_outlined,
              alTocar: () => _abrir(context, const MisAnunciosScreen()),
            ),
            const SizedBox(height: Espacio.md),
            
            TarjetaMenu(
              titulo: 'Gestionar solicitudes',
              detalle: 'Aprobar libera tu contacto, y sólo a esa persona.',
              icono: Icons.mark_email_unread_outlined,
              alTocar: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (ctx) => SolicitudesRecibidasProvider(ctx.read()),
                    child: const SolicitudesRecibidasScreen(),
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
