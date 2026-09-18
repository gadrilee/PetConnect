import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../shared/layout/grilla.dart';
import '../../../shared/layout/pagina.dart';
import '../../../shared/widgets/aviso.dart';
import '../../../shared/widgets/bloque.dart';
import '../../../shared/widgets/boton_flotante.dart';
import '../../../shared/widgets/boton_secundario.dart';
import '../../../shared/widgets/boton_texto.dart';
import '../../../shared/widgets/estado_vacio.dart';
import '../../../shared/widgets/etiqueta_estado.dart';
import '../../../shared/widgets/fila_condicion.dart';
import '../../../shared/widgets/pie_acciones.dart';
import '../../../shared/widgets/precio_final.dart';
import '../data/anuncio.dart';
import '../providers/mis_anuncios_provider.dart';
import '../providers/publicar_provider.dart';
import 'confirmar_alquilado_screen.dart';
import 'publicar_screen.dart';

/// Los anuncios del propietario, en cualquier estado.
///
/// Lo que resuelve esta pantalla es que el anuncio muera cuando debe: si
/// marcar "Ya alquilado" cuesta mas de un toque, no va a pasar y los mensajes
/// van a seguir llegando semanas despues.
class MisAnunciosScreen extends StatefulWidget {
  const MisAnunciosScreen({super.key});

  @override
  State<MisAnunciosScreen> createState() => _MisAnunciosScreenState();
}

class _MisAnunciosScreenState extends State<MisAnunciosScreen> {
  /// El resultado de la ultima publicacion, para contarlo en el pie. Se va
  /// al refrescar la lista: ya se leyo.
  String? _publicado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<MisAnunciosProvider>().cargar(),
    );
  }

  Future<void> _publicar() async {
    // El provider del formulario se crea nuevo en cada publicacion, para no
    // arrastrar fotos ni ubicacion del anuncio anterior.
    final repo = context.read<MisAnunciosProvider>();
    final publicado = await Navigator.of(context).push<Anuncio>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (ctx) => PublicarProvider(ctx.read()),
          child: const PublicarScreen(),
        ),
      ),
    );
    if (!mounted) return;
    repo.limpiarMensajes();
    repo.cargar();
    if (publicado != null) {
      setState(() {
        _publicado = 'Publicado. Está a ${publicado.minutosCaminando} min '
            'caminando de la UAGRM.';
      });
    }
  }

  Future<void> _refrescar() {
    setState(() => _publicado = null);
    final provider = context.read<MisAnunciosProvider>()..limpiarMensajes();
    return provider.cargar();
  }

  /// El pie solo cuenta resultados: que se publico, que salio de la busqueda
  /// o volvio a ella, o el ultimo error —no se pudo cargar, o no se pudo
  /// cambiar el estado de un anuncio— mientras la lista sigue a la vista.
  /// Nunca un toast suelto.
  PieAcciones? _pie(MisAnunciosProvider estado) {
    final error = estado.anuncios.isEmpty ? null : estado.error;
    if (error != null) {
      return PieAcciones(aviso: Aviso(mensaje: error, tipo: TipoAviso.error));
    }
    if (estado.aviso != null) {
      return PieAcciones(
        aviso: Aviso(mensaje: estado.aviso!, tipo: TipoAviso.exito),
      );
    }
    if (_publicado != null) {
      return PieAcciones(
        aviso: Aviso(mensaje: _publicado!, tipo: TipoAviso.exito),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<MisAnunciosProvider>();
    final anuncios = estado.anuncios;

    Widget? cuerpo;
    if (estado.cargando && anuncios.isEmpty) {
      cuerpo = const CircularProgressIndicator();
    } else if (estado.error != null && anuncios.isEmpty) {
      cuerpo = EstadoVacio(
        icono: Icons.error_outline,
        titulo: 'No pudimos cargar tus anuncios',
        detalle: estado.error,
        esError: true,
        accion: 'Reintentar',
        alAccion: estado.cargar,
      );
    } else if (anuncios.isEmpty) {
      cuerpo = const EstadoVacio(
        icono: Icons.home_work_outlined,
        titulo: 'Todavía no publicaste nada',
        detalle:
            'Publicá una vez con las condiciones por delante y el anuncio filtra solo.',
      );
    }

    return Pagina(
      titulo: 'Mis anuncios',
      alRefrescar: _refrescar,
      botonFlotante: BotonFlotante(
        etiqueta: 'Publicar',
        icono: Icons.add,
        alTocar: _publicar,
      ),
      pie: _pie(estado),
      cuerpo: cuerpo,
      hijos: [
        // GRID: un anuncio por fila en movil, dos en tablet y tres en
        // escritorio, con 16 entre tarjetas (el medianil de la grilla).
        Grilla12(
          celdas: [
            for (final anuncio in anuncios)
              CeldaGrilla(
                columnas: const Columnas(tablet: 6, escritorio: 4),
                child: _TarjetaGestion(anuncio: anuncio),
              ),
          ],
        ),
      ],
    );
  }
}

/// La tarjeta del PROPIETARIO: muestra el estado del anuncio y la accion de
/// marcarlo como alquilado. No es la misma pieza que TarjetaAnuncio, que es
/// la que ve la inquilina para decidir; comparten las piezas, no el trabajo.
class _TarjetaGestion extends StatelessWidget {
  const _TarjetaGestion({required this.anuncio});

  final Anuncio anuncio;

  /// Sin solicitudes pendientes, un toque. Con pendientes, antes se dice que
  /// se van a cerrar: eso afecta a otras personas (flujo v0.5).
  Future<void> _marcarAlquilado(BuildContext context) async {
    final provider = context.read<MisAnunciosProvider>();
    if (anuncio.solicitudesPendientes == 0) {
      await provider.marcarAlquilado(anuncio);
      return;
    }
    provider.limpiarMensajes();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: ConfirmarAlquiladoScreen(anuncio: anuncio),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final precio = PrecioFinal.formatear(anuncio.precioFinal);
    final provider = context.watch<MisAnunciosProvider>();
    // Mientras se cambia, el boton no acepta un segundo toque.
    final ocupado = provider.cambiando(anuncio.id);

    final datos = <(IconData, String)>[
      (Icons.payments_outlined, '$precio Bs'),
      (Icons.directions_walk, '${anuncio.minutosCaminando} min'),
      (
        anuncio.aceptaMascotas ? Icons.pets : Icons.block,
        anuncio.aceptaMascotas ? 'Mascotas' : 'Sin mascotas',
      ),
      (Icons.home_outlined, anuncio.tipoEspacio.etiqueta),
    ];

    return Bloque(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // FLEXBOX: el titulo toma el espacio libre y el estado queda
          // anclado a la derecha.
          Row(
            children: [
              Expanded(
                child: Text(
                  anuncio.titulo,
                  style:
                      AppText.button(context).copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: Espacio.sm),
              EtiquetaEstado.anuncio(anuncio.estado),
            ],
          ),
          const SizedBox(height: Espacio.sm),
          // FLEXBOX: los datos van en fila y bajan si no entran (flex-wrap).
          Wrap(
            spacing: Espacio.md,
            runSpacing: Espacio.xs,
            children: [
              for (final (icono, texto) in datos)
                FilaCondicion(
                  enLinea: true,
                  icono: icono,
                  texto: texto,
                  colorIcono: AppColors.text50,
                  estilo:
                      AppText.caption(context).copyWith(color: AppColors.text70),
                ),
            ],
          ),
          const SizedBox(height: Espacio.md),
          if (anuncio.estaDisponible)
            BotonSecundario(
              etiqueta: 'Marcar Ya alquilado',
              icono: Icons.check_circle_outline,
              compacto: true,
              alTocar: ocupado ? null : () => _marcarAlquilado(context),
            )
          else
            BotonTexto(
              etiqueta: 'Volver a publicar',
              icono: Icons.refresh,
              alTocar: ocupado ? null : () => provider.volverAPublicar(anuncio),
            ),
        ],
      ),
    );
  }
}
