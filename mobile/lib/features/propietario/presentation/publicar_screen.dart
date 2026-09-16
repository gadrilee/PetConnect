import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/casilla.dart';
import '../../../shared/widgets/controles.dart';
import '../../../shared/widgets/icono_circulo.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../../../shared/widgets/titulo_seccion.dart';
import '../data/anuncio.dart';
import '../providers/publicar_provider.dart';

/// Publicar un anuncio: las cuatro condiciones de descarte, GPS y fotos.
///
/// Todo lo que sale mal se cuenta en el pie, que siempre esta a la vista:
/// el aviso (no se pudo publicar, falta la ubicacion), el motivo en rojo
/// (cuantos campos corregir) y el candado del WhatsApp. El exito no se
/// cuenta aca: la pantalla devuelve el anuncio y quien la abrio lo muestra
/// en su propio pie.
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
    // Con campos en rojo no se envia nada: el motivo del pie dice cuantos.
    if (_errorTitulo != null ||
        _errorAlquiler != null ||
        _errorCostoServicios != null) {
      return;
    }
    FocusScope.of(context).unfocus();

    // Sin ubicacion el provider no envia y deja el aviso; el pie lo muestra.
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

    // El exito lo cuenta la pantalla que vuelve a verse, en su pie; y es ella
    // la que recarga la lista al recibir el anuncio, no esta.
    Navigator.of(context).pop(anuncio);
  }

  /// El aviso del pie: que la publicacion fallo (error) o que falta un paso
  /// para poder publicar, como marcar la ubicacion (advertencia).
  Aviso? _avisoDelPie(PublicarProvider publicar) {
    final mensaje = publicar.error ?? publicar.errorUbicacion;
    if (mensaje == null) return null;
    final faltaUnPaso = publicar.error == null ||
        publicar.error == PublicarProvider.faltaUbicacion;
    return Aviso(
      mensaje: mensaje,
      tipo: faltaUnPaso ? TipoAviso.advertencia : TipoAviso.error,
    );
  }

  /// Cuantos campos hay que corregir, dicho debajo del boton.
  static String? _motivo(int enRojo) => switch (enRojo) {
        0 => null,
        1 => 'Corregí el campo marcado en rojo para poder publicar.',
        _ => 'Corregí los $enRojo campos marcados en rojo para poder publicar.',
      };

  @override
  Widget build(BuildContext context) {
    final publicar = context.watch<PublicarProvider>();
    final tenue = AppColors.text70;
    const teclado = TextInputType.numberWithOptions(decimal: true);

    // Lo que se ve en rojo: la validacion local o la del backend, campo por
    // campo. El pie cuenta cuantos son.
    final errorTitulo = _errorTitulo ?? publicar.erroresPorCampo['titulo'];
    final errorAlquiler =
        _errorAlquiler ?? publicar.erroresPorCampo['precio_alquiler'];
    final errorCostoServicios = _todoIncluido
        ? null
        : _errorCostoServicios ??
            publicar.erroresPorCampo['costo_servicios_estimado'];
    final enRojo =
        [errorTitulo, errorAlquiler, errorCostoServicios].nonNulls.length;

    // CONSTRAINTS: un formulario de una columna, en el orden de Figma, que en
    // un monitor no pasa de 480 y queda centrado.
    // AUTO LAYOUT: 32 entre secciones numeradas, 16 entre el titulo de una
    // seccion y su primer campo y entre campo y campo.
    return Pagina(
      titulo: 'Publicar',
      ancho: AnchoPagina.formulario,
      pie: PieAcciones(
        aviso: _avisoDelPie(publicar),
        botonPrincipal: BotonPrincipal(
          etiqueta: 'PUBLICAR',
          etiquetaCargando: 'PUBLICANDO...',
          alTocar: publicar.publicando ? null : _publicar,
          cargando: publicar.publicando,
        ),
        motivo: _motivo(enRojo),
        notaWhatsApp: true,
      ),
      hijos: [
        // 1. Qué estás alquilando
        const TituloSeccion('1. Qué estás alquilando'),
        const SizedBox(height: Espacio.md),
        // FLEXBOX: las tres opciones reparten el ancho por partes iguales,
        // igual que en Buscar, para que "Casa" no quede mas angosta.
        Row(
          children: [
            for (final t in TipoEspacio.values) ...[
              if (t != TipoEspacio.values.first)
                const SizedBox(width: Espacio.md),
              Expanded(
                child: Opcion(
                  etiqueta: t.etiqueta,
                  seleccionada: _tipo == t,
                  alTocar: () => setState(() => _tipo = t),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Título del anuncio',
          controlador: _titulo,
          pista: 'Habitación con baño privado',
          mensajeError: errorTitulo,
        ),

        // 2. Precio final
        const SizedBox(height: Espacio.xl),
        const TituloSeccion('2. Precio final'),
        const SizedBox(height: Espacio.md),
        Text(
          'El dato n.º 1 para descartar. Declararlo acá te evita '
          'repetirlo por WhatsApp.',
          style: AppText.caption(context).copyWith(color: tenue),
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Alquiler mensual',
          controlador: _alquiler,
          tipoTeclado: teclado,
          pista: '0',
          unidad: 'Bs',
          mensajeError: errorAlquiler,
        ),
        const SizedBox(height: Espacio.md),
        Text(
          'Qué servicios incluye',
          style: AppText.body(context).copyWith(
            fontWeight: FontWeight.w600,
            color: tenue,
          ),
        ),
        // La etiqueta y sus casillas se leen juntas: 8, como dentro de un
        // campo.
        const SizedBox(height: Espacio.sm),
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
          const SizedBox(height: Espacio.md),
          CampoTexto(
            etiqueta: 'Cuánto paga aparte por los servicios',
            controlador: _costoServicios,
            tipoTeclado: teclado,
            pista: '0',
            unidad: 'Bs',
            mensajeError: errorCostoServicios,
          ),
        ],
        const SizedBox(height: Espacio.md),
        // La barra "Precio final" de Figma: el unico bloque primario de la
        // pantalla. Es la misma pieza que ve la inquilina en el anuncio, y
        // es ella la que escribe la cifra: aca va el monto crudo.
        PrecioFinal(monto: '$_precioFinal'),

        // 3. Reglas
        const SizedBox(height: Espacio.xl),
        const TituloSeccion('3. Reglas'),
        const SizedBox(height: Espacio.md),
        Interruptor(
          etiqueta: 'Acepto mascotas',
          encendido: _mascotas,
          alCambiar: (v) => setState(() => _mascotas = v),
        ),
        const SizedBox(height: Espacio.md),
        CampoTexto(
          etiqueta: 'Reglas (opcional)',
          controlador: _restricciones,
          pista: 'Solo señoritas, sin fiestas...',
        ),

        // 4. Ubicación + 5. Fotos
        const SizedBox(height: Espacio.xl),
        // FLEXBOX: las dos secciones reparten el ancho por partes iguales, con
        // el medianil de 16 entre las dos. Si el GPS falla, lo dice el aviso
        // del pie, no un texto suelto debajo del boton.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSeccion('4. Ubicación'),
                  const SizedBox(height: Espacio.md),
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
                ],
              ),
            ),
            const SizedBox(width: Espacio.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloSeccion('5. Fotos'),
                  const SizedBox(height: Espacio.md),
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
          const SizedBox(height: Espacio.md),
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
              style: AppText.caption(context).copyWith(color: AppColors.text70),
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
