import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/foto_inmueble.dart';
import '../../../shared/widgets/pastilla.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../../propietario/data/anuncio.dart';
import '../data/solicitudes_repository.dart';
import '../providers/solicitud_provider.dart';
import 'solicitar_visita_screen.dart';

/// Vista 04 — Detalle del anuncio.
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
  static const _titulo = 'Anuncio';

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

  void _reintentar() {
    setState(() {
      _cargando = true;
      _error = null;
    });
    _cargar();
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
    final anuncio = _anuncio;

    if (_cargando) {
      return const Pagina(titulo: _titulo, cuerpo: CircularProgressIndicator());
    }

    if (_error != null || anuncio == null) {
      return Pagina(
        titulo: _titulo,
        cuerpo: EstadoVacio(
          icono: Icons.error_outline,
          titulo: _error ?? 'No se pudo cargar el anuncio.',
          esError: true,
          accion: 'Reintentar',
          alAccion: _reintentar,
        ),
      );
    }

    return Pagina(
      titulo: _titulo,
      pie: PieAcciones(
        botonPrincipal: BotonPrincipal(
          etiqueta: 'SOLICITAR VISITA',
          alTocar: _irASolicitar,
        ),
      ),
      hijos: [
        // GRID: lo que decide (fotos, precio y condiciones) ocupa 8 columnas y
        // lo que acompana 4. En movil todo va a 12, en el orden del wireframe.
        Grilla12(
          separacionFilas: Espacio.lg,
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 6, escritorio: 8),
              child: _Principal(anuncio: anuncio),
            ),
            CeldaGrilla(
              columnas: const Columnas(tablet: 6, escritorio: 4),
              child: _Acompana(anuncio: anuncio),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fotos, titulo y las cuatro condiciones de descarte.
class _Principal extends StatelessWidget {
  const _Principal({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    final restricciones = anuncio.restricciones.isNotEmpty
        ? ' · ${anuncio.restricciones}'
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Galeria(anuncio: anuncio),
        const SizedBox(height: Espacio.md),

        // ═══ 1. ORIENTAR — que estoy viendo ═══
        if (anuncio.titulo.isNotEmpty)
          Text(
            anuncio.titulo,
            style: AppText.titulo(context).copyWith(color: AppColors.text),
          ),

        // Espacio de GRUPO: separa orientar de informar.
        const SizedBox(height: Espacio.lg),

        // ═══ 2. INFORMAR — las cuatro condiciones de descarte ═══
        //
        // Van juntas dentro de un mismo bloque porque se leen como una sola
        // decision: "¿me sirve o lo descarto?".
        Bloque(
          tono: TonoBloque.suave,
          hijos: [
            // El precio final es el criterio de descarte n.º 1 del brief,
            // asi que se lee primero y con mas peso: la barra verde.
            PrecioFinal(monto: anuncio.precioFinal),

            // ─── Corregido tras la prueba con usuaria (27/08) ───
            //
            // Ella leyo el precio destacado y IGUAL pregunto "¿cuanto es con
            // luz?". Por eso los servicios van pegados a la cifra y lo que NO
            // esta incluido aparece explicito en vez de omitirse: una fila
            // por servicio, con el check verde o el bloqueo gris.
            for (final (clave, nombre) in const [
              ('agua', 'Agua'),
              ('luz', 'Luz'),
              ('internet', 'Internet'),
            ]) ...[
              const SizedBox(height: Espacio.sm),
              _servicio(
                context,
                nombre,
                anuncio.serviciosIncluidos[clave] == true,
              ),
            ],

            // El divisor es una linea de 1 px que vive DENTRO del hueco de 16:
            // 8 de cada lado. No es un bloque de contenido.
            const SizedBox(height: Espacio.sm),
            Divider(height: 1, color: AppColors.text12),
            const SizedBox(height: Espacio.sm),

            // Los otros tres datos comparten peso entre si.
            FilaCondicion(
              icono: Icons.directions_walk,
              texto: '${anuncio.minutosCaminando} min caminando a la UAGRM',
            ),
            const SizedBox(height: Espacio.sm),
            FilaCondicion(
              icono: anuncio.aceptaMascotas ? Icons.pets : Icons.pets_outlined,
              texto: anuncio.aceptaMascotas
                  ? 'Acepta mascotas'
                  : 'No acepta mascotas',
            ),
            const SizedBox(height: Espacio.sm),
            FilaCondicion(
              icono: Icons.home_outlined,
              texto: '${anuncio.tipoEspacio.etiqueta}$restricciones',
            ),
          ],
        ),
      ],
    );
  }
}

/// La galeria de fotos, cada una con su fecha de captura debajo.
///
/// La fecha no va sobre la foto sino en una pastilla debajo, como en Figma:
/// se lee sobre el fondo de la pagina y no depende de lo que tenga la imagen.
class _Galeria extends StatefulWidget {
  const _Galeria({required this.anuncio});

  final Anuncio anuncio;

  @override
  State<_Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<_Galeria> {
  /// Que foto se esta mirando: la pastilla de la fecha la sigue.
  int _actual = 0;

  @override
  Widget build(BuildContext context) {
    final fotos = widget.anuncio.fotos;
    String dos(int n) => n.toString().padLeft(2, '0');

    // CONSTRAINTS: la galeria guarda la proporcion 16:9. En un telefono mide
    // 176 de alto, como en el wireframe, y en un monitor crece con su columna.
    final imagen = AspectRatio(
      aspectRatio: 16 / 9,
      child: fotos.isEmpty
          ? const FotoInmueble(url: null)
          : ClipRRect(
              borderRadius: BorderRadius.circular(Medida.radioSm),
              child: PageView.builder(
                itemCount: fotos.length,
                onPageChanged: (i) => setState(() => _actual = i),
                itemBuilder: (_, i) =>
                    FotoInmueble(url: fotos[i].imagen, radio: 0),
              ),
            ),
    );

    if (fotos.isEmpty) return imagen;

    final fecha = fotos[_actual].fechaCaptura;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        imagen,
        const SizedBox(height: Espacio.sm),
        // FLEXBOX: la fecha a la izquierda y, si hay varias fotos, el
        // contador anclado a la derecha.
        Row(
          children: [
            // Fecha de captura (evidencia 4)
            Pastilla('Foto ${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}'),
            const Spacer(),
            if (fotos.length > 1) Pastilla('${_actual + 1}/${fotos.length}'),
          ],
        ),
      ],
    );
  }
}

/// Lo que acompana la decision: el contacto protegido y la ubicacion.
class _Acompana extends StatelessWidget {
  const _Acompana({required this.anuncio});

  final Anuncio anuncio;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Aviso(
          icono: Icons.lock_outline,
          mensaje:
              'El contacto del propietario está protegido. Se libera solo cuando aprobás una solicitud.',
        ),
        const SizedBox(height: Espacio.lg),
        // La ubicacion exacta no se publica: el aviso lo dice, no un bloque.
        Aviso(
          tipo: TipoAviso.info,
          icono: Icons.place_outlined,
          mensaje: anuncio.direccionReferencia.isNotEmpty
              ? anuncio.direccionReferencia
              : 'Ubicación aproximada — visible al aprobar la solicitud',
        ),
      ],
    );
  }
}

/// Un servicio del precio final, tal como se lee junto a la cifra.
///
/// Muestra tanto los incluidos como los que NO lo estan: si no aparece, no se
/// sabe si esta o no esta. El check verde dice "incluido"; el bloqueo gris,
/// "se paga aparte".
Widget _servicio(BuildContext context, String nombre, bool incluido) {
  return FilaCondicion(
    icono: incluido ? Icons.check_circle : Icons.block,
    colorIcono: incluido ? AppColors.success : AppColors.text40,
    texto: incluido ? nombre : '$nombre no',
    estilo: AppText.caption(context).copyWith(
      color: incluido ? AppColors.text : AppColors.text50,
      fontWeight: incluido ? FontWeight.w600 : FontWeight.normal,
    ),
  );
}
