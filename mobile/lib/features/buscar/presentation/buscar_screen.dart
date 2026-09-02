import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../anuncios/data/anuncio.dart';
import '../data/solicitudes_repository.dart';
import '../providers/buscar_provider.dart';
import 'resultados_screen.dart';

/// Vista 01 — Buscar.
///
/// Filtra por las cuatro condiciones de descarte: precio final, mascotas,
/// tipo de espacio y minutos caminando a la UAGRM.
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _precioCtrl = TextEditingController();
  TipoEspacio? _tipoSeleccionado;
  bool _aceptaMascotas = false;
  double _minutosMax = 15;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    // El estado del boton depende de lo que hay escrito, asi que hay que
    // reaccionar a cada tecla y no recien al tocarlo.
    _precioCtrl.addListener(_revisarPrecio);
  }

  @override
  void dispose() {
    _precioCtrl.removeListener(_revisarPrecio);
    _precioCtrl.dispose();
    super.dispose();
  }

  void _revisarPrecio() => setState(() {});

  /// El campo vacio es valido: significa "sin limite de precio".
  /// Lo invalido es haber escrito algo que no es un monto.
  bool get _precioEsValido {
    final texto = _precioCtrl.text.trim();
    if (texto.isEmpty) return true;
    final n = double.tryParse(texto.replaceAll(',', '.'));
    return n != null && n > 0;
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);

    final repo = context.read<SolicitudesRepository>();
    final provider = BuscarProvider(repo);

    final precioMax = double.tryParse(_precioCtrl.text.replaceAll(',', '.'));

    await provider.buscar(
      FiltrosBusqueda(
        precioMax: precioMax,
        tipoEspacio: _tipoSeleccionado,
        aceptaMascotas: _aceptaMascotas ? true : null,
        minutosMax: _minutosMax.toInt(),
      ),
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ResultadosScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar'), leading: const BackButton()),
      body: ListView(
        // Margen de 24 a los lados; arriba 16, que es lo que el wireframe
        // deja entre el encabezado y el primer filtro.
        padding: const EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.md,
          Espacio.lg,
          Espacio.lg,
        ),
        children: [
          // ---- Precio máximo ----
          CampoTexto(
            etiqueta: 'Precio máximo por mes (Bs)',
            controlador: _precioCtrl,
            pista: 'Ej. 800',
            icono: Icons.attach_money,
            tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
            formateadores: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            // null cuando el monto sirve: es como la pieza expresa "sin error".
            mensajeError: _precioEsValido
                ? null
                : 'Escribí un monto válido, como 800. O dejalo vacío para no '
                      'filtrar por precio.',
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Tipo de espacio ----
          Text(
            'Tipo de espacio',
            style: texto.labelMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
          const SizedBox(height: Espacio.sm),
          _SelectorTipo(
            seleccionado: _tipoSeleccionado,
            alCambiar: (t) => setState(() => _tipoSeleccionado = t),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Acepta mascotas ----
          _FilaSwitch(
            titulo: 'Solo acepta mascotas',
            valor: _aceptaMascotas,
            alCambiar: (v) => setState(() => _aceptaMascotas = v),
          ),

          const SizedBox(height: Espacio.lg),

          // ---- Minutos caminando ----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Máximo caminando a la UAGRM',
                style: texto.labelMedium?.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
              Text(
                '${_minutosMax.toInt()} min',
                style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            value: _minutosMax,
            min: 5,
            max: 60,
            divisions: 11,
            label: '${_minutosMax.toInt()} min',
            onChanged: (v) => setState(() => _minutosMax = v),
          ),

          const SizedBox(height: Espacio.xl),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          Espacio.lg,
          Espacio.sm,
          Espacio.lg,
          MediaQuery.of(context).padding.bottom + Espacio.md,
        ),
        child: BotonPrincipal(
          etiqueta: 'BUSCAR',
          etiquetaCargando: 'BUSCANDO...',
          // null deshabilita: es como la pieza expresa "falta algo".
          alTocar: _precioEsValido ? _buscar : null,
          cargando: _cargando,
          // El detalle ya está junto al campo que lo provoca. Repetirlo acá
          // sería decir dos veces lo mismo a 600 px de distancia: basta con
          // señalar dónde mirar.
          motivoDeshabilitado: 'Revisá el precio, arriba.',
        ),
      ),
    );
  }
}

// --------------------------------------------------------- Widgets de apoyo

class _SelectorTipo extends StatelessWidget {
  const _SelectorTipo({required this.seleccionado, required this.alCambiar});

  final TipoEspacio? seleccionado;
  final ValueChanged<TipoEspacio?> alCambiar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      children: TipoEspacio.values.map((tipo) {
        final activo = seleccionado == tipo;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: Espacio.sm),
            child: GestureDetector(
              onTap: () => alCambiar(activo ? null : tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: Espacio.md),
                decoration: BoxDecoration(
                  color: activo
                      ? esquema.primaryContainer
                      : esquema.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: activo
                        ? esquema.primary
                        : esquema.outline.withValues(alpha: 0.4),
                    width: activo ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  tipo.etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    color: activo
                        ? esquema.onPrimaryContainer
                        : esquema.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FilaSwitch extends StatelessWidget {
  const _FilaSwitch({
    required this.titulo,
    required this.valor,
    required this.alCambiar,
  });

  final String titulo;
  final bool valor;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Switch(value: valor, onChanged: alCambiar),
      ],
    );
  }
}
