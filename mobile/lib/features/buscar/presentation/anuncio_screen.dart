import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../anuncios/data/anuncio.dart';
import '../data/solicitudes_repository.dart';
import '../providers/solicitud_provider.dart';
import 'solicitar_visita_screen.dart';

/// Vista 03 — Detalle del anuncio.
///
/// Muestra las cuatro condiciones de descarte (precio final, mascotas, tipo,
/// distancia), la galería de fotos con fecha de captura, las restricciones y
/// los servicios incluidos. Desde aquí se puede solicitar la visita.
class AnuncioScreen extends StatefulWidget {
  const AnuncioScreen({super.key, required this.anuncioId});

  final int anuncioId;

  @override
  State<AnuncioScreen> createState() => _AnuncioScreenState();
}

class _AnuncioScreenState extends State<AnuncioScreen> {
  Anuncio? _anuncio;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final repo = context.read<SolicitudesRepository>();
      final anuncio = await repo.detalle(widget.anuncioId);
      if (mounted) setState(() { _anuncio = anuncio; _cargando = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.mensaje; _cargando = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'No se pudo cargar el anuncio.'; _cargando = false; });
    }
  }

  void _irASolicitar() {
    final anuncio = _anuncio;
    if (anuncio == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (ctx) => SolicitudProvider(ctx.read<SolicitudesRepository>()),
        child: SolicitarVisitaScreen(anuncio: anuncio),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncio'),
        leading: const BackButton(),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(mensaje: _error!, alReintentar: _cargar)
              : _AnuncioBody(anuncio: _anuncio!),
      bottomNavigationBar: _anuncio != null
          ? Padding(
              padding: EdgeInsets.fromLTRB(Espacio.lg, Espacio.sm, Espacio.lg,
                  MediaQuery.of(context).padding.bottom + Espacio.md),
              child: FilledButton(
                onPressed: _irASolicitar,
                child: const Text('SOLICITAR VISITA'),
              ),
            )
          : null,
    );
  }
}

// --------------------------------------------------------- Body del anuncio

class _AnuncioBody extends StatelessWidget {
  const _AnuncioBody({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // ---- Galería de fotos ----
        if (anuncio.fotos.isNotEmpty)
          SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: anuncio.fotos.length,
              itemBuilder: (_, i) {
                final foto = anuncio.fotos[i];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      foto.imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, e) => Container(
                        color: esquema.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                    // Fecha de captura (evidencia 4)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Foto ${foto.fechaCaptura.day.toString().padLeft(2, '0')}/'
                          '${foto.fechaCaptura.month.toString().padLeft(2, '0')}/'
                          '${foto.fechaCaptura.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                    if (anuncio.fotos.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${i + 1}/${anuncio.fotos.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          )
        else
          Container(
            height: 180,
            color: esquema.surfaceContainerHighest,
            child: Icon(Icons.home_outlined, size: 64, color: esquema.onSurfaceVariant),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
              Espacio.lg, Espacio.lg, Espacio.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ 1. ORIENTAR — que estoy viendo ═══
              if (anuncio.titulo.isNotEmpty)
                Text(anuncio.titulo,
                    style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w600)),

              // Espacio de GRUPO: separa orientar de informar.
              const SizedBox(height: Espacio.lg),

              // ═══ 2. INFORMAR — las cuatro condiciones de descarte ═══
              //
              // Van juntas dentro de un mismo contenedor porque se leen como
              // una sola decision: "¿me sirve o lo descarto?". Antes estaban
              // sueltas y la separacion entre ellas era casi la misma que con
              // el titulo, asi que no se veia que formaran un grupo.
              Container(
                padding: const EdgeInsets.all(Espacio.md),
                decoration: BoxDecoration(
                  color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // El precio final es el criterio de descarte n.º 1 del
                    // brief, asi que se lee primero y con mas peso.
                    Text('Precio final',
                        style: texto.labelSmall
                            ?.copyWith(color: esquema.onSurfaceVariant)),
                    const SizedBox(height: Espacio.xs),
                    Text('${anuncio.precioFinal} Bs / mes',
                        style: texto.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),

                    // ─── Corregido tras la prueba con usuaria (27/08) ───
                    //
                    // Ella leyo el precio destacado y IGUAL pregunto
                    // "¿cuanto es con luz?". El numero solo es ambiguo: no
                    // significa nada hasta saber que cubre.
                    //
                    // Antes esto era una linea de texto chico y gris, y los
                    // servicios vivian en OTRA seccion mas abajo de la
                    // pantalla. Ahora van pegados a la cifra y, sobre todo,
                    // lo que NO esta incluido aparece explicito en vez de
                    // omitirse: callarlo es lo que obliga a preguntar.
                    const SizedBox(height: Espacio.sm),
                    Wrap(
                      spacing: Espacio.sm,
                      runSpacing: Espacio.xs,
                      children: [
                        _Servicio(
                            nombre: 'Agua',
                            incluido: anuncio.serviciosIncluidos['agua'] == true),
                        _Servicio(
                            nombre: 'Luz',
                            incluido: anuncio.serviciosIncluidos['luz'] == true),
                        _Servicio(
                            nombre: 'Internet',
                            incluido:
                                anuncio.serviciosIncluidos['internet'] == true),
                      ],
                    ),

                    const SizedBox(height: Espacio.md),
                    Divider(
                        height: 1,
                        color: esquema.outline.withValues(alpha: 0.3)),
                    const SizedBox(height: Espacio.md),

                    // Los otros tres datos comparten peso entre si.
                    _FilaCondicion(
                      icono: Icons.directions_walk,
                      texto:
                          '${anuncio.minutosCaminando} min caminando a la UAGRM',
                      esquema: esquema,
                    ),
                    const SizedBox(height: Espacio.sm),
                    _FilaCondicion(
                      icono:
                          anuncio.aceptaMascotas ? Icons.pets : Icons.pets_outlined,
                      texto: anuncio.aceptaMascotas
                          ? 'Acepta mascotas'
                          : 'No acepta mascotas',
                      esquema: esquema,
                    ),
                    const SizedBox(height: Espacio.sm),
                    _FilaCondicion(
                      icono: Icons.home_outlined,
                      texto: '${anuncio.tipoEspacio.etiqueta}'
                          '${anuncio.restricciones.isNotEmpty ? " · ${anuncio.restricciones}" : ""}',
                      esquema: esquema,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Espacio.md),

              // ---- Contacto protegido ----
              Container(
                padding: const EdgeInsets.all(Espacio.md),
                decoration: BoxDecoration(
                  color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: esquema.onSurfaceVariant),
                    const SizedBox(width: Espacio.sm),
                    Expanded(
                      child: Text(
                        'El contacto del propietario está protegido. '
                        'Se libera solo cuando aprobás una solicitud.',
                        style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),


              // ---- Ubicación aproximada ----
              const SizedBox(height: Espacio.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Espacio.md),
                decoration: BoxDecoration(
                  color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: esquema.outline.withValues(alpha: 0.4)),
                ),
                child: Text(
                  anuncio.direccionReferencia.isNotEmpty
                      ? anuncio.direccionReferencia
                      : 'Ubicación aproximada — visible al aprobar la solicitud',
                  textAlign: TextAlign.center,
                  style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                ),
              ),

              const SizedBox(height: Espacio.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaCondicion extends StatelessWidget {
  const _FilaCondicion({
    required this.icono,
    required this.texto,
    required this.esquema,
  });

  final IconData icono;
  final String texto;
  final ColorScheme esquema;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: esquema.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icono, size: 18, color: esquema.primary),
        ),
        const SizedBox(width: Espacio.sm),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: alReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Un servicio del precio final, tal como se lee junto a la cifra.
///
/// Muestra tanto los incluidos como los que NO lo estan. Omitir los que
/// faltan fue lo que hizo que la usuaria de la prueba tuviera que preguntar
/// "¿cuanto es con luz?": si no aparece, no se sabe si esta o no esta.
class _Servicio extends StatelessWidget {
  const _Servicio({required this.nombre, required this.incluido});

  final String nombre;
  final bool incluido;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final color = incluido ? esquema.onSurface : esquema.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(incluido ? Icons.check_circle : Icons.cancel_outlined,
            size: 15, color: incluido ? esquema.primary : esquema.outline),
        const SizedBox(width: Espacio.xs),
        Text(
          incluido ? nombre : '$nombre no',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: incluido ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
