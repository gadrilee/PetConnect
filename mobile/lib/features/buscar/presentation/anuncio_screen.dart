import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/fila_condicion.dart';
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
      if (mounted) {
        setState(() {
          _anuncio = anuncio;
          _cargando = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.mensaje;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el anuncio.';
          _cargando = false;
        });
      }
    }
  }

  void _irASolicitar() {
    final anuncio = _anuncio;
    if (anuncio == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => SolicitudProvider(ctx.read<SolicitudesRepository>()),
          child: SolicitarVisitaScreen(anuncio: anuncio),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anuncio'), leading: const BackButton()),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorBody(mensaje: _error!, alReintentar: _cargar)
          : _AnuncioBody(anuncio: _anuncio!),
      bottomNavigationBar: _anuncio != null
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                Espacio.lg,
                Espacio.sm,
                Espacio.lg,
                MediaQuery.of(context).padding.bottom + Espacio.md,
              ),
              child: BotonPrincipal(
                etiqueta: 'SOLICITAR VISITA',
                alTocar: _irASolicitar,
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
      // El mismo margen de 24 del wireframe para toda la pantalla. Arriba van
      // 16, que es la distancia entre el encabezado y la foto.
      padding: const EdgeInsets.fromLTRB(
        Espacio.lg,
        Espacio.md,
        Espacio.lg,
        Espacio.lg,
      ),
      children: [
        // ---- Galería de fotos ----
        //
        // Va DENTRO del margen y con las esquinas redondeadas, igual que en el
        // wireframe. A sangre completa se comia los 24 de margen y la pantalla
        // arrancaba con una imagen enorme en vez de con la tarjeta del precio,
        // que es la que decide.
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 176,
            width: double.infinity,
            child: anuncio.fotos.isEmpty
                ? Container(
                    color: esquema.surfaceContainerHighest,
                    child: Icon(
                      Icons.home_outlined,
                      size: 64,
                      color: esquema.onSurfaceVariant,
                    ),
                  )
                : PageView.builder(
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
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                          // Fecha de captura (evidencia 4)
                          Positioned(
                            left: Espacio.sm,
                            bottom: Espacio.sm,
                            child: _Pastilla(
                              'Foto ${foto.fechaCaptura.day.toString().padLeft(2, '0')}/'
                              '${foto.fechaCaptura.month.toString().padLeft(2, '0')}/'
                              '${foto.fechaCaptura.year}',
                            ),
                          ),
                          if (anuncio.fotos.length > 1)
                            Positioned(
                              right: Espacio.sm,
                              bottom: Espacio.sm,
                              child: _Pastilla(
                                '${i + 1}/${anuncio.fotos.length}',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ),

        // Foto → título
        const SizedBox(height: Espacio.md),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ 1. ORIENTAR — que estoy viendo ═══
            if (anuncio.titulo.isNotEmpty)
              Text(
                anuncio.titulo,
                style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),

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
                  Text(
                    'Precio final',
                    style: texto.labelSmall?.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Espacio.sm),
                  Text(
                    '${anuncio.precioFinal} Bs / mes',
                    style: texto.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

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
                    runSpacing: Espacio.sm,
                    children: [
                      _Servicio(
                        nombre: 'Agua',
                        incluido: anuncio.serviciosIncluidos['agua'] == true,
                      ),
                      _Servicio(
                        nombre: 'Luz',
                        incluido: anuncio.serviciosIncluidos['luz'] == true,
                      ),
                      _Servicio(
                        nombre: 'Internet',
                        incluido:
                            anuncio.serviciosIncluidos['internet'] == true,
                      ),
                    ],
                  ),

                  // El divisor es una linea de 1 px que vive DENTRO del hueco
                  // de 16: 8 de cada lado. No es un bloque de contenido.
                  const SizedBox(height: Espacio.sm),
                  Divider(
                    height: 1,
                    color: esquema.outline.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: Espacio.sm),

                  // Los otros tres datos comparten peso entre si.
                  FilaCondicion(
                    icono: Icons.directions_walk,
                    texto:
                        '${anuncio.minutosCaminando} min caminando a la UAGRM',
                  ),
                  const SizedBox(height: Espacio.sm),
                  FilaCondicion(
                    icono: anuncio.aceptaMascotas
                        ? Icons.pets
                        : Icons.pets_outlined,
                    texto: anuncio.aceptaMascotas
                        ? 'Acepta mascotas'
                        : 'No acepta mascotas',
                  ),
                  const SizedBox(height: Espacio.sm),
                  FilaCondicion(
                    icono: Icons.home_outlined,
                    texto:
                        '${anuncio.tipoEspacio.etiqueta}'
                        '${anuncio.restricciones.isNotEmpty ? " · ${anuncio.restricciones}" : ""}',
                  ),
                ],
              ),
            ),

            // Entre grupos: 24, como en el wireframe.
            const SizedBox(height: Espacio.lg),

            // ---- Contacto protegido ----
            Container(
              padding: const EdgeInsets.all(Espacio.md),
              decoration: BoxDecoration(
                color: esquema.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: esquema.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: esquema.onSurfaceVariant,
                  ),
                  const SizedBox(width: Espacio.sm),
                  Expanded(
                    child: Text(
                      'El contacto del propietario está protegido. '
                      'Se libera solo cuando aprobás una solicitud.',
                      style: texto.bodySmall?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
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
                border: Border.all(
                  color: esquema.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                anuncio.direccionReferencia.isNotEmpty
                    ? anuncio.direccionReferencia
                    : 'Ubicación aproximada — visible al aprobar la solicitud',
                textAlign: TextAlign.center,
                style: texto.bodySmall?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Etiqueta chica sobre la foto: la fecha de captura y el contador.
///
/// El relleno es de 4 arriba y abajo — medio paso, no separa dos elementos:
/// con el texto de 16 da una pastilla de 24, que si cae en la escala.
class _Pastilla extends StatelessWidget {
  const _Pastilla(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.sm,
        vertical: Espacio.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
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
        padding: const EdgeInsets.all(Espacio.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: Espacio.md),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: Espacio.md),
            OutlinedButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
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
        Icon(
          incluido ? Icons.check_circle : Icons.cancel_outlined,
          size: 15,
          color: incluido ? esquema.primary : esquema.outline,
        ),
        const SizedBox(width: Espacio.sm),
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
