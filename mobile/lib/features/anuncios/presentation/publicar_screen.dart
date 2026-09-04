import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/aviso_error.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';

/// Formulario de publicar (flujo v0.1).
///
/// Las cuatro condiciones de descarte son obligatorias. Esa obligatoriedad es
/// el producto: si se pudieran dejar vacias, la app seria otro tablon de
/// anuncios como los grupos de Facebook.
///
/// El diseño sigue el wireframe v0.1 de Figma: todo visible en una sola
/// pantalla. Las secciones de Ubicación y Fotos van en fila para no ocupar
/// espacio vertical innecesario. El botón Publicar queda fijo al fondo.
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

  // Errores locales por campo (validados al intentar publicar)
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
    // El precio final se recalcula mientras escribe: es el dato que decide
    // el descarte, asi que tiene que estar a la vista todo el tiempo.
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

    // Validación local antes de llamar al servidor
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
        _errorCostoServicios != null) return;
    if (!provider.hayUbicacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta marcar la ubicación del inmueble.'),
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Publicado. Está a ${anuncio.minutosCaminando} min '
          'caminando de la UAGRM.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final publicar = context.watch<PublicarProvider>();
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar')),

      // ── Botón fijo al fondo ───────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (publicar.error != null) ...[
                AvisoError(mensaje: publicar.error!),
                const SizedBox(height: 8),
              ],
              BotonPrincipal(
                etiqueta: 'PUBLICAR',
                etiquetaCargando: 'PUBLICANDO...',
                alTocar: publicar.publicando ? null : _publicar,
                cargando: publicar.publicando,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: esquema.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tu WhatsApp no aparece en el anuncio',
                    style: texto.bodySmall
                        ?.copyWith(color: esquema.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ── Cuerpo con scroll ─────────────────────────────────────────────────
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            children: [
              // ─── 1. Qué estás alquilando ──────────────────────────────
              _Titulo('1. Qué estás alquilando'),
              Row(
                children: TipoEspacio.values.map((t) {
                  final seleccionado = _tipo == t;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: t != TipoEspacio.values.last ? 8.0 : 0.0,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _tipo = t),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? esquema.surfaceContainerHighest
                                : Colors.transparent,
                            border: Border.all(
                              color: seleccionado
                                  ? esquema.outline
                                  : esquema.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            t.etiqueta,
                            style: texto.bodySmall?.copyWith(
                              fontWeight: seleccionado
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: seleccionado
                                  ? esquema.onSurface
                                  : esquema.onSurfaceVariant,
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
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Título del anuncio',
                controlador: _titulo,
                pista: 'Habitación con baño privado',
                mensajeError: _errorTitulo ??
                    publicar.erroresPorCampo['titulo'],
              ),

              // ─── 2. Precio final ──────────────────────────────────────
              const SizedBox(height: 32),
              _Titulo('2. Precio final'),
              Text(
                'El dato n.º 1 para descartar. Declararlo acá te evita '
                'repetirlo por WhatsApp.',
                style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              CampoTexto(
                etiqueta: 'Alquiler mensual',
                controlador: _alquiler,
                tipoTeclado:
                    const TextInputType.numberWithOptions(decimal: true),
                pista: '0',
                sufijo: Padding(
                  padding: const EdgeInsets.only(right: Espacio.md),
                  child: Text(
                    'Bs',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                ),
                mensajeError: _errorAlquiler ??
                    publicar.erroresPorCampo['precio_alquiler'],
              ),
              const SizedBox(height: 16),
              // Checkboxes de servicios en fila compacta
              Row(
                children: [
                  Text('Qué servicios incluye',
                      style: texto.labelMedium
                          ?.copyWith(color: esquema.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _CheckCompacto(
                      label: 'Agua',
                      value: _agua,
                      onChanged: (v) => setState(() => _agua = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CheckCompacto(
                      label: 'Luz',
                      value: _luz,
                      onChanged: (v) => setState(() => _luz = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CheckCompacto(
                      label: 'Internet',
                      value: _internet,
                      onChanged: (v) => setState(() => _internet = v ?? false),
                    ),
                  ),
                ],
              ),
              // Campo de servicios extra solo cuando no todo está incluido
              if (!_todoIncluido) ...[
                const SizedBox(height: 16),
                CampoTexto(
                  etiqueta: 'Cuánto paga aparte por los servicios',
                  controlador: _costoServicios,
                  tipoTeclado:
                      const TextInputType.numberWithOptions(decimal: true),
                  pista: '0',
                  sufijo: Padding(
                    padding: const EdgeInsets.only(right: Espacio.md),
                    child: Text(
                      'Bs',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  mensajeError: _errorCostoServicios ??
                      publicar.erroresPorCampo['costo_servicios_estimado'],
                ),
              ],
              const SizedBox(height: 16),
              // Bloque de precio final destacado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: esquema.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Precio final',
                      style: texto.titleSmall?.copyWith(
                        color: esquema.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${NumberFormat.decimalPattern('es').format(_precioFinal)} Bs',
                      style: texto.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: esquema.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── 3. Reglas ────────────────────────────────────────────
              const SizedBox(height: 24),
              _Titulo('3. Reglas'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acepto mascotas'),
                value: _mascotas,
                onChanged: (v) => setState(() => _mascotas = v),
              ),
              CampoTexto(
                etiqueta: 'Reglas (opcional)',
                controlador: _restricciones,
                pista: 'Solo señoritas, sin fiestas...',
              ),

              // ─── 4. Ubicación  +  5. Fotos (en fila, como en Figma) ──
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. Ubicación
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
                          const SizedBox(height: 8),
                          Text(
                            publicar.errorUbicacion!,
                            style: texto.bodySmall
                                ?.copyWith(color: esquema.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 5. Fotos
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

              // Miniaturas de fotos debajo de los botones
              if (publicar.fotos.isNotEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: publicar.fotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = publicar.fotos[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
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
                                backgroundColor: esquema.error,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: esquema.onError,
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

              const SizedBox(height: 8),
            ],
          ),
        ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Checkbox compacto en fila para los servicios incluidos.
class _CheckCompacto extends StatelessWidget {
  const _CheckCompacto({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? esquema.primary : esquema.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
          color: value
              ? esquema.primaryContainer.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: value ? esquema.primary : esquema.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: value ? esquema.primary : esquema.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón cuadrado grande para Ubicación y Fotos (igual que en el wireframe).
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
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return InkWell(
      onTap: cargando ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: esquema.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esquema.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icono, size: 24, color: esquema.primary),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
