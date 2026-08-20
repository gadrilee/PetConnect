import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/aviso_error.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';

/// Formulario de publicar (flujo v0.1).
///
/// Las cuatro condiciones de descarte son obligatorias. Esa obligatoriedad es
/// el producto: si se pudieran dejar vacias, la app seria otro tablon de
/// anuncios como los grupos de Facebook.
class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  State<PublicarScreen> createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final _formulario = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _alquiler = TextEditingController();
  final _costoServicios = TextEditingController(text: '0');
  final _restricciones = TextEditingController();
  final _referencia = TextEditingController();

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
    _referencia.dispose();
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

    if (!_formulario.currentState!.validate()) return;
    if (!provider.hayUbicacion) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Falta marcar la ubicación del inmueble.'),
      ));
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
      costoServiciosEstimado:
          _todoIncluido ? '0' : _costoServicios.text.trim().replaceAll(',', '.'),
      aceptaMascotas: _mascotas,
      restricciones: _restricciones.text.trim(),
      direccionReferencia: _referencia.text.trim(),
    );

    if (!mounted || anuncio == null) return;

    context.read<MisAnunciosProvider>().cargar();
    Navigator.of(context).pop(anuncio);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Publicado. Está a ${anuncio.minutosCaminando} min '
          'caminando de la UAGRM.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final publicar = context.watch<PublicarProvider>();
    final texto = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar')),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // ---------------------------------------------- tipo de espacio
              _Titulo('1. Qué estás alquilando'),
              SegmentedButton<TipoEspacio>(
                segments: TipoEspacio.values
                    .map((t) => ButtonSegment(value: t, label: Text(t.etiqueta)))
                    .toList(),
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titulo,
                decoration: const InputDecoration(
                  labelText: 'Título del anuncio',
                  hintText: 'Habitación con baño privado',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Ponele un título' : null,
              ),

              // ------------------------------------------------------- precio
              const SizedBox(height: 28),
              _Titulo('2. Precio final'),
              Text(
                'El precio con los servicios incluidos es el dato n.º 1 para '
                'descartar. Declararlo acá te evita repetirlo por WhatsApp.',
                style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _alquiler,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Alquiler mensual',
                  suffixText: 'Bs',
                  errorText: publicar.erroresPorCampo['precio_alquiler'],
                ),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Poné un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text('Qué servicios incluye',
                  style: texto.labelLarge?.copyWith(color: esquema.onSurfaceVariant)),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Agua'),
                value: _agua,
                onChanged: (v) => setState(() => _agua = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Luz'),
                value: _luz,
                onChanged: (v) => setState(() => _luz = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Internet'),
                value: _internet,
                onChanged: (v) => setState(() => _internet = v ?? false),
              ),

              // El backend rechaza publicar con servicios afuera y costo en
              // cero: publicar solo el alquiler es lo que hoy hace perder viajes.
              if (!_todoIncluido) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _costoServicios,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Cuánto paga aparte por los servicios',
                    suffixText: 'Bs',
                    helperText: 'Un estimado sirve. Sin esto no se puede publicar.',
                    helperMaxLines: 2,
                    errorText: publicar.erroresPorCampo['costo_servicios_estimado'],
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (n == null || n <= 0) {
                      return 'Estimá cuánto paga aparte';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: esquema.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Precio final',
                        style: texto.titleSmall
                            ?.copyWith(color: esquema.onPrimaryContainer)),
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

              // ------------------------------------------------------- reglas
              const SizedBox(height: 28),
              _Titulo('3. Reglas'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Acepto mascotas'),
                subtitle: const Text('Se puede filtrar por esto en la búsqueda'),
                value: _mascotas,
                onChanged: (v) => setState(() => _mascotas = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _restricciones,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Otras condiciones (opcional)',
                  hintText: 'Sólo señoritas, sin fiestas...',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              // ----------------------------------------------------- ubicacion
              const SizedBox(height: 28),
              _Titulo('4. Ubicación'),
              Text(
                'Tomala estando en el inmueble. De ahí sale el cálculo de '
                'minutos caminando a la UAGRM.',
                style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (publicar.hayUbicacion)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: esquema.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.place, color: esquema.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${publicar.lat!.toStringAsFixed(5)}, '
                          '${publicar.lng!.toStringAsFixed(5)}',
                          style: texto.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: publicar.buscandoUbicacion
                            ? null
                            : () => publicar.tomarUbicacion(),
                        child: const Text('Volver a tomar'),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: publicar.buscandoUbicacion
                      ? null
                      : () => publicar.tomarUbicacion(),
                  icon: publicar.buscandoUbicacion
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: Text(publicar.buscandoUbicacion
                      ? 'Buscando el GPS...'
                      : 'Usar mi ubicación'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                ),
              if (publicar.errorUbicacion != null) ...[
                const SizedBox(height: 12),
                AvisoError(mensaje: publicar.errorUbicacion!),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _referencia,
                decoration: const InputDecoration(
                  labelText: 'Referencia (opcional)',
                  hintText: 'A media cuadra del mercado',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),

              // --------------------------------------------------------- fotos
              const SizedBox(height: 28),
              _Titulo('5. Fotos'),
              Text(
                'Se toman con la cámara de la app y quedan con la fecha de '
                'captura visible. Así nadie ve un baño que ya no existe.',
                style: texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (publicar.fotos.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: publicar.fotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final f = publicar.fotos[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(f.ruta),
                                width: 110, height: 110, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => publicar.quitarFoto(i),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: esquema.error,
                                child: Icon(Icons.close,
                                    size: 14, color: esquema.onError),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                DateFormat('dd/MM/yy').format(f.fechaCaptura),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => publicar.agregarFoto(),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(publicar.fotos.isEmpty
                    ? 'Tomar una foto'
                    : 'Tomar otra foto'),
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),

              // ------------------------------------------------------ publicar
              if (publicar.error != null) ...[
                const SizedBox(height: 20),
                AvisoError(mensaje: publicar.error!),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: publicar.publicando ? null : _publicar,
                child: publicar.publicando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publicar'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: esquema.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tu WhatsApp no aparece en el anuncio',
                      style:
                          texto.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 10),
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
