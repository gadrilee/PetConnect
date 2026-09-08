import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/casilla.dart';
import '../../../shared/widgets/encabezado.dart';
import '../../../shared/widgets/interruptor.dart';
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
        _errorCostoServicios = (s == null || s < 0)
            ? 'Estimá cuánto paga aparte'
            : null;
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
      Aviso.mostrarToast(context, mensaje: 'Falta marcar la ubicación del inmueble.', tipo: TipoAviso.error);
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
      mensaje: 'Publicado. Está a ${anuncio.minutosCaminando} min caminando de la UAGRM.',
      tipo: TipoAviso.exito,
    );
  }

  @override
  Widget build(BuildContext context) {
    final publicar = context.watch<PublicarProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const Encabezado(titulo: 'Publicar'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Espacio.lg, Espacio.sm, Espacio.lg, Espacio.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (publicar.error != null) ...[
                Aviso(
                  icono: Icons.error_outline,
                  mensaje: publicar.error!,
                  tipo: TipoAviso.error,
                ),
                const SizedBox(height: Espacio.xl),
              ],
              BotonPrincipal(
                etiqueta: 'PUBLICAR',
                etiquetaCargando: 'PUBLICANDO...',
                alTocar: publicar.publicando ? null : _publicar,
                cargando: publicar.publicando,
              ),
              const SizedBox(height: Espacio.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: Espacio.sm),
                  Text(
                    'Tu WhatsApp no aparece en el anuncio',
                    style: AppText.caption(context).copyWith(
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Espacio.lg),
          children: [
            // 1. Qué estás alquilando
            _Titulo('1. Qué estás alquilando'),
            Row(
              children: TipoEspacio.values.map((t) {
                final seleccionado = _tipo == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t != TipoEspacio.values.last ? Espacio.sm : 0.0,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _tipo = t),
                      borderRadius: BorderRadius.circular(Medida.radioSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: seleccionado
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          border: Border.all(
                            color: seleccionado
                                ? AppColors.primary
                                : AppColors.text.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(Medida.radioSm),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.etiqueta,
                          style: AppText.caption(context).copyWith(
                            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                            color: seleccionado ? AppColors.primary : AppColors.text.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
            _Titulo('2. Precio final'),
            Text(
              'El dato n.º 1 para descartar. Declararlo acá te evita '
              'repetirlo por WhatsApp.',
              style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: Espacio.lg),
            CampoTexto(
              etiqueta: 'Alquiler mensual',
              controlador: _alquiler,
              tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
              pista: '0',
              sufijo: Padding(
                padding: const EdgeInsets.only(right: Espacio.md),
                child: Text(
                  'Bs',
                  style: AppText.body(context).copyWith(
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ),
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
            Row(
              children: [
                Expanded(child: Casilla(etiqueta: 'Agua', marcado: _agua, alCambiar: (v) => setState(() => _agua = v ?? false))),
                Expanded(child: Casilla(etiqueta: 'Luz', marcado: _luz, alCambiar: (v) => setState(() => _luz = v ?? false))),
                Expanded(child: Casilla(etiqueta: 'Internet', marcado: _internet, alCambiar: (v) => setState(() => _internet = v ?? false))),
              ],
            ),
            
            if (!_todoIncluido) ...[
              const SizedBox(height: Espacio.lg),
              CampoTexto(
                etiqueta: 'Cuánto paga aparte por los servicios',
                controlador: _costoServicios,
                tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                pista: '0',
                sufijo: Padding(
                  padding: const EdgeInsets.only(right: Espacio.md),
                  child: Text(
                    'Bs',
                    style: AppText.body(context).copyWith(
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                mensajeError:
                    _errorCostoServicios ??
                    publicar.erroresPorCampo['costo_servicios_estimado'],
              ),
            ],
            const SizedBox(height: Espacio.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Espacio.lg, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(Medida.radio),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Precio final',
                    style: AppText.button(context).copyWith(color: AppColors.surface),
                  ),
                  Text(
                    '${NumberFormat.decimalPattern('es').format(_precioFinal)} Bs',
                    style: AppText.heading(context).copyWith(color: AppColors.surface, fontSize: 20),
                  ),
                ],
              ),
            ),

            // 3. Reglas
            const SizedBox(height: Espacio.xxl),
            _Titulo('3. Reglas'),
            Interruptor(
              etiqueta: 'Acepto mascotas',
              marcado: _mascotas,
              alCambiar: (v) => setState(() => _mascotas = v),
            ),
            const SizedBox(height: Espacio.sm),
            CampoTexto(
              etiqueta: 'Reglas (opcional)',
              controlador: _restricciones,
              pista: 'Solo señoritas, sin fiestas...',
            ),

            // 4. Ubicación + 5. Fotos
            const SizedBox(height: Espacio.xxl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Titulo('4. Ubicación'),
                      _BotonSeccion(
                        icono: publicar.hayUbicacion
                            ? Icons.place
                            : Icons.my_location,
                        label: publicar.hayUbicacion
                            ? '${publicar.lat!.toStringAsFixed(4)},\n'
                                  '${publicar.lng!.toStringAsFixed(4)}'
                            : 'Usar GPS',
                        cargando: publicar.buscandoUbicacion,
                        onTap: () => publicar.tomarUbicacion(),
                      ),
                      if (publicar.errorUbicacion != null) ...[
                        const SizedBox(height: Espacio.xs),
                        Text(
                          publicar.errorUbicacion!,
                          style: AppText.caption(context).copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: Espacio.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Titulo('5. Fotos'),
                      _BotonSeccion(
                        icono: Icons.photo_camera_outlined,
                        label: publicar.fotos.isEmpty
                            ? 'Tomar foto'
                            : '${publicar.fotos.length} foto(s)',
                        cargando: false,
                        onTap: () => publicar.agregarFoto(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (publicar.fotos.isNotEmpty) ...[
              const SizedBox(height: Espacio.lg),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: publicar.fotos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Espacio.sm),
                  itemBuilder: (_, i) {
                    final f = publicar.fotos[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Medida.radioSm),
                          child: Image.file(
                            File(f.ruta),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => publicar.quitarFoto(i),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: AppColors.error,
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: Espacio.lg),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.sm),
      child: Text(
        texto,
        style: AppText.heading(context).copyWith(color: AppColors.text, fontSize: 18),
      ),
    );
  }
}

class _BotonSeccion extends StatelessWidget {
  const _BotonSeccion({
    required this.icono,
    required this.label,
    required this.cargando,
    required this.onTap,
  });

  final IconData icono;
  final String label;
  final bool cargando;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: cargando ? null : onTap,
      borderRadius: BorderRadius.circular(Medida.radio),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Medida.radio),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            else
              Icon(icono, size: 24, color: AppColors.primary),
            const SizedBox(height: Espacio.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.caption(context).copyWith(color: AppColors.text.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
