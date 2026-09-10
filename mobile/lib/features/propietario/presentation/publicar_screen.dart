import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/casilla.dart';
import '../../../shared/widgets/controles.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/icono_circulo.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final _titulo = TextEditingController();
  final _alquiler = TextEditingController();
  final _costoServicios = TextEditingController(text: '0');
  final _restricciones = TextEditingController();

  String? _errorTitulo;
  String? _errorAlquiler;
  String? _errorCostoServicios;

  TipoEspacio _tipo = TipoEspacio.habitacion;
  bool _agua = true;
  bool _luz = true;
  bool _internet = false;
  bool _mascotas = false;

  @override
  void initState() {
    super.initState();
    _alquiler.addListener(_refrescar);
    _costoServicios.addListener(_refrescar);
  }

  void _refrescar() => setState(() {});

  @override
  void dispose() {
    _titulo.dispose();
    _alquiler.dispose();
    _costoServicios.dispose();
    _restricciones.dispose();
    super.dispose();
  }

  bool get _todoIncluido => _agua && _luz && _internet;

  double get _precioFinal {
    final a = double.tryParse(_alquiler.text.replaceAll(',', '.')) ?? 0;
    final s = double.tryParse(_costoServicios.text.replaceAll(',', '.')) ?? 0;
    return a + s;
  }

  Future<void> _publicar() async {
    final provider = context.read<PublicarProvider>();

    setState(() {
      _errorTitulo = _titulo.text.trim().isEmpty ? 'Ponele un título' : null;
      final n = double.tryParse(_alquiler.text.replaceAll(',', '.'));
      _errorAlquiler = (n == null || n <= 0) ? 'Poné un monto válido' : null;
      if (!_todoIncluido) {
        final s = double.tryParse(_costoServicios.text.replaceAll(',', '.'));
        _errorCostoServicios =
            (s == null || s < 0) ? 'Estimá cuánto paga aparte' : null;
      } else {
        _errorCostoServicios = null;
      }
    });
    if (_errorTitulo != null ||
        _errorAlquiler != null ||
        _errorCostoServicios != null) {
      return;
    }
    if (!provider.hayUbicacion) {
      Aviso.mostrarToast(
        context,
        mensaje: 'Falta marcar la ubicación del inmueble.',
        tipo: TipoAviso.error,
      );
      return;
    }
    FocusScope.of(context).unfocus();

    final anuncio = await provider.publicar(
      titulo: _titulo.text.trim(),
      tipoEspacio: _tipo,
      precioAlquiler: _alquiler.text.trim().replaceAll(',', '.'),
      incluyeAgua: _agua,
      incluyeLuz: _luz,
      incluyeInternet: _internet,
      costoServiciosEstimado: _todoIncluido
          ? '0'
          : _costoServicios.text.trim().replaceAll(',', '.'),
      aceptaMascotas: _mascotas,
      restricciones: _restricciones.text.trim(),
      direccionReferencia: '',
    );

    if (!mounted || anuncio == null) return;

    context.read<MisAnunciosProvider>().cargar();
    Navigator.of(context).pop(anuncio);
    Aviso.mostrarToast(
      context,
      mensaje:
          'Publicado. Está a ${anuncio.minutosCaminando} min caminando de la UAGRM.',
      tipo: TipoAviso.exito,
    );
  }

  @override
  Widget build(BuildContext context) {
    final publicar = context.watch<PublicarProvider>();
    final tenue = AppColors.text.withValues(alpha: 0.7);
    const teclado = TextInputType.numberWithOptions(decimal: true);

    // CONSTRAINTS: un formulario de una columna, en el orden de Figma, que en
    // un monitor no pasa de 480 y queda centrado.
    return Pagina(
      titulo: 'Publicar',
      ancho: AnchoPagina.formulario,
      pie: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (publicar.error != null) ...[
            Aviso(mensaje: publicar.error!, tipo: TipoAviso.error),
            const SizedBox(height: Espacio.md),
          ],
          BotonPrincipal(
            etiqueta: 'PUBLICAR',
            etiquetaCargando: 'PUBLICANDO...',
            alTocar: publicar.publicando ? null : _publicar,
            cargando: publicar.publicando,
          ),
          const SizedBox(height: Espacio.sm),
          Center(
            child: FilaCondicion(
              enLinea: true,
              icono: Icons.lock_outline,
              colorIcono: AppColors.text.withValues(alpha: 0.5),
              texto: 'Tu WhatsApp no aparece en el anuncio',
              estilo: AppText.caption(context)
                  .copyWith(color: AppColors.text.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
      hijos: [
        // 1. Qué estás alquilando
        const TituloSeccion('1. Qué estás alquilando'),
        const SizedBox(height: Espacio.sm),
        // FLEXBOX: la misma Opcion que en Buscar. Mide lo que su palabra y
        // baja de fila si no entra.
        Wrap(
          spacing: Espacio.md,
          runSpacing: Espacio.sm,
          children: [
            for (final t in TipoEspacio.values)
              Opcion(
                etiqueta: t.etiqueta,
                seleccionada: _tipo == t,
                alTocar: () => setState(() => _tipo = t),
              ),
          ],
        ),
        const SizedBox(height: Espacio.lg),
        CampoTexto(
          etiqueta: 'Título del anuncio',
          controlador: _titulo,
          pista: 'Habitación con baño privado',
          mensajeError: _errorTitulo ?? publicar.erroresPorCampo['titulo'],
        ),

        // 2. Precio final
        const SizedBox(height: Espacio.xxl),
        const TituloSeccion('2. Precio final'),
        const SizedBox(height: Espacio.sm),
        Text(
          'El dato n.º 1 para descartar. Declararlo acá te evita '
          'repetirlo por WhatsApp.',
          style: AppText.caption(context).copyWith(color: tenue),
        ),
        const SizedBox(height: Espacio.lg),
        CampoTexto(
          etiqueta: 'Alquiler mensual',
          controlador: _alquiler,
          tipoTeclado: teclado,
          pista: '0',
          unidad: 'Bs',
          mensajeError:
              _errorAlquiler ?? publicar.erroresPorCampo['precio_alquiler'],
        ),
        const SizedBox(height: Espacio.lg),
        Text(
          'Qué servicios incluye',
          style: AppText.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: Espacio.xs),
        // FLEXBOX: las tres casillas reparten el ancho por partes iguales.
        Row(
          children: [
            Expanded(
              child: Casilla(
                etiqueta: 'Agua',
                marcado: _agua,
                alCambiar: (v) => setState(() => _agua = v ?? false),
              ),
            ),
            Expanded(
              child: Casilla(
                etiqueta: 'Luz',
                marcado: _luz,
                alCambiar: (v) => setState(() => _luz = v ?? false),
              ),
            ),
            Expanded(
              child: Casilla(
                etiqueta: 'Internet',
                marcado: _internet,
                alCambiar: (v) => setState(() => _internet = v ?? false),
              ),
            ),
          ],
        ),
        if (!_todoIncluido) ...[
          const SizedBox(height: Espacio.lg),
          CampoTexto(
            etiqueta: 'Cuánto paga aparte por los servicios',
            controlador: _costoServicios,
            tipoTeclado: teclado,
            pista: '0',
            unidad: 'Bs',
            mensajeError: _errorCostoServicios ??
                publicar.erroresPorCampo['costo_servicios_estimado'],
          ),
        ],
        const SizedBox(height: Espacio.lg),
        Bloque(
          tono: TonoBloque.primario,
          // FLEXBOX: la etiqueta toma el espacio libre y la cifra queda a la
          // derecha.
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Precio final',
                  style: AppText.button(context)
                      .copyWith(color: AppColors.surface),
                ),
              ),
              Text(
                '${NumberFormat.decimalPattern('es').format(_precioFinal)} Bs',
                style: AppText.cifra(context).copyWith(color: AppColors.surface),
              ),
            ],
          ),
        ),

        // 3. Reglas
        const SizedBox(height: Espacio.xxl),
        const TituloSeccion('3. Reglas'),
        const SizedBox(height: Espacio.md),
        Interruptor(
          etiqueta: 'Acepto mascotas',
          encendido: _mascotas,
          alCambiar: (v) => setState(() => _mascotas = v),
        ),
        const SizedBox(height: Espacio.lg),
        CampoTexto(
          etiqueta: 'Reglas (opcional)',
          controlador: _restricciones,
          pista: 'Solo señoritas, sin fiestas...',
        ),

        // 4. Ubicación + 5. Fotos
        const SizedBox(height: Espacio.xxl),
        // FLEXBOX: las dos secciones reparten el ancho por partes iguales.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSeccion('4. Ubicación'),
                  const SizedBox(height: Espacio.sm),
                  _BotonSeccion(
                    icono: publicar.hayUbicacion
                        ? Icons.place
                        : Icons.my_location,
                    etiqueta: publicar.hayUbicacion
                        ? '${publicar.lat!.toStringAsFixed(4)},\n'
                            '${publicar.lng!.toStringAsFixed(4)}'
                        : 'Usar GPS',
                    cargando: publicar.buscandoUbicacion,
                    alTocar: () => publicar.tomarUbicacion(),
                  ),
                  if (publicar.errorUbicacion != null) ...[
                    const SizedBox(height: Espacio.xs),
                    Text(
                      publicar.errorUbicacion!,
                      style: AppText.caption(context)
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Espacio.lg),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSeccion('5. Fotos'),
                  const SizedBox(height: Espacio.sm),
                  _BotonSeccion(
                    icono: Icons.photo_camera_outlined,
                    etiqueta: publicar.fotos.isEmpty
                        ? 'Tomar foto'
                        : '${publicar.fotos.length} foto(s)',
                    cargando: false,
                    alTocar: () => publicar.agregarFoto(),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (publicar.fotos.isNotEmpty) ...[
          const SizedBox(height: Espacio.lg),
          SizedBox(
            height: _MiniaturaLocal.lado,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: publicar.fotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: Espacio.sm),
              itemBuilder: (_, i) => _MiniaturaLocal(
                ruta: publicar.fotos[i].ruta,
                alQuitar: () => publicar.quitarFoto(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Una accion de seccion: marcar la ubicacion o tomar una foto.
///
/// AUTO LAYOUT: alto minimo de 88, no fijo. Si la etiqueta ocupa dos lineas,
/// como las coordenadas, el bloque crece en vez de cortarla.
class _BotonSeccion extends StatelessWidget {
  const _BotonSeccion({
    required this.icono,
    required this.etiqueta,
    required this.cargando,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final bool cargando;
  final VoidCallback alTocar;

  /// 88 menos el relleno de arriba y de abajo del Bloque.
  static const double _altoMinimo = 56;

  @override
  Widget build(BuildContext context) {
    return Bloque(
      tono: TonoBloque.suave,
      alTocar: cargando ? null : alTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _altoMinimo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(icono, size: 24, color: AppColors.primary),
            const SizedBox(height: Espacio.xs),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: AppText.caption(context)
                  .copyWith(color: AppColors.text.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una foto recien tomada, con la cruz para quitarla.
class _MiniaturaLocal extends StatelessWidget {
  const _MiniaturaLocal({required this.ruta, required this.alQuitar});

  final String ruta;
  final VoidCallback alQuitar;

  static const double lado = 72;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Medida.radioSm),
          child: Image.file(
            File(ruta),
            width: lado,
            height: lado,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: Espacio.xs,
          right: Espacio.xs,
          child: Semantics(
            button: true,
            label: 'Quitar foto',
            child: GestureDetector(
              onTap: alQuitar,
              child: const IconoCirculo(
                Icons.close,
                diametro: 20,
                tono: TonoIcono.error,
                relleno: true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
