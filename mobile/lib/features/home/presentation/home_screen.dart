import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';

/// Pantalla de entrada despues del login.
///
/// Todavia no tiene las funciones del producto: es el punto donde se bifurcan
/// los dos flujos documentados. Cada modulo del `appmap/appmap-v0.1.md` va a
/// colgar de aca.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final perfil = auth.perfil;
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    if (perfil == null) return const SizedBox.shrink();

    final pendientes = perfil.esPropietario
        ? const [
            ('Publicar anuncio', 'Las cuatro condiciones de descarte, la '
                'ubicación por GPS y las fotos con fecha.'),
            ('Gestionar solicitudes', 'Aprobar libera tu contacto, y sólo a '
                'esa persona.'),
            ('Mis anuncios', 'Marcar Ya alquilado en un toque.'),
          ]
        : const [
            ('Buscar', 'Filtrar por precio final, mascotas, tipo y minutos '
                'caminando a la UAGRM.'),
            ('Ver anuncio', 'Los cuatro datos para descartar sin viajar.'),
            ('Solicitar visita', 'Aceptás las condiciones y pedís el contacto.'),
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
          Text('Lo que viene', style: texto.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 4),
          Text(
            'La sesión ya funciona contra la API. Estas pantallas todavía no '
            'están construidas.',
            style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          for (final (titulo, detalle) in pendientes)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(titulo,
                      style: texto.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(detalle),
                  ),
                  trailing: Chip(
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
