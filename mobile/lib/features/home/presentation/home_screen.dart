import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../anuncios/presentation/mis_anuncios_screen.dart';
import '../../anuncios/presentation/publicar_screen.dart';
import '../../anuncios/providers/mis_anuncios_provider.dart';
import '../../anuncios/providers/publicar_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../buscar/presentation/buscar_screen.dart';

/// Pantalla de entrada despues del login. Es el punto donde se bifurcan los dos
/// flujos documentados: cada modulo del `appmap/appmap-v0.1.md` cuelga de aca.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  void _publicar(BuildContext context) {
    // Provider nuevo por publicacion, para no arrastrar fotos ni ubicacion
    // del anuncio anterior.
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (ctx) => PublicarProvider(ctx.read()),
            child: const PublicarScreen(),
          ),
        ))
        .then((_) {
          if (context.mounted) context.read<MisAnunciosProvider>().cargar();
        });
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<AuthProvider>().perfil;
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    if (perfil == null) return const SizedBox.shrink();

    final modulos = perfil.esPropietario
        ? <_Modulo>[
            _Modulo(
              titulo: 'Publicar anuncio',
              detalle: 'Las cuatro condiciones de descarte, la ubicación por '
                  'GPS y las fotos con fecha.',
              icono: Icons.add_home_outlined,
              alTocar: () => _publicar(context),
            ),
            _Modulo(
              titulo: 'Mis anuncios',
              detalle: 'Marcar Ya alquilado en un toque.',
              icono: Icons.list_alt_outlined,
              alTocar: () => _abrir(context, const MisAnunciosScreen()),
            ),
            const _Modulo(
              titulo: 'Gestionar solicitudes',
              detalle: 'Aprobar libera tu contacto, y sólo a esa persona.',
              icono: Icons.mark_email_unread_outlined,
            ),
          ]
        : <_Modulo>[
            _Modulo(
              titulo: 'Buscar',
              detalle: 'Filtrar por precio final, mascotas, tipo y minutos '
                  'caminando a la UAGRM. Solicitar visita y recibir el '
                  'contacto cuando el propietario aprueba.',
              icono: Icons.search,
              alTocar: () => _abrir(context, const BuscarScreen()),
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AlquilaMatch'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: esquema.primaryContainer,
                    child: Icon(
                      perfil.esPropietario ? Icons.home_work_outlined : Icons.search,
                      color: esquema.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(perfil.username,
                            style: texto.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(perfil.rol.etiqueta,
                            style: texto.bodyMedium
                                ?.copyWith(color: esquema.onSurfaceVariant)),
                        if (perfil.esPropietario && perfil.whatsapp.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 14, color: esquema.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tu WhatsApp está oculto en los anuncios',
                                  style: texto.bodySmall
                                      ?.copyWith(color: esquema.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          for (final m in modulos)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  onTap: m.alTocar,
                  enabled: m.alTocar != null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Icon(m.icono, color: esquema.primary),
                  title: Text(m.titulo,
                      style:
                          texto.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(m.detalle),
                  ),
                  trailing: m.alTocar != null
                      ? const Icon(Icons.chevron_right)
                      : Chip(
                          label: const Text('pendiente'),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          backgroundColor: esquema.surfaceContainerHighest,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Modulo {
  const _Modulo({
    required this.titulo,
    required this.detalle,
    required this.icono,
    this.alTocar,
  });

  final String titulo;
  final String detalle;
  final IconData icono;

  /// Null = todavía no construido. La tarjeta se ve, pero deshabilitada.
  final VoidCallback? alTocar;
}
