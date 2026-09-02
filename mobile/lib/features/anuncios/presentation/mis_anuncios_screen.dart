import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/aviso_error.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';
import 'publicar_screen.dart';

/// Los anuncios del propietario, en cualquier estado.
///
/// Lo que resuelve esta pantalla es que el anuncio muera cuando debe: si
/// marcar "Ya alquilado" cuesta mas de un toque, no va a pasar y los mensajes
/// van a seguir llegando semanas despues.
class MisAnunciosScreen extends StatefulWidget {
  const MisAnunciosScreen({super.key});

  @override
  State<MisAnunciosScreen> createState() => _MisAnunciosScreenState();
}

class _MisAnunciosScreenState extends State<MisAnunciosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MisAnunciosProvider>().cargar(),
    );
  }

  Future<void> _publicar() async {
    // El provider del formulario se crea nuevo en cada publicacion, para no
    // arrastrar fotos ni ubicacion del anuncio anterior.
    final repo = context.read<MisAnunciosProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => PublicarProvider(ctx.read()),
          child: const PublicarScreen(),
        ),
      ),
    );
    if (mounted) repo.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<MisAnunciosProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis anuncios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publicar,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: RefreshIndicator(
        onRefresh: () => estado.cargar(),
        child: Builder(
          builder: (_) {
            if (estado.cargando && estado.anuncios.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (estado.error != null && estado.anuncios.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [AvisoError(mensaje: estado.error!)],
              );
            }
            if (estado.anuncios.isEmpty) return const _SinAnuncios();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: estado.anuncios.length,
              itemBuilder: (_, i) =>
                  _TarjetaGestion(anuncio: estado.anuncios[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SinAnuncios extends StatelessWidget {
  const _SinAnuncios();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.home_work_outlined,
          size: 56,
          color: esquema.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'Todavía no publicaste nada',
          textAlign: TextAlign.center,
          style: texto.titleMedium,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Publicá una vez con las condiciones por delante y el anuncio '
            'filtra solo.',
            textAlign: TextAlign.center,
            style: texto.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// La tarjeta del PROPIETARIO: muestra el estado del anuncio y la accion de
/// marcarlo como alquilado. No es la misma pieza que TarjetaAnuncio, que es
/// la que ve la inquilina para decidir; comparten el tema, no el trabajo.
class _TarjetaGestion extends StatelessWidget {
  const _TarjetaGestion({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final disponible = anuncio.estaDisponible;
    final precio = NumberFormat.decimalPattern(
      'es',
    ).format(double.tryParse(anuncio.precioFinal) ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    anuncio.titulo,
                    style: texto.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(anuncio.estado.etiqueta),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: disponible
                      ? esquema.primaryContainer
                      : esquema.surfaceContainerHighest,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Dato(Icons.payments_outlined, '$precio Bs'),
                _Dato(Icons.directions_walk, '${anuncio.minutosCaminando} min'),
                _Dato(
                  anuncio.aceptaMascotas ? Icons.pets : Icons.block,
                  anuncio.aceptaMascotas ? 'Mascotas' : 'Sin mascotas',
                ),
                _Dato(Icons.home_outlined, anuncio.tipoEspacio.etiqueta),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: disponible
                  ? OutlinedButton.icon(
                      onPressed: () => context
                          .read<MisAnunciosProvider>()
                          .alternarEstado(anuncio),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Marcar Ya alquilado'),
                    )
                  : TextButton.icon(
                      onPressed: () => context
                          .read<MisAnunciosProvider>()
                          .alternarEstado(anuncio),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Volver a publicar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto);

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: esquema.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }
}
