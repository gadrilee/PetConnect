import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/boton_principal.dart';
import '../../../shared/widgets/campo_texto.dart';
import '../../../shared/widgets/controles.dart';
import '../../../shared/widgets/resumen_busqueda.dart';
import '../../propietario/data/anuncio.dart';
import '../data/solicitudes_repository.dart';
import '../providers/buscar_provider.dart';
import 'resultados_screen.dart';

/// Vista 02 — Buscar.
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

  /// Los filtros tal como estan en pantalla. Los usan la busqueda y el panel
  /// "Tu búsqueda", asi los dos dicen siempre lo mismo.
  FiltrosBusqueda get _filtros => FiltrosBusqueda(
        precioMax: _precioEsValido
            ? double.tryParse(_precioCtrl.text.trim().replaceAll(',', '.'))
            : null,
        tipoEspacio: _tipoSeleccionado,
        aceptaMascotas: _aceptaMascotas ? true : null,
        minutosMax: _minutosMax.toInt(),
      );

  Future<void> _buscar() async {
    setState(() => _cargando = true);

    final provider = BuscarProvider(context.read<SolicitudesRepository>());
    await provider.buscar(_filtros);

    if (!mounted) return;
    setState(() => _cargando = false);

    if (provider.error != null) {
      Aviso.mostrarToast(
        context,
        mensaje: provider.error!,
        tipo: TipoAviso.error,
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
    final tenue = AppText.caption(context)
        .copyWith(color: AppColors.text.withValues(alpha: 0.7));

    return Pagina(
      titulo: 'Buscar',
      pie: BotonPrincipal(
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
      hijos: [
        // GRID: los filtros en 8 columnas y "Tu búsqueda" en 4, como en Figma.
        // En movil van 12 y 12, uno debajo del otro.
        Grilla12(
          separacionFilas: Espacio.lg,
          celdas: [
            CeldaGrilla(
              columnas: const Columnas(tablet: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---- Precio máximo ----
                  CampoTexto(
                    etiqueta: 'Precio máximo por mes (Bs)',
                    controlador: _precioCtrl,
                    pista: 'Ej. 800',
                    icono: Icons.attach_money,
                    tipoTeclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    formateadores: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                    // null cuando el monto sirve: es como la pieza expresa
                    // "sin error".
                    mensajeError: _precioEsValido
                        ? null
                        : 'Escribí un monto válido, como 800. O dejalo vacío '
                            'para no filtrar por precio.',
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Tipo de espacio ----
                  Text('Tipo de espacio', style: tenue),
                  const SizedBox(height: Espacio.sm),
                  // FLEXBOX: cada opcion mide lo que su palabra y, si no
                  // entran en una fila, pasan a la siguiente (flex-wrap).
                  Wrap(
                    spacing: Espacio.md,
                    runSpacing: Espacio.sm,
                    children: [
                      for (final t in TipoEspacio.values)
                        Opcion(
                          etiqueta: t.etiqueta,
                          seleccionada: _tipoSeleccionado == t,
                          alTocar: () => setState(
                            () => _tipoSeleccionado =
                                _tipoSeleccionado == t ? null : t,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Acepta mascotas ----
                  Interruptor(
                    etiqueta: 'Solo acepta mascotas',
                    encendido: _aceptaMascotas,
                    alCambiar: (v) => setState(() => _aceptaMascotas = v),
                  ),
                  const SizedBox(height: Espacio.lg),

                  // ---- Minutos caminando ----
                  // FLEXBOX: la etiqueta toma el espacio libre y el valor
                  // queda anclado a la derecha.
                  Row(
                    children: [
                      Expanded(
                        child: Text('Máximo caminando a la UAGRM', style: tenue),
                      ),
                      Text(
                        '${_minutosMax.toInt()} min',
                        style: AppText.button(context)
                            .copyWith(color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espacio.md),
                  Deslizador(
                    valor: _minutosMax,
                    min: 5,
                    max: 60,
                    alCambiar: (v) => setState(() => _minutosMax = v),
                  ),
                ],
              ),
            ),
            CeldaGrilla(
              columnas: const Columnas(tablet: 4),
              child: ResumenBusqueda(filtros: _filtros),
            ),
          ],
        ),
      ],
    );
  }
}
