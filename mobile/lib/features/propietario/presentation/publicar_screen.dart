import 'package:flutter/foundation.dart';
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
/// El boton PUBLICAR esta apagado hasta que el anuncio se puede publicar: el
/// titulo y los montos con un valor que sirve y la ubicacion marcada (Figma
/// "02 Publicar · vacío"). Cada campo se pone en rojo apenas lo que tiene
/// escrito no sirve, y el pie cuenta cuantos hay que corregir ("03 Datos con
/// error"). Con los campos bien pero sin ubicacion, el pie avisa en naranja
/// que falta ese paso ("04 Falta la ubicación"); si el envio falla, avisa en
/// rojo y deja el boton prendido para reintentar ("05 No se pudo publicar").
/// Lo que el backend objeta de un campo va debajo de ese campo y se cuenta
/// como uno mas en rojo, igual que en Crear cuenta; el aviso rojo queda para
/// la conexion, el servidor y lo que no tiene campo. Todo eso se cuenta en el
/// pie, que siempre esta a la vista y nunca tapa el boton. El exito no se
/// cuenta aca: la pantalla devuelve el anuncio y quien la abrio lo muestra en
/// su propio pie.
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

  /// Los campos que la persona ya edito. Un campo vacio que todavia no toco
  /// no esta en rojo: el rojo aparece cuando lo que escribio no sirve.
  final _editados = <TextEditingController>{};

  TipoEspacio _tipo = TipoEspacio.habitacion;
  bool _agua = true;
  bool _luz = true;
  bool _internet = false;
  bool _mascotas = false;

  @override
  void initState() {
    super.initState();
    _vigilar(_titulo, campoApi: 'titulo');
    _vigilar(_alquiler, campoApi: 'precio_alquiler');
    _vigilar(_costoServicios, campoApi: 'costo_servicios_estimado');
  }

  /// Reacciona a lo que se escribe en [controlador]: lo marca como editado,
  /// vuelve a validar y descarta lo que el backend habia objetado de ese
  /// campo, que ya no describe lo que hay escrito. Solo al cambiar el texto:
  /// mover el cursor no es editar.
  void _vigilar(
    TextEditingController controlador, {
    required String campoApi,
  }) {
    var anterior = controlador.text;
    controlador.addListener(() {
      if (!mounted || controlador.text == anterior) return;
      anterior = controlador.text;
      setState(() => _editados.add(controlador));
      context.read<PublicarProvider>().olvidarErrorDeCampo(campoApi);
    });
  }

  @override
  void dispose() {
    _titulo.dispose();
    _alquiler.dispose();
    _costoServicios.dispose();
    _restricciones.dispose();
    super.dispose();
  }

  bool get _todoIncluido => _agua && _luz && _internet;

  static double? _numero(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  /// Lo mismo que se publica: con todo incluido, los servicios no suman,
  /// igual que el `'0'` que manda [_publicar]. La barra que ve el propietario
  /// no puede decir una cifra distinta de la que va a leer la inquilina.
  double get _precioFinal =>
      (_numero(_alquiler.text) ?? 0) +
      (_todoIncluido ? 0 : (_numero(_costoServicios.text) ?? 0));

  /// Los campos de la API que esta pantalla pinta en rojo. Lo que el backend
  /// objete de otra cosa —una foto, la ubicacion— no tiene campo donde ir y
  /// se dice en el aviso del pie.
  static const _camposApi = {
    'titulo',
    'precio_alquiler',
    'costo_servicios_estimado',
  };

  /// La objecion del backend que no cae debajo de ningun campo, si la hay.
  static String? _objecionSuelta(PublicarProvider publicar) => publicar
      .erroresPorCampo
      .entries
      .where((e) => !_camposApi.contains(e.key))
      .map((e) => e.value)
      .firstOrNull;

  // Que le falta a cada campo, con las palabras de Figma "03 Datos con
  // error". `null` es que el valor sirve.

  static String? _validarTitulo(String texto) =>
      texto.trim().isEmpty ? 'Poné un título' : null;

  static String? _validarAlquiler(String texto) {
    final monto = _numero(texto);
    return monto == null || monto <= 0 ? 'Poné un monto válido' : null;
  }

  /// Igual que el alquiler: un monto, aunque puede ser 0 si paga poco aparte.
  static String? _validarServicios(String texto) {
    final monto = _numero(texto);
    return monto == null || monto < 0 ? 'Estimá cuánto paga aparte' : null;
  }

  /// Lo que se ve en rojo debajo de un campo: la validacion local, solo si la
  /// persona ya lo edito, o lo que objeto el backend.
  String? _errorDe(
    TextEditingController controlador,
    String? Function(String) validar,
    String? delBackend,
  ) =>
      (_editados.contains(controlador) ? validar(controlador.text) : null) ??
      delBackend;

  Future<void> _publicar() async {
    final provider = context.read<PublicarProvider>();
    FocusScope.of(context).unfocus();

    // El boton solo se prende con todo listo, asi que aca no se valida nada:
    // los campos se validaron mientras se escribian y la ubicacion ya esta.
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

  /// El aviso del pie.
  ///
  /// Rojo (error) cuando algo fallo, el envio o la camara, o el backend objeto
  /// algo que no es un campo de aca: el boton queda prendido para reintentar.
  /// Lo que objeto de un campo no va aca: va debajo del campo y lo cuenta el
  /// motivo. Naranja (advertencia) cuando falta un paso: el GPS no respondio,
  /// o los campos ya estan bien pero la ubicacion no esta marcada. Con el
  /// formulario a medias no dice nada: el boton apagado y los campos en rojo
  /// ya cuentan lo que falta.
  Aviso? _avisoDelPie(
    PublicarProvider publicar, {
    required bool camposValidos,
  }) {
    final fallo = publicar.error ?? _objecionSuelta(publicar);
    if (fallo != null && fallo != PublicarProvider.faltaUbicacion) {
      return Aviso(mensaje: fallo, tipo: TipoAviso.error);
    }
    final faltaUnPaso = publicar.errorUbicacion ??
        (!publicar.hayUbicacion && (camposValidos || fallo != null)
            ? PublicarProvider.faltaUbicacion
            : null);
    if (faltaUnPaso == null) return null;
    return Aviso(mensaje: faltaUnPaso, tipo: TipoAviso.advertencia);
  }

  /// Cuantos campos hay que corregir, dicho debajo del boton apagado. Con
  /// ninguno en rojo no se dice nada: un formulario vacio no es un error.
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
    final errorTitulo = _errorDe(
      _titulo,
      _validarTitulo,
      publicar.erroresPorCampo['titulo'],
    );
    final errorAlquiler = _errorDe(
      _alquiler,
      _validarAlquiler,
      publicar.erroresPorCampo['precio_alquiler'],
    );
    final errorCostoServicios = _todoIncluido
        ? null
        : _errorDe(
            _costoServicios,
            _validarServicios,
            publicar.erroresPorCampo['costo_servicios_estimado'],
          );
    final enRojo =
        [errorTitulo, errorAlquiler, errorCostoServicios].nonNulls.length;

    // Se puede publicar cuando los valores sirven —los haya tocado o no—, el
    // backend no objeto ninguno y la ubicacion esta marcada. Mientras tanto
    // el boton queda apagado: `null` es como la pieza dice "falta algo".
    final camposValidos = enRojo == 0 &&
        _validarTitulo(_titulo.text) == null &&
        _validarAlquiler(_alquiler.text) == null &&
        (_todoIncluido || _validarServicios(_costoServicios.text) == null);
    final listo = camposValidos && publicar.hayUbicacion;

    final aviso = _avisoDelPie(publicar, camposValidos: camposValidos);
    final motivo = _motivo(enRojo);

    // CONSTRAINTS: un formulario de una columna, en el orden de Figma, que en
    // un monitor no pasa de 480 y queda centrado.
    // AUTO LAYOUT: 32 entre secciones numeradas, 16 entre el titulo de una
    // seccion y su primer campo y entre campo y campo.
    return Pagina(
      titulo: 'Publicar',
      ancho: AnchoPagina.formulario,
      pie: PieAcciones(
        aviso: aviso,
        botonPrincipal: BotonPrincipal(
          etiqueta: 'PUBLICAR',
          etiquetaCargando: 'PUBLICANDO...',
          alTocar: listo && !publicar.publicando ? _publicar : null,
          cargando: publicar.publicando,
          // Lo visible lo dicen el motivo y el aviso; esto es para quien no
          // ve la pantalla.
          pistaDeshabilitado: motivo ??
              aviso?.mensaje ??
              'Completá los datos del anuncio para poder publicar.',
        ),
        motivo: motivo,
        notaWhatsApp: true,
      ),
      hijos: [
        // 1. Qué estás alquilando
        const TituloSeccion('1. Qué estás alquilando'),
        const SizedBox(height: Espacio.md),
        // La misma Opcion que en Buscar, en su otro modo: las tres reparten
        // la fila por partes iguales, como en Figma "02 Publicar". Como se
        // reparten y se centran lo sabe la pieza, no esta pantalla.
        FilaOpciones(
          opciones: [
            for (final t in TipoEspacio.values)
              Opcion(
                etiqueta: t.etiqueta,
                seleccionada: _tipo == t,
                alTocar: () => setState(() => _tipo = t),
              ),
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
                bytes: publicar.fotos[i].bytes,
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
  const _MiniaturaLocal({required this.bytes, required this.alQuitar});

  final Uint8List bytes;
  final VoidCallback alQuitar;

  static const double lado = 72;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Medida.radioSm),
          // Los bytes de la foto recien sacada. Antes era Image.file, que
          // necesita dart:io y en la web no existe.
          child: Image.memory(
            bytes,
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
